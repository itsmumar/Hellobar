describe DeliverUserOnboardingCampaign do
  let(:service) { DeliverUserOnboardingCampaign.new(campaign) }
  let(:user) { create :user }

  describe '#call' do
    context 'with CreateABarCampaign' do
      let(:campaign) { CreateABarCampaign.new(user) }

      it 'sends create_a_bar email' do
        expect { service.call }
          .to have_enqueued_job
          .with('DripCampaignMailer', 'create_a_bar', 'deliver_now', user)
          .on_queue('test_mailers')
      end

      it 'marks sequence as delivered' do
        expect { service.call }
          .to change { user.current_onboarding_status.sequence_delivered_last }
          .from(nil).to(0)
      end

      it 'tracks event' do
        expect(Analytics)
          .to receive(:track).with(:user, user.id, 'Sent Email', {
            'Email Template' => 'create_a_bar',
            'Campaign Name' => 'CreateABarCampaign'
          })

        service.call
      end

      context 'when campaign has been already sent' do
        before { user.current_onboarding_status.update sequence_delivered_last: 0 }

        it 'does not touch current_onboarding_status' do
          expect { service.call }
            .not_to change { user.current_onboarding_status.sequence_delivered_last }
        end

        it 'does not send email' do
          expect { service.call }.not_to have_enqueued_job
        end

        it 'does not track event' do
          expect(Analytics).not_to receive(:track)
          service.call
        end
      end
    end
  end
end
