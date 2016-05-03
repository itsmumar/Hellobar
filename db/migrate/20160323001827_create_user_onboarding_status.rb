class CreateUserOnboardingStatus < ActiveRecord::Migration
  def change
    create_table :user_onboarding_statuses do |t|
      t.belongs_to :user
      t.integer :status_id
      t.integer :sequence_delivered_last

      t.datetime :created_at
    end

    add_index :user_onboarding_statuses, :user_id
  end
end
