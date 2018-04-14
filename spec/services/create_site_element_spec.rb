describe CreateSiteElement do
  let(:user) { create :user }
  let(:site) { create :site, :with_rule, user: user }
  let(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
  let(:service) { CreateSiteElement.new params, site, user }

  it 'persists site element' do
    expect { service.call }.to change(SiteElement, :count).by(1)
  end

  it 'calls TrackEvent with :created_bar event' do
    expect(TrackEvent)
      .to receive_service_call
      .with(:created_bar, site_element: instance_of(SiteElement), user: user)

    service.call
  end

  it 'regenerates script' do
    expect { service.call }
      .to have_enqueued_job(GenerateStaticScriptJob).with(site)
  end
end
