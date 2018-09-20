describe IntercomRefresh do
  subject!(:service) { IntercomRefresh.new }

  before do
    allow(IntercomRefresh).to receive(:new)
    allow(service).to receive(:track_updated_site_counts)
  end


  # let(:rules) { create_list :static_script_rule, 1, rule: elite_site.rules.first }

  context 'when bill subscription is elite' do
    let!(:user) { create :user }
    let!(:site) { create :site, :with_rule, user: user }
    let!(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
    let!(:element) { create :slider, site: site}

    # it 'calls TrackEvent with :update_site_count event' do
    #   expect(service)
    #     .to receive_service_call
    #
    #
    #   service.call
    # end
    #
    # it 'updates site count' do
    #   site.update(script_installed_at: Time.now)
    #
    #   service.call
    #   # expect { service.call }
    #   #   .to have_received(:track_updated_site_counts)
    #
    #   p user.sites.last.site_elements.count
    #   # expect(service).to have_received(:track_updated_site_counts)
    #
    #   # expect(last_bill.subscription).to eql(site.active_subscription)
    #   # expect(last_bill.amount).to eql(10)
    #   # expect(last_bill.grace_period_allowed).to be_truthy
    #   # expect(last_bill.description).to eql('Monthly View Limit Overage Fee')
    # end
  end
end
