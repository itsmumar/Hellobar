Coupon.create! label: Coupon::REFERRAL_LABEL, amount: Coupon::REFERRAL_AMOUNT, public: false
Coupon.create! label: Coupon::PROMOTIONAL_LABEL, amount: Subscription::Growth.defaults[:monthly_amount], public: true, trial_period: 30
