# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let(:valid_attributes) do
    {
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User"
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      user = User.new(valid_attributes)
      expect(user).to be_valid
    end

    it "requires email" do
      user = User.new(valid_attributes.except(:email))
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires first_name" do
      user = User.new(valid_attributes.except(:first_name))
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("can't be blank")
    end

    it "requires last_name" do
      user = User.new(valid_attributes.except(:last_name))
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include("can't be blank")
    end

    it "requires unique email" do
      User.create!(valid_attributes)
      duplicate_user = User.new(valid_attributes)
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include("has already been taken")
    end

    describe "phone_number validation" do
      it "allows nil phone number" do
        user = User.new(valid_attributes.merge(phone_number: nil))
        expect(user).to be_valid
      end

      it "validates uniqueness of phone number" do
        User.create!(valid_attributes.merge(phone_number: "+14155551234"))
        duplicate_user = User.new(valid_attributes.merge(email: "other@example.com", phone_number: "+14155551234"))
        expect(duplicate_user).not_to be_valid
        expect(duplicate_user.errors[:phone_number]).to include("has already been taken")
      end

      it "accepts valid phone number formats" do
        valid_formats = [
          "(415) 555-1234",
          "415-555-1234",
          "4155551234",
          "+1 415 555 1234",
          "+14155551234"
        ]

        valid_formats.each_with_index do |format, index|
          user = User.new(valid_attributes.merge(email: "user#{index}@example.com", phone_number: format))
          expect(user).to be_valid, "Expected #{format} to be valid but got errors: #{user.errors.full_messages}"
        end
      end

      it "rejects phone numbers with invalid characters" do
        invalid_numbers = [
          "415-555-ABCD",
          "john@example.com",
          "415.555.1234#",
          "call me maybe"
        ]

        invalid_numbers.each do |number|
          user = User.new(valid_attributes.merge(phone_number: number))
          expect(user).not_to be_valid, "Expected #{number} to be invalid"
        end
      end

      it "rejects phone numbers that are too short" do
        user = User.new(valid_attributes.merge(phone_number: "123456789")) # 9 digits
        expect(user).not_to be_valid
        expect(user.errors[:phone_number]).to include("is too short (minimum is 10 characters)")
      end

      it "rejects phone numbers that are too long" do
        user = User.new(valid_attributes.merge(phone_number: "1" * 21)) # 21 digits
        expect(user).not_to be_valid
        expect(user.errors[:phone_number]).to include("is too long (maximum is 20 characters)")
      end
    end
  end

  describe "phone number normalization" do
    it "normalizes 10-digit US phone number to E.164 format" do
      user = User.create!(valid_attributes.merge(phone_number: "4155551234"))
      expect(user.phone_number).to eq("+14155551234")
    end

    it "normalizes formatted US phone number to E.164 format" do
      user = User.create!(valid_attributes.merge(email: "user1@example.com", phone_number: "(415) 555-1234"))
      expect(user.phone_number).to eq("+14155551234")
    end

    it "normalizes dashed US phone number to E.164 format" do
      user = User.create!(valid_attributes.merge(email: "user2@example.com", phone_number: "415-555-1234"))
      expect(user.phone_number).to eq("+14155551234")
    end

    it "preserves +1 prefix if already present" do
      user = User.create!(valid_attributes.merge(email: "user3@example.com", phone_number: "+1 415 555 1234"))
      expect(user.phone_number).to eq("+14155551234")
    end

    it "handles phone number with +1 and dashes" do
      user = User.create!(valid_attributes.merge(email: "user4@example.com", phone_number: "+1-415-555-1234"))
      expect(user.phone_number).to eq("+14155551234")
    end

    it "removes all formatting characters" do
      user = User.create!(valid_attributes.merge(email: "user5@example.com", phone_number: "+1 (415) 555-1234"))
      expect(user.phone_number).to eq("+14155551234")
    end

    it "does not modify nil phone number" do
      user = User.create!(valid_attributes.merge(phone_number: nil))
      expect(user.phone_number).to be_nil
    end

    it "keeps international numbers with + prefix as-is" do
      # Future international support - for now just preserve the format
      user = User.create!(valid_attributes.merge(email: "user6@example.com", phone_number: "+44 20 1234 5678"))
      expect(user.phone_number).to eq("+442012345678")
    end
  end

  describe "email normalization" do
    it "normalizes email to lowercase" do
      user = User.create!(valid_attributes.merge(email: "John.Doe@EXAMPLE.COM"))
      expect(user.email).to eq("john.doe@example.com")
    end

    it "strips whitespace from email" do
      user = User.create!(valid_attributes.merge(email: "  john@example.com  "))
      expect(user.email).to eq("john@example.com")
    end
  end

  describe "#full_name" do
    it "returns first and last name combined" do
      user = User.new(valid_attributes.merge(first_name: "John", last_name: "Doe"))
      expect(user.full_name).to eq("John Doe")
    end
  end

  describe "account lockout" do
    let(:user) { User.create!(valid_attributes) }

    describe "#increment_failed_login!" do
      it "increments failed login attempts" do
        expect { user.increment_failed_login! }.to change(user, :failed_login_attempts).by(1)
      end

      it "locks account after max attempts" do
        (User::MAX_LOGIN_ATTEMPTS - 1).times { user.increment_failed_login! }
        expect(user.locked_at).to be_nil

        user.increment_failed_login!
        expect(user.locked_at).to be_present
      end
    end

    describe "#reset_failed_login!" do
      before do
        user.update_columns(failed_login_attempts: 3, locked_at: Time.current)
      end

      it "resets failed login attempts to 0" do
        user.reset_failed_login!
        expect(user.failed_login_attempts).to eq(0)
      end

      it "clears locked_at timestamp" do
        user.reset_failed_login!
        expect(user.locked_at).to be_nil
      end
    end

    describe "#locked?" do
      it "returns false when not locked" do
        expect(user.locked?).to be(false)
      end

      it "returns true when locked recently" do
        user.update_column(:locked_at, 5.minutes.ago)
        expect(user.locked?).to be(true)
      end

      it "returns false when lock has expired" do
        user.update_column(:locked_at, (User::LOCKOUT_DURATION + 1.minute).ago)
        expect(user.locked?).to be(false)
      end
    end
  end
end
