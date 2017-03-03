require 'spec_helper'

describe IdentitiesController do
  before do
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  fixtures :all

  before do
    @identity = identities(:mailchimp)
    @identity.extra = { 'metadata' => { 'api_endpoint' => 'https://us3.api.mailchimp.com' } }
    @identity.save
  end

  describe 'GET :show' do
    it 'should return the identity' do
      stub_current_user @identity.site.users.first
      Gibbon::Request.stubs(:new => double('gibbon'))
      ServiceProviders::MailChimp.any_instance.stub(:lists).and_return([])
      get :show, site_id: @identity.site.id, id: 'mailchimp'
      json = JSON.parse(response.body)
      json['id'].should == @identity.id
    end

    it 'should return null when identity doesnt exist' do
      stub_current_user @identity.site.users.first
      get :show, site_id: @identity.site.id, id: 'made_up_identity'
      response.body.should == 'null'
    end

    it 'should return nothing when there is an error retrieving the service provider' do
      stub_current_user @identity.site.users.first
      ServiceProviders::MailChimp.should_receive(:new).and_raise(Gibbon::MailChimpError)
      get :show, site_id: @identity.site.id, id: 'mailchimp'
      response.body.should == 'null'
    end
  end

  describe 'GET :new' do
    before do
      request.env['HTTP_REFERER'] = 'my_cool_referrer'
    end

    it 'should redirect to auth path when api_key param is not present' do
      stub_current_user @identity.site.users.first
      redirect_path = "/auth/my_cool_provider/?site_id=#{@identity.site.id}&redirect_to=my_cool_referrer"

      get :new, provider: 'my_cool_provider', site_id: @identity.site.id

      expect(controller).to redirect_to(redirect_path)
    end

    it 'should call create method when api_key param is present' do
      stub_current_user @identity.site.users.first
      allow_any_instance_of(Identity).to receive(:provider_config).and_return({ name: 'get_response_api' })
      expect(controller).to receive(:create).and_call_original

      get :new, provider: 'my_cool_provider', site_id: @identity.site.id, api_key: 'my_cool_api_key'
    end
  end

  describe 'POST :create' do
    it 'redirects when identity already exists' do
      api_key = 'my_cool_api_key'
      stub_current_user @identity.site.users.first
      identity = Identity.create! site_id: @identity.site.id, provider: 'get_response_api', api_key: api_key
      allow_any_instance_of(Identity).to receive(:provider_config).and_return({ name: 'get_response_api' })
      post :create, site_id: @identity.site.id, provider: 'get_response_api', api_key: api_key
      expect(response).to redirect_to('http://test.host/sites/483182012/contact_lists')
    end

    context 'api key identity' do
      before do
        request.env['HTTP_REFERER'] = 'my_cool_referrer'
      end

      it 'saves api key on the identity object' do
        api_key = 'valid-active-campaign-key'
        stub_current_user @identity.site.users.first
        post :create, site_id: @identity.site.id, provider: 'active_campaign',
                      api_key: api_key, app_url: 'crossover.api-us1.com'

        expect(Identity.last.api_key).to eq(api_key)
      end

      it 'sets the redirect patch on the oauth object' do
        api_key = 'my_cool_api_key'
        stub_current_user @identity.site.users.first
        post :create, site_id: @identity.site.id, provider: 'get_response_api', api_key: api_key

        expect(response).to redirect_to('my_cool_referrer')
      end
    end

    context 'oauth identity' do
      before(:each) do
        user = User.last
        @site = user.sites.first
        stub_current_user user
        allow_any_instance_of(Identity).to receive(:provider_config).and_return({ name: 'mailchimp' })
        allow_any_instance_of(Identity).to receive(:service_provider).and_return(nil)
      end

      it 'saves credentials on the identity object' do
        allow(controller).to receive(:env).
          and_return({
          'omniauth.auth'   => { 'credentials' => 'my_cool_creds' },
          'omniauth.params' => { 'redirect_to' => 'http://test.host/sites/483182012/site_elements/12312/new' } })
        post :create, site_id: @site.id, provider: 'mailchimp'
        expect(Identity.last.credentials).to eq('my_cool_creds')
      end

      context 'redirects' do
        it 'to email setting page' do
          allow(controller).to receive(:env).
            and_return({
            'omniauth.auth'   => { 'credentials' => 'my_cool_creds' },
            'omniauth.params' => { 'redirect_to' => 'http://test.host/sites/483182012/site_elements/12312/new' } })
          post :create, site_id: @site.id, provider: 'mailchimp'
          expect(response).to redirect_to(controller.env['omniauth.params']['redirect_to'] + '#/settings/emails')
        end

        it 'to referrer' do
          allow(controller).to receive(:env).
            and_return({
            'omniauth.auth'   => { 'credentials' => 'my_cool_creds' },
            'omniauth.params' => { 'redirect_to' => 'http://test.host/sites/483182012/contact_lists' } })
          post :create, site_id: @site.id, provider: 'mailchimp'
          expect(response).to redirect_to(controller.env['omniauth.params']['redirect_to'])
        end
      end
    end
  end
end
