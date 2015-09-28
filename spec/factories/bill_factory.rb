FactoryGirl.define do
  factory :bill do
    amount 0
    subscription
    bill_at Time.now

    factory :pro_bill do
      amount Subscription::Pro.defaults[:monthly_amount]
      association :subscription, factory: :pro_subscription
    end
  end
end


# t.integer  "subscription_id"
# t.integer  "status",                                        default: 0
# t.string   "type"
# t.decimal  "amount",               precision: 7,  scale: 2
# t.string   "description"
# t.string   "metadata"
# t.boolean  "grace_period_allowed",                          default: true
# t.datetime "bill_at"
# t.datetime "start_date"
# t.datetime "end_date"
# t.datetime "status_set_at"
# t.datetime "created_at"
# t.decimal  "discount",             precision: 10, scale: 0, default: 0
# t.decimal  "final_amount",         precision: 10, scale: 0
