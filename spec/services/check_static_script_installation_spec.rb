describe CheckStaticScriptInstallation do
  let(:site) { create(:site, :with_user, :with_rule) }
  let(:service) { CheckStaticScriptInstallation.new(site) }

  # this needs because we stub CheckStaticScriptInstallation#call globally
  # as it is being called from many places
  # which is going to be refactored, though
  before { allow_any_instance_of(CheckStaticScriptInstallation).to receive(:call).and_call_original }

  shared_examples 'uninstalled' do
    before do
      stub_request(:get, site.url).to_return(status: 200, body: '', headers: {})
    end

    it 'updates the script_uninstalled_at' do
      expect { service.call }.to change { site.reload.script_uninstalled_at }
    end

    it 'tracks the install event' do
      expect(Analytics).to receive(:track).with(:site, site.id, 'Uninstalled')
      service.call
    end
  end

  shared_examples 'installed' do
    before do
      stub_request(:get, site.url).to_return(status: 200, body: site.script_name, headers: {})
    end

    it 'updates the script_installed_at' do
      expect { service.call }.to change { site.reload.script_installed_at }
    end

    it 'redeems referrals' do
      expect(Referrals::RedeemForRecipient).to receive(:run).with(site: site)
      service.call
    end

    it 'tracks the install event' do
      expect(Analytics).to receive(:track).with(:site, site.id, 'Installed')
      service.call
    end

    let(:last_status) { UserOnboardingStatus.last }

    it 'creates onboarding status :installed_script' do
      expect { service.call }.to change(UserOnboardingStatus, :count).by(1)
      expect(last_status.status_id).to eql UserOnboardingStatus::STATUSES[:installed_script]
    end
  end

  context 'when site is marked as installed' do
    before do
      site.update script_installed_at: Time.current, script_uninstalled_at: nil
    end

    context 'and bar has views according Hello::DataAPI' do
      before { expect(Hello::DataAPI).to receive(:lifetime_totals).and_return(lifetime_totals) }

      context 'when lifetime_totals is empty hash' do
        let(:lifetime_totals) { {} }
        include_examples 'uninstalled'
      end

      context 'when lifetime_totals returns no views in the last 10 days' do
        let(:lifetime_totals) { Hash['1' => [[1, 0]] * 11] }
        include_examples 'uninstalled'
      end
    end

    context 'and script is not installed on the homepage' do
      let(:body) { '<html><body>Text</body></html>' }

      before do
        stub_request(:get, site.url).to_return status: 200, body: body
      end

      include_examples 'uninstalled'
    end

    context 'and could not get the homepage' do
      before { allow(HTTParty).to receive(:get).and_raise('error') }

      include_examples 'uninstalled'
    end

    context 'and site is inaccessible' do
      before do
        stub_request(:get, site.url).to_return status: 504
      end

      include_examples 'uninstalled'
    end
  end

  context 'when site is marked as uninstalled' do
    before do
      site.update script_installed_at: nil, script_uninstalled_at: Time.current
    end

    context 'and bar has no views according Hello::DataAPI' do
      before { expect(Hello::DataAPI).to receive(:lifetime_totals).and_return(lifetime_totals) }

      context 'if there is only one day of data' do
        let(:lifetime_totals) { Hash[1 => [[1, 0]]] }
        include_examples 'installed'
      end

      context 'if there are multiple days of data' do
        let(:lifetime_totals) { Hash[1 => [[1, 0], [2, 0]]] }
        include_examples 'installed'
      end

      context 'if there are multiple days of data' do
        let(:lifetime_totals) { Hash[1 => [[1, 0], [2, 0]]] }
        include_examples 'installed'
      end

      context 'if one element has views but others do not' do
        let(:lifetime_totals) do
          {
            '1' => [[1, 0]] * 8,
            '2' => [[1, 0], [1, 0], [2, 0], [2, 0], [2, 0], [2, 0], [2, 0], [2, 0]]
          }
        end
        include_examples 'installed'
      end

      context 'if any of the elements have been installed in the last 7 days' do
        let(:lifetime_totals) do
          {
            '1' => [[1, 0]] * 8,
            '2' => [[1, 0], [1, 0]]
          }
        end
        include_examples 'installed'
      end
    end

    context 'and script is installed on the homepage' do
      let(:body) { "<script src='//localhost/#{ site.script_name }'></script>" }

      before do
        stub_request(:get, site.url).to_return status: 200, body: body

        expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({})
      end

      include_examples 'installed'
    end
  end

  context 'when installed_at is more recent than uninstalled_at' do
    before do
      site.update script_installed_at: 1.day.ago, script_uninstalled_at: 1.week.ago
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return({})
    end

    include_examples 'uninstalled'
  end

  context 'when uninstalled_at is more recent than installed_at' do
    before do
      site.update script_installed_at: 1.week.ago, script_uninstalled_at: 1.day.ago
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(1 => [[1, 0]])
    end

    include_examples 'installed'
  end
end
