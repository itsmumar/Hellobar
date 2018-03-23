describe UpdateStaticScriptInstallation do
  context 'when site script was not installed' do
    let!(:site) { create :site, :with_user, :with_rule }

    context 'and is set to installed' do
      let(:service) { UpdateStaticScriptInstallation.new site, installed: true }

      it 'sets the script_installed_at', :freeze do
        expect { service.call }.to change {
          site.reload.script_installed_at
        }.to Time.current
      end

      it 'redeems referrals' do
        expect(RedeemReferralForRecipient).to receive_service_call.with(site)

        service.call
      end

      it 'sends the install event to analytics' do
        expect(TrackEvent).to receive_service_call
          .with(:installed_script, site: site, user: site.owners.first)

        service.call
      end

      it 'creates onboarding status :installed_script' do
        expect { service.call }.to change(UserOnboardingStatus, :count).by 1
        expect(UserOnboardingStatus.last.status_id)
          .to eql UserOnboardingStatus::STATUSES[:installed_script]
      end
    end

    context 'and is set to uninstalled' do
      let(:service) { UpdateStaticScriptInstallation.new site, installed: false }

      it 'does nothing' do
        expect(TrackEvent).not_to receive_service_call

        service.call

        expect(site.reload.script_installed_at).to eq nil
      end
    end
  end

  context 'when site script was installed' do
    let!(:site) { create :site, :with_user, :with_rule, :installed }

    context 'and is set to uninstalled' do
      let(:service) { UpdateStaticScriptInstallation.new site, installed: false }

      it 'sets the script_uninstalled_at', :freeze do
        expect { service.call }.to change {
          site.reload.script_uninstalled_at
        }.to Time.current
      end

      it 'sends the uninstall event to analytics' do
        expect(TrackEvent).to receive_service_call
          .with(:uninstalled_script, site: site, user: site.owners.first)

        service.call
      end

      it 'changes user onboarding status' do
        expect { service.call }.to change(UserOnboardingStatus, :count).by 1
      end
    end

    context 'and is set to installed' do
      let(:service) { UpdateStaticScriptInstallation.new site, installed: true }

      it 'does not update script_installed_at' do
        expect { service.call }.not_to change {
          site.reload.script_installed_at
        }
      end

      it 'does not send tracking events' do
        expect(TrackEvent).not_to receive_service_call

        service.call
      end
    end
  end
end
