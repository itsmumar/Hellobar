describe ContactListsHelper, type: :helper do
  let(:site) { create(:site) }
  let(:contact_list) { create(:contact_list, :mailchimp, site: site) }

  context 'MailChimp' do
    it 'has valid results' do
      expect(helper.contact_list_provider_name(contact_list)).to eq 'MailChimp'
      expect(helper.contact_list_image(contact_list)).to eq 'providers/mailchimp.png'
    end
  end

  context 'embed code ESPs' do
    let(:contact_list) do
      ContactList.new(name: 'asdf', site: site, data: { 'embed_code' => 'asdf' })
    end

    context 'MadMimi' do
      before do
        contact_list.identity = create(:identity, :mad_mimi)
      end

      it 'has valid results' do
        expect(helper.contact_list_provider_name(contact_list)).to eq 'MadMimi'
        expect(helper.contact_list_image(contact_list)).to eq 'providers/mad_mimi_form.png'
      end
    end
  end

  context 'no ESP' do
    let(:contact_list) do
      ContactList.new(site: site)
    end

    it 'has valid results' do
      expect(helper.contact_list_provider_name(contact_list)).to eq 'Hello Bar'
      expect(helper.contact_list_image(contact_list)).to eq 'providers/hellobar.png'
    end
  end
end
