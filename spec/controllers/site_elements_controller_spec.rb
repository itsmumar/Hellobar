require 'spec_helper'

describe SiteElementsController do
  let(:settings) do
    {
      'fields_to_collect' => [
        {
          'id'          => 'fieldid1',
          'type'        => 'builtin-name',
          'label'       => 'Name',
          'is_enabled'  => true
        },
        {
          'id'          => 'fieldid3',
          'type'        => 'builtin-phone',
          'label'       => 'phone',
          'is_enabled'  => true
        }
      ]
    }
  end

  let(:manipulated_settings) do
    {
      'fields_to_collect' => [
        {
          'id'          => 'fieldid1',
          'type'        => 'builtin-name',
          'label'       => 'Name',
          'is_enabled'  => true,
          'wrong_field' => 'wrong_field'
        },
        {
          'id'          => 'fieldid3',
          'type'        => 'builtin-phone',
          'label'       => 'phone',
          'is_enabled'  => true,
          'wrong_field' => 'wrong_field'
        }
      ]
    }
  end

  let(:settings_custom_fields) do
    settings['fields_to_collect'] += [
      {
        'id'          => 'fieldid4',
        'type'        => 'custom-company-name',
        'label'       => 'Company Name',
        'is_enabled'  => true
      },
      {
        'id'          => 'fieldid5',
        'type'        => 'custom-address',
        'label'       => 'Address',
        'is_enabled'  => false
      }
    ]

    { 'fields_to_collect' => settings['fields_to_collect'] }
  end

  describe 'GET show' do
    let(:user) { create(:user) }
    let(:element) { create(:site_element) }
    before do
      element.site.users << user
    end

    it 'serializes a site_element to json' do
      stub_current_user(user)
      Site.any_instance.stub(has_script_installed?: true)

      get :show, site_id: element.site, id: element, format: :json

      expect_json_response_to_include(
        id: element.id,
        headline: element.headline,
        background_color: element.background_color
      )
    end
  end

  describe 'POST create' do
    let!(:site) { create(:site) }
    let(:owner) { site.owners.first }

    before(:each) do
      stub_current_user(owner)
    end

    it 'sets the correct error if a rule is not provided' do
      Site.any_instance.stub(generate_script: true)

      post :create, site_id: site.id, site_element: { element_subtype: 'traffic', rule_id: 0 }

      expect_json_to_have_error(:rule, "can't be blank")
    end

    it 'sets `fields_to_collect` under `settings` and return back' do
      post :create, site_id: site.id, site_element: { element_subtype: 'traffic',
                                                      rule_id: 0,
                                                      settings: settings }

      expect_json_response_to_include(settings: settings)
    end

    it 'accepts whitelisted fields only' do
      post :create, site_id: site.id, site_element: { element_subtype: 'traffic',
                                                      rule_id: 0,
                                                      settings: manipulated_settings }

      expect_json_response_to_include(settings: settings)
    end

    it 'accepts custom fields' do
      post :create, site_id: site.id, site_element: { element_subtype: 'traffic',
                                                      rule_id: 0,
                                                      settings: settings_custom_fields }

      expect_json_response_to_include(settings: settings_custom_fields)
    end

    it 'sets the success flash message on create' do
      SiteElement.any_instance.stub(valid?: true, save!: true)

      expect {
        post :create, site_id: site.id, site_element: { element_subtype: 'traffic', rule_id: 0 }
      }.to change { flash[:success] }.from(nil)
    end
  end

  describe 'POST new' do
    it 'defaults the font_id to the column default' do
      membership = create(:site_membership)
      stub_current_user(membership.user)

      get :new, site_id: membership.site.id, format: :json

      default_font_id = SiteElement.columns_hash['font_id'].default
      expect_json_response_to_include(font_id: default_font_id)
    end

    context 'with pro subscription' do
      it 'defaults branding to false if pro' do
        site = create(:site, :with_user)
        subscription = create(:pro_subscription, site: site)
        stub_current_user(site.owners.first)

        get :new, site_id: subscription.site.id, format: :json

        expect_json_response_to_include(show_branding: false)
      end
    end

    context 'with free subscription' do
      let(:site) { create(:site, :with_user) }
      let(:subscription) { create(:free_subscription, site: site) }
      before { stub_current_user(site.owners.first) }

      it 'defaults branding to true if free user' do
        get :new, site_id: subscription.site.id, format: :json

        expect_json_response_to_include(show_branding: true)
      end

      it 'sets the theme id to the default theme id' do
        get :new, site_id: subscription.site.id, format: :json

        default_theme = Theme.where(default_theme: true).first
        expect_json_response_to_include(theme_id: default_theme.id)
      end

      it "doesn't push an unsaved element into the site.site_elements association" do
        membership = create(:site_membership)
        create(:rule, site: membership.site)
        stub_current_user(membership.user)

        get :new, site_id: membership.site.id, format: :json
        expect(assigns(:site_element).site.site_elements.map(&:id)).not_to include(nil)
      end
    end
  end

  describe 'POST update' do
    let(:user) { create(:user) }
    let(:element) { create(:site_element) }
    before do
      element.site.users << user
    end

    before do
      stub_current_user(user)

      allow_any_instance_of(Site).to receive(:generate_script)
      allow_any_instance_of(Site)
        .to receive(:lifetime_totals).and_return('1' => [[1, 0]])
    end

    it 'creates an updater' do
      expect(SiteElements::Update).to receive(:new).and_call_original

      post :update, valid_params(element)
    end

    it 'updates with the params' do
      updater = double(SiteElements::Update, element: element)
      params = valid_params(element)

      expect(SiteElements::Update).to receive(:new).and_return(updater)
      expect(updater).to receive(:run).and_return(true)

      post :update, params
    end

    context 'when updating succeeds' do
      it 'returns successfully' do
        post :update, valid_params(element)

        expect(response).to be_success
      end

      it 'sets the success flash' do
        expect {
          post :update, valid_params(element)
        }.to change { flash[:success] }.from(nil)
      end

      it 'sends json of the updated attributes' do
        post :update, valid_params(element)

        expect_json_response_to_include(id: element.id, closable: true)
      end

      context 'if type was changed' do
        let(:element) { create(:site_element, :email) }

        it 'sends json of new element' do
          params = valid_params(element)
          params[:site_element][:element_subtype] = 'traffic'

          post :update, params

          json_response = parse_json_response
          expect(json_response[:id]).not_to eq(element.id)
        end
      end

      context 'updates `fields_to_collect`' do
        before(:each) do
          @params = valid_params(element)
        end

        it 'with valid attrs' do
          @params[:site_element][:settings] = settings
          post :update, @params

          expect(response).to be_success
          expect_json_response_to_include(settings: settings)
        end

        it 'with whitelisted attrs only and ignore the others' do
          @params[:site_element][:settings] = manipulated_settings
          post :update, @params

          expect_json_response_to_include('settings' => settings)
        end

        it 'with cutom fields too' do
          @params[:site_element][:settings] = settings_custom_fields
          post :update, @params

          expect_json_response_to_include('settings' => settings_custom_fields)
        end
      end
    end

    context 'when updating fails' do
      it 'returns unprocessable_entity' do
        post :update, invalid_params(element)

        expect(response.status).to eq(422)
      end

      def invalid_params(el)
        {
          id: el.id,
          site_id: el.site_id,
          site_element: { border_color: '' }
        }
      end
    end

    def valid_params(el)
      {
        id: el.id,
        site_id: el.site_id,
        site_element: { closable: true }
      }
    end

    def create_successful_updater
      updater = double(SiteElements::Update, update: true)
      expect(SiteElements::Update).to receive(:new).and_return(updater)
      updater
    end

    def create_failing_updater
      updater = double(SiteElements::Update, update: false)
      expect(SiteElements::Update).to receive(:new).and_return(updater)
      updater
    end
  end
end
