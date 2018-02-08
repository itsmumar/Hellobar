describe 'SiteElements requests' do
  let(:settings) do
    {
      'fields_to_collect' => [
        {
          'id' => 'fieldid1',
          'type' => 'builtin-name',
          'label' => 'Name',
          'is_enabled' => 'true'
        },
        {
          'id' => 'fieldid3',
          'type' => 'builtin-phone',
          'label' => 'phone',
          'is_enabled' => 'true'
        }
      ]
    }
  end

  let(:manipulated_settings) do
    {
      'fields_to_collect' => [
        {
          'id' => 'fieldid1',
          'type' => 'builtin-name',
          'label' => 'Name',
          'is_enabled' => 'true',
          'wrong_field' => 'wrong_field'
        },
        {
          'id' => 'fieldid3',
          'type' => 'builtin-phone',
          'label' => 'phone',
          'is_enabled' => 'true',
          'wrong_field' => 'wrong_field'
        }
      ]
    }
  end

  let(:settings_custom_fields) do
    settings['fields_to_collect'] += [
      {
        'id' => 'fieldid4',
        'type' => 'custom-company-name',
        'label' => 'Company Name',
        'is_enabled' => 'true'
      },
      {
        'id' => 'fieldid5',
        'type' => 'custom-address',
        'label' => 'Address',
        'is_enabled' => 'false'
      }
    ]

    { 'fields_to_collect' => settings['fields_to_collect'] }
  end

  let(:user) { create :user }
  let(:site) { create :site, :with_rule, :installed, user: user }
  let!(:element) { create :bar, site: site }

  context 'when unauthenticated' do
    describe 'GET :show' do
      it 'responds with a redirect to the login page' do
        get site_site_element_path(site, element)

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET #show' do
      it 'serializes a site_element to json' do
        get site_site_element_path(element.site, element, format: :json)

        expect(json).to include(
          id: element.id,
          headline: element.headline,
          background_color: element.background_color
        )
      end
    end

    describe 'PUT #toggle_paused' do
      it 'responds with success' do
        put site_site_element_toggle_paused_path(site, element)
        expect(response.status).to eq(200)
      end

      it 'toggle site element status' do
        put site_site_element_toggle_paused_path(site, element)
        expect(element.reload).to be_paused
      end

      it 'regenerates script' do
        expect { put site_site_element_toggle_paused_path(site, element) }
          .to have_enqueued_job(GenerateStaticScriptJob).with(site)
      end

      context 'when site element returns validation error' do
        before do
          allow_any_instance_of(SiteElement).to receive(:toggle_paused!) do |record|
            record.errors.add(:site, 'is invalid')
            raise ActiveRecord::RecordInvalid, record
          end
        end

        it 'respond with errors' do
          put site_site_element_toggle_paused_path(site, element)

          expect(response.status).to eq(422)

          expect(json[:errors]).to match site: ['is invalid']
          expect(json[:full_error_messages]).to match_array ['Site is invalid']
        end
      end
    end

    describe 'POST #create' do
      let(:owner) { user }
      let(:rule_id) { site.rules.first.id }

      def post_create(params)
        post site_site_elements_path(element.site, site_element: params)
      end

      it 'sets the correct error if a rule is not provided' do
        allow_any_instance_of(StaticScript).to receive(:generate).and_return(true)

        post_create element_subtype: 'traffic', rule_id: 0

        expect(json[:errors]).to match(rule: ["can't be blank"])
      end

      it 'sets `fields_to_collect` under `settings` and return back' do
        post_create element_subtype: 'traffic', rule_id: rule_id, settings: settings

        expect(json).to include settings: settings
      end

      it 'accepts whitelisted fields only' do
        post_create(
          element_subtype: 'traffic',
          rule_id: rule_id,
          settings: manipulated_settings
        )

        expect(json).to include settings: settings
      end

      it 'accepts custom fields' do
        post_create(
          element_subtype: 'traffic',
          rule_id: rule_id,
          settings: settings_custom_fields
        )

        expect(json).to include settings: settings_custom_fields
      end

      it 'sets the success flash message on create' do
        expect { post_create element_subtype: 'traffic', rule_id: rule_id }
          .to change(SiteElement, :count)
          .by(1)

        expect(request.flash[:success]).to be_present
      end
    end

    describe 'GET #new' do
      def send_request
        get new_site_site_element_path site, format: :json
      end

      it 'defaults the font_id to the column default' do
        send_request

        default_font_id = SiteElement.columns_hash['font_id'].default

        expect(json).to include font_id: default_font_id
      end

      context 'with pro subscription' do
        let!(:subscription) { create(:subscription, :pro, :paid, site: site) }

        it 'defaults branding to false if pro' do
          send_request
          expect(json).to include show_branding: false
        end
      end

      context 'with free subscription' do
        let!(:subscription) { create(:subscription, :free, site: site) }

        it 'defaults branding to true' do
          send_request
          expect(json).to include show_branding: true
        end

        it 'sets `theme_id` to `autodetect`' do
          send_request
          expect(json).to include theme_id: 'autodetect'
        end
      end
    end

    describe 'PUT #update' do
      let(:site) { create :site, :pro, :with_rule, :installed, user: user }
      let(:element) { create(:bar, site: site, closable: false) }
      let(:params) { Hash[closable: true] }

      before do
        allow_any_instance_of(StaticScript).to receive(:generate)
      end

      def put_update(params)
        put site_site_element_path(site, element, site_element: params)
      end

      it 'updates with the params' do
        expect(UpdateSiteElement)
          .to receive_service_call
          .with(element, closable: 'true')
          .and_return(element)

        put_update params
      end

      context 'when updating succeeds' do
        it 'returns successfully' do
          put_update params
          expect(response).to be_success
        end

        it 'sets the success flash' do
          put_update params
          expect(request.flash[:success]).to be_present
        end

        it 'sends json of the updated attributes' do
          put_update params

          expect(json).to include id: element.id, closable: true
        end

        context 'if type was changed' do
          let!(:element) { create(:bar, :email, site: site) }

          it 'sends json of new element' do
            put_update params.merge(element_subtype: 'traffic')

            expect(json[:id]).not_to eq(element.id)
          end
        end

        context 'updates `fields_to_collect`' do
          it 'with valid attrs' do
            put_update params.merge(settings: settings)

            expect(response).to be_success
            expect(json).to include settings: settings
          end

          it 'with whitelisted attrs only and ignore the others' do
            put_update params.merge(settings: manipulated_settings)

            expect(response).to be_success
            expect(json).to include settings: settings
          end

          it 'with cutom fields too' do
            put_update params.merge(settings: settings_custom_fields)

            expect(json).to include settings: settings_custom_fields
          end
        end
      end

      context 'when updating fails' do
        let(:params) { Hash[border_color: ''] }

        it 'returns unprocessable_entity' do
          put_update params

          expect(response.status).to eq(422)
        end
      end

      context 'when you have invalid image_id referenced in SiteElement' do
        let(:element) { create :bar, site: site, active_image_id: 1 }

        it 'returns unprocessable_entity' do
          put_update params.merge(active_image_id: 2)

          expect(response.status).to eq(422)
          expect(json[:errors]).to match base: ['Previous image could not be found']
          expect(json[:full_error_messages]).to match_array ['Previous image could not be found']
        end
      end
    end
  end
end
