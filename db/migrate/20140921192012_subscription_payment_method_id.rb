class SubscriptionPaymentMethodId < ActiveRecord::Migration
  def change
    change_table :subscriptions do |t|
      t.belongs_to :payment_method
    end
  end
end
