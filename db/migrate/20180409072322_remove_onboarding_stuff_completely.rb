class RemoveOnboardingStuffCompletely < ActiveRecord::Migration
  def up
    drop_table :user_onboarding_statuses
  end
end
