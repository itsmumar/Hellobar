describe RedeemReferralForRecipient do
  let!(:coupon) { create :coupon, :referral }

  let(:recipient) { create :user }
  let(:site) { create :site, user: recipient }

  let(:service) { RedeemReferralForRecipient.new(site) }

  before do
    allow_any_instance_of(RedeemReferralForSender).to receive(:call)
  end

  context 'when can redeem the referral' do
    let!(:referral) { create(:referral, recipient: recipient, state: Referral::SIGNED_UP) }

    it 'updates referral' do
      expect { service.call }
        .to change { referral.reload.state }
        .to('installed')
        .and change { referral.reload.available_to_sender }
        .to(true)
    end

    it 'changes subscription to trial growth', :freeze do
      expect { service.call }
        .to change { site.current_subscription }
        .to instance_of(Subscription::Growth)

      expect(site.current_subscription.trial_end_date).to eql 1.month.from_now
    end

    it 'calls UseReferral service' do
      expect(UseReferral)
        .to receive_service_call
        .with(instance_of(Bill), referral)

      service.call
    end

    it 'calls RedeemReferralForSender service' do
      expect(RedeemReferralForSender)
        .to receive_service_call
        .with(referral)

      service.call
    end

    it 'sends email notification to the sender' do
      expect { service.call }
        .to have_enqueued_job(ActionMailer::DeliveryJob)
        .with('ReferralsMailer', 'successful', 'deliver_now', referral, recipient)
    end

    it 'tracks used_recipient_referral_coupon event' do
      expect(TrackEvent)
        .to receive_service_call
        .with(
          :upgraded_subscription,
          user: recipient,
          subscription: instance_of(Subscription::Growth),
          previous_subscription: nil
        )

      expect(TrackEvent)
        .to receive_service_call
        .with(
          :used_recipient_referral_coupon,
          user: recipient,
          subscription: instance_of(Subscription::Growth)
        )

      service.call
    end
  end

  context 'when referral is not in state :signed_up' do
    let!(:referral) { create(:referral, recipient: recipient, state: Referral::SENT) }

    it 'does nothing' do
      expect { service.call }
        .not_to change(referral, :updated_at)

      expect(service.call).to be_nil
    end
  end

  context 'when referral is already accepted' do
    let!(:referral) { create(:referral, recipient: recipient, state: Referral::INSTALLED) }

    it 'does nothing' do
      expect { service.call }
        .not_to change(referral, :updated_at)

      expect(service.call).to be_nil
    end
  end

  context 'when there is no referral for recipient' do
    let!(:referral) { create(:referral, state: Referral::SIGNED_UP) }

    it 'does nothing' do
      expect { service.call }
        .not_to change(referral, :updated_at)

      expect(service.call).to be_nil
    end
  end
end
