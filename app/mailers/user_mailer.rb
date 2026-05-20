class UserMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    @reset_url = "vitalforgemobilev1://reset-password?token=#{user.password_reset_token}"
    mail(to: @user.email, subject: "Reset your VitalForge password")
  end
end
