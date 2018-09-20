describe HandleUnfreezeFrozenAccount do
  subject!(:service2) { HandleUnfreezeFrozenAccount.new(site) }

  let(:user) { create :user }
  let(:site) { create :site, :with_rule, user: user }
  let(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
  let(:service) { CreateSiteElement.new params, site, user }

  it 'persists site element' do
    expect { service.call }.to change(SiteElement, :count).by(1)
  end

  context 'unfreeze the account' do
    it 'activates frozen elements' do
      site.deactivate_site_element
      service.call
      expect(site.site_elements.last.deactivated_at).to eql(nil)
    end
  end
end
