require 'spec_helper'

describe ContactList do
  let(:site) { create(:site) }
  let(:provider) { 'email' }
  let(:identity) { Identity.new(site: site, provider: provider) }
  let(:contact_list) { create(:contact_list).tap { |c| c.identity = identity } }
  let(:service_provider) { contact_list.service_provider }

  before do
    if identity.provider == 'email'
      allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::Email)
      allow(ServiceProviders::Email).to receive(:settings).and_return(oauth: false)
      allow(contact_list).to receive(:syncable?).and_return(true)
      expect(service_provider).to be_a(ServiceProviders::Email)
      allow(service_provider).to receive(:batch_subscribe).and_return(nil)
    end

    allow(Hello::DataAPI).to receive(:contacts).and_return([
      ['test1@hellobar.com', '', 1384807897],
      ['test2@hellobar.com', '', 1384807898]
    ])
  end

  describe 'as a valid object' do
    it 'validates a webhook has a valid URL' do
      list = build(:contact_list, data: { 'webhook_url' => 'url' })

      list.valid?

      expect(list.errors[:base]).to include('webhook URL is invalid')
    end
  end

  describe 'associated identity' do
    it 'should use #provider on creation to find the correct identity' do
      identity = create(:identity)
      list = build(:contact_list, site: identity.site, provider: 'mailchimp')

      expect { list.valid? }.to change { list.identity }.from(nil).to(identity)
    end

    it 'should use #provider on edit to find the correct identity' do
      constantcontact = create(:identity, :constantcontact)
      list = create(:contact_list, :mailchimp, site: constantcontact.site)
      list.provider = 'constantcontact'
      list.save
      expect(list.identity).to eql constantcontact
    end

    it 'should not be valid if #provider does not match an existing identity' do
      list = create(:contact_list)
      list.provider = 'notanesp'
      list.identity = nil

      expect(list).not_to be_valid
      expect(list.errors.messages[:provider]).to include('is not valid')
    end

    it 'should clear the identity if provider is "0"' do
      list = create(:contact_list, :mailchimp)
      expect(list.identity).not_to be_blank

      list.update_attributes(provider: '0')
      expect(list.identity).to be_blank
    end

    it 'should notify the old identity when the identity is updated' do
      list = create(:contact_list, :mailchimp)
      old_identity = list.identity
      expect(old_identity).to receive(:contact_lists_updated)
      allow(Identity).to receive(:find_by).and_return(old_identity)
      list.identity = create(:identity, :constantcontact)
      list.save
    end

    it 'should message the identity when the contact list is destroyed' do
      list = create(:contact_list, :mailchimp)
      old_identity = list.identity
      expect(old_identity).to receive(:contact_lists_updated)
      allow(Identity).to receive(:find_by).and_return(old_identity)
      list.destroy
    end
  end

  describe 'site_elements_count' do
    let(:num) { 3 }

    it 'runs the number of site_elements_count' do
      num.times { |_| contact_list.site_elements << create(:site_element) }
      expect(contact_list.site_elements_count).to eq(3)
    end
  end

  describe 'sync_one!' do
    before do
      allow_any_instance_of(Identity).to receive(:service_provider_valid).and_return(true)
      contact_list.save!
      allow(contact_list).to receive(:syncable?).and_return(true)
    end

    context 'oauth provider' do
      let(:provider) { 'mailchimp' }
      let(:credentials) { { 'token' => 'asdf' } }
      let(:extra) { { 'metadata' => { 'api_endpoint' => 'asdf' } } }

      before do
        expect_any_instance_of(Identity).to receive(:credentials).and_return(credentials)
        expect_any_instance_of(Identity).to receive(:extra).and_return(extra)
      end

      it 'should not raise error' do
        expect(service_provider).to be_oauth
        expect(service_provider).to receive(:subscribe)
        contact_list.sync_one! 'email@email.com', 'Test Testerson'
      end
    end

    context 'webhook' do
      it 'syncs' do
        allow(contact_list).to receive(:data) { { 'webhook_url' => 'http://url.com/webhooks' } }
        expect(service_provider).to receive(:subscribe).with(nil, 'email@email.com', 'Name Mcnamerson', true)

        contact_list.sync_one!('email@email.com', 'Name Mcnamerson')
      end
    end

    context 'embed code provider' do
      let(:provider) { 'mad_mimi_form' }
      let(:contact_list) { create(:contact_list, :embed_iframe).tap { |c| c.identity = identity } }
      let(:service_provider) { contact_list.service_provider }
      let(:double_optin) { ContactList.new.double_optin }

      it 'should sync' do
        expect(service_provider).to be_a(ServiceProviders::MadMimiForm)
        expect(service_provider).to be_embed_code
        expect(service_provider).to receive(:subscribe_params).with('email@email.com', 'Test Testerson', double_optin)
        contact_list.sync_one! 'email@email.com', 'Test Testerson'
      end
    end

    it 'creates a log entry' do
      allow(contact_list).to receive(:oauth?) { true }
      allow(service_provider).to receive(:subscribe)

      expect {
        contact_list.sync_one! 'email@email.com', 'Test Testerson'
      }.to change { ContactListLog.count }.by(1)
    end

    it 'saves the error in a log entry' do
      allow(contact_list).to receive(:oauth?) { true }
      allow(service_provider).to receive(:subscribe).and_raise('this error')
      expect { contact_list.sync_one! 'email@email.com', 'Test Testerson' }.to raise_error
      expect(contact_list.contact_list_logs.last.error).to include('this error')
    end

    it 'saves the stacktrace in a log entry' do
      allow(contact_list).to receive(:oauth?) { true }
      allow(service_provider).to receive(:subscribe).and_raise('this error')
      expect { contact_list.sync_one! 'email@email.com', 'Test Testerson' }.to raise_error('this error')
      expect(contact_list.contact_list_logs.last.stacktrace).to_not be_blank
    end

    it 'marks a log entry as completed' do
      allow(contact_list).to receive(:oauth?) { true }
      allow(service_provider).to receive(:subscribe)

      expect {
        contact_list.sync_one! 'email@email.com', 'Test Testerson'
      }.to change { ContactListLog.where(completed: true).count }.by(1)
    end
  end

  it 'should handle invalid JSON correctly' do
    contact_list.update_column :data, '{"url":"http://yoursite.com/goal",does_not_include":[",'

    expect { contact_list.reload.data }.to raise_error(JSON::ParserError)
  end

  describe 'email syncing errors' do
    before do
      allow(Hello::DataAPI).to receive(:contacts).and_return([:foo, :bar])
      allow(contact_list).to receive(:syncable?).and_return(true)
      allow(contact_list).to receive(:oauth?).and_return(true)
    end

    after { contact_list.sync! }

    describe 'for mailchimp' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::MailChimp)
      end

      it 'if someone has an invalid list stored, delete the identity and notify them' do
        expect(contact_list).to receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: Invalid MailChimp List ID'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
      end

      it "if someone's token is no longer valid, delete the identity and notify them" do
        expect(contact_list).to receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: Invalid Mailchimp API Key'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
      end

      it 'if someone has deleted their account, delete the identity and notify them' do
        expect(contact_list).to receive(:batch_subscribe).and_raise(Gibbon::MailChimpError.new('MailChimp API Error: This account has been deactivated'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
      end
    end

    describe 'for campaign monitor' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::CampaignMonitor)
      end

      it 'if someone has revoked our access, delete the identity and notify them' do
        expect(contact_list).to receive(:batch_subscribe).and_raise(CreateSend::RevokedOAuthToken.new(Hashie::Mash.new(Code: 122, Message: 'Revoked OAuth Token')))
        expect(contact_list.identity).to receive :destroy_and_notify_user
      end
    end

    describe 'for aweber' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::AWeber)
      end

      it 'if someone has an invalid list stored, delete the identity and notify them' do
        expect(contact_list).to receive(:batch_subscribe).and_raise(URI::InvalidURIError.new('404 Resource Not Found'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
      end

      it "if someone's token is no longer valid, or they have deleted their account, delete the identity and notify them" do
        expect(contact_list).to receive(:batch_subscribe).and_raise(ArgumentError.new('This account has been deactivated'))
        expect(contact_list.identity).to receive :destroy_and_notify_user
      end
    end

    describe 'for constantcontact' do
      before do
        allow(identity).to receive(:service_provider_class).and_return(ServiceProviders::ConstantContact)
      end

      it 'if someone has an invalid list stored, delete the identity and notify them' do
        response = OpenStruct.new(code: 404, body: '404 Resource Not Found')
        expect(contact_list).to receive(:batch_subscribe).and_raise(RestClient::ResourceNotFound.new(response))
        expect(contact_list.identity).to receive :destroy_and_notify_user
      end
    end
  end

  describe '#destroy' do
    it 'deletes contact list from default scope' do
      expect {
        contact_list.destroy
      }.to change { ContactList.count }.by(-1)
    end

    it 'soft deletes a contact list' do
      expect {
        contact_list.destroy
      }.to change { ContactList.only_deleted.count }
    end
  end

  describe '#subscribers' do
    it 'gets subscribers from the data API' do
      allow(Hello::DataAPI).to receive(:contacts).and_return([['person@gmail.com', 'Per Son', 123456789]])
      expect(contact_list.subscribers).to eql [{ email: 'person@gmail.com', name: 'Per Son', subscribed_at: Time.zone.at(123456789) }]
    end

    it 'defaults to [] if data API returns nil' do
      allow(Hello::DataAPI).to receive(:contacts).and_return(nil)
      expect(contact_list.subscribers).to be_empty
    end

    it 'sends a limit to the data api if specified' do
      expect(Hello::DataAPI).to receive(:contacts).with(contact_list, 100)
      contact_list.subscribers(100)
    end
  end

  describe '#subscriber_statuses' do
    it 'returns empty hash if service provider does not retreive statuses' do
      allow(service_provider).to receive(:respond_to?).with(:subscriber_statuses).and_return false
      expect(contact_list.subscriber_statuses([{ email: 'test' }])).to eq({})
    end

    it 'returns a hash with the status as returned by the service provider' do
      subscribers = [{ email: 'test@test.com' }, { email: 'test2@test.com' }]
      result = { 'test@test.com' => 'pending', 'test2@test.com' => 'subscribed' }
      expect(service_provider)
        .to receive(:subscriber_statuses)
        .with(contact_list, ['test@test.com', 'test2@test.com']).and_return(result)
      expect(contact_list.subscriber_statuses(subscribers)).to eq(result)
    end
  end

  describe '#num_subscribers' do
    it 'gets number of subscribers from the data API' do
      allow(Hello::DataAPI).to receive(:contact_list_totals).and_return(contact_list.id.to_s => 5)
      expect(contact_list.num_subscribers).to eq(5)
    end

    it 'defaults to 0 if data API returns nil' do
      allow(Hello::DataAPI).to receive(:contact_list_totals).and_return(nil)
      expect(contact_list.num_subscribers).to eq(0)
    end
  end

  describe '#data' do
    it 'drops nil values in data' do
      contact_list.data = { 'remote_name' => '', 'remote_id' => 1 }
      contact_list.identity = nil
      allow(contact_list).to receive(:sync_all!).and_return(true)
      contact_list.save
      expect(contact_list.data['remote_name']).to be_nil
    end
  end
end

describe ContactList, 'embed code' do
  subject { create(:contact_list, :embed_code) }

  before { subject.data['embed_code'] = embed_code }

  context 'invalid' do
    let(:embed_code) { 'asdf' }
    before { subject.data['embed_code'] = embed_code }

    describe '#data' do
      it { expect(subject.data).to eql 'embed_code' => 'asdf' }
    end

    it { expect(subject.valid?).to be false }
  end

  context 'invalid' do
    let(:embed_code) { '<<asdfasdf>>>' }
    it { expect(subject.valid?).to be false }
  end

  context 'invalid' do
    let(:embed_code) { '<from></from>' }
    it { expect(subject.valid?).to be false }
  end

  context 'valid' do
    let(:embed_code) { '<form></form>' }
    it { expect(subject.valid?).to be true }
  end
end

describe ContactList, '#needs_to_reconfigure?' do
  it 'returns false if not syncable' do
    list = ContactList.new

    allow(list).to receive(:syncable?) { false }

    expect(list.needs_to_reconfigure?).to eql(false)
  end

  it 'returns false if syncs with oauth' do
    list = ContactList.new

    allow(list).to receive(:syncable?) { true }
    allow(list).to receive(:oauth?) { true }

    expect(list.needs_to_reconfigure?).to eql(false)
  end

  it 'returns false if syncs with an api_key' do
    list = ContactList.new

    allow(list).to receive(:syncable?) { true }
    allow(list).to receive(:oauth?) { false }
    allow(list).to receive(:api_key?) { true }

    expect(list.needs_to_reconfigure?).to eql(false)
  end

  it 'returns false when able to generate subscribe params' do
    list = ContactList.new

    allow(list).to receive(:syncable?) { true }
    allow(list).to receive(:oauth?) { false }
    allow(list).to receive(:api_key?) { false }
    allow(list).to receive(:subscribe_params) { true }

    expect(list.needs_to_reconfigure?).to eql(false)
  end

  it 'returns true when not able to generate subscribe params' do
    list = ContactList.new

    allow(list).to receive(:syncable?) { true }
    allow(list).to receive(:oauth?) { false }
    allow(list).to receive(:api_key?) { false }
    allow(list).to receive(:subscribe_params) { raise('hell') }

    expect(list.needs_to_reconfigure?).to eql(true)
  end
end

describe ContactList, '#tags' do
  it 'returns an empty array when no tags have been saved' do
    contact_list = ContactList.new

    expect(contact_list.tags).to eql([])
  end

  it 'returns the tags that have been already saved' do
    contact_list = ContactList.new data: { 'tags' => %w(1 2 3) }

    expect(contact_list.tags).to eql(%w(1 2 3))
  end
end
