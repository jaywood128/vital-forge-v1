# frozen_string_literal: true

class CreatePersonalRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :personal_records do |t|
      t.references :user,         null: false, foreign_key: true
      t.references :exercise,     null: false, foreign_key: true
      t.references :exercise_set, null: false,
                   foreign_key: { to_table: :exercise_sets, on_delete: :restrict }
      t.decimal  :estimated_1rm, precision: 6, scale: 2, null: false
      t.decimal  :weight,        precision: 6, scale: 2, null: false
      t.integer  :reps,          null: false
      t.datetime :recorded_at,   null: false
      t.timestamps
    end

    add_index :personal_records, [:user_id, :exercise_id, :recorded_at]
    add_index :personal_records, [:user_id, :exercise_id, :estimated_1rm]
  end
end
