describe HandleUnfreezeFrozenAccount do
  # subject!(:service) { HandleUnfreezeFrozenAccount.new(site) }

  let(:user) { create :user }
  let(:site) { create :site, :with_rule, user: user }
  let(:params) { Hash[element_subtype: 'call', rule_id: site.rules.ids.first] }
  let(:service) { HandleUnfreezeFrozenAccount.new site }

  it 'persists site element' do
    expect { service.call }.to change(SiteElement, :count).by(1)
  end
  #
  # context 'when warning emails have been sent' do
  #   it 'resets warning_email_one_sent to false' do
  #     service.call
  #     expect(site.warning_email_one_sent).to eql(false)
  #     expect(site.warning_email_two_sent).to eql(false)
  #     expect(site.warning_email_three_sent).to eql(false)
  #     expect(site.limit_email_sent).to eql(false)
  #     expect(site.upsell_email_sent).to eql(false)
  #   end
  # end
end
