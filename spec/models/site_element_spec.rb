require 'spec_helper'

describe SiteElement do
  it_behaves_like 'a model triggering script regeneration'

  let(:element) { create(:site_element, :traffic) }
  let(:contact_list) { create(:contact_list) }
  let(:site) { create(:site) }

  it 'belongs to a site through a rule set' do
    element.rule = nil
    expect(element.site).to be_nil
  end

  describe 'validations' do
    it 'requires a contact list if element_subtype is "email"' do
      expect(element).to be_valid

      element.contact_list = contact_list
      expect(element).to be_valid
    end

    describe '#site_is_capable_of_creating_element' do
      it 'does not allow an unpersisted element to be created when site is at its limit' do
        capability = double 'capability', at_site_element_limit?: true
        site.stub capabilities: capability

        element = SiteElement.new
        element.stub site: site
        element.valid?

        expect(element.errors[:site]).to eq(['is currently at its limit to create site elements'])
      end

      it 'allows a persisted element to be updated when site is at its limit' do
        capability = double('capability', at_site_element_limit?: true)
        site.stub(capabilities: capability)
        element.stub site: site
        expect(element).to be_valid
      end
    end

    describe 'callbacks' do
      it 'removes unreferenced image uploads' do
        image = create(:image_upload, site: element.site)
        create(:image_upload, site: element.site)

        expect {
          element.active_image = image
          element.save
        }.to change { ImageUpload.count }.by(-1)
      end

      it 'does not remove image uploads that are still active' do
        image = create(:image_upload, site: element.site)
        element.update(active_image: image)

        expect {
          element.headline = 'dsfadsf' # trigger save
          element.save
        }.to change { ImageUpload.count }.by(0)
      end

      it 'does not remove image uploads that are active for other elements' do
        image = create(:image_upload, site: element.site)
        create(:site_element, active_image_id: image.id, rule: create(:rule, site: element.site))

        expect {
          element.headline = 'a new headline'
          element.save
        }.to change { ImageUpload.count }.by(0)
      end
    end

    describe '#redirect_has_url' do
      context 'when subtype is email' do
        let(:element) { create(:site_element, :email) }

        it 'requires a the correct capabilities' do
          allow(element.site.capabilities).to receive(:after_submit_redirect?).and_return(false)
          element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]

          element.save

          expect(element.errors['settings.redirect_url']).to include('is a pro feature')
        end

        it 'requires a redirect url if after_email_submit_action is :redirect' do
          allow(element.site.capabilities).to receive(:after_submit_redirect?).and_return(true)
          element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]

          element.save

          expect(element.errors['settings.redirect_url']).to include('cannot be blank')
        end

        it "doesn't require a redirect url if after_email_submit_action is not :redirect" do
          allow(element.site.capabilities).to receive(:after_submit_redirect?).and_return(true)
          element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:show_default_message]

          element.save

          expect(element.errors['settings.redirect_url']).to be_empty
        end
      end

      context 'when subtype is not email' do
        it "doesn't care about redirect url" do
          element.save
          expect(element.errors['settings.redirect_url']).to be_empty
        end
      end
    end
  end

  describe '#recent' do
    before { SiteElement.destroy_all }
    it 'should only include site elements created within the last 2 weeks' do
      expect(SiteElement.recent(5).map { |se| se.created_at > 2.weeks.ago }.count).to eq(0)
    end
  end

  describe 'HTML tags and attributes whitelisting' do
    it 'strips the <section> element' do
      text = 'Text'
      headline = "<section>#{ text }</section>"

      site_element = SiteElement.new headline: headline

      expect(site_element.headline).to eq text
    end

    it 'allows data-hb-geolocation attribute' do
      headline = '<span data-hb-geolocation="country">Country</span>'

      site_element = SiteElement.new headline: headline

      expect(site_element.headline).to eq headline
    end
  end

  describe '#redirect_has_url' do
    let(:element) { create(:site_element, :email) }

    context 'when subtype is email' do
      it 'requires a the correct capabilities' do
        allow(element.site.capabilities).to receive(:after_submit_redirect?).and_return(false)
        element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]

        element.save

        expect(element.errors['settings.redirect_url']).to include('is a pro feature')
      end

      it 'requires a redirect url if after_email_submit_action is :redirect' do
        allow(element.site.capabilities).to receive(:after_submit_redirect?).and_return(true)
        element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]

        element.save

        expect(element.errors['settings.redirect_url']).to include('cannot be blank')
      end

      it "doesn't require a redirect url if after_email_submit_action is not :redirect" do
        allow(element.site.capabilities).to receive(:after_submit_redirect?).and_return(true)
        element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:show_default_message]

        element.save

        expect(element.errors['settings.redirect_url']).to be_empty
      end
    end

    context 'when subtype is not email' do
      it "doesn't care about redirect url" do
        element.save
        expect(element.errors['settings.redirect_url']).to be_empty
      end
    end
  end

  describe '#has_thank_you_text' do
    let(:element) { create(:site_element, :email) }

    context 'when subtype is email' do
      it 'requires a the correct capabilities' do
        allow(element.site.capabilities).to receive(:custom_thank_you_text?).and_return(false)
        element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:custom_thank_you_text]

        element.save

        expect(element.errors['custom_thank_you_text']).to include('is a pro feature')
      end

      it 'requires thank you text if after_email_submit_action is :custom_thank_you_text' do
        allow(element.site.capabilities).to receive(:custom_thank_you_text?).and_return(true)
        element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:custom_thank_you_text]

        element.save

        expect(element.errors['custom_thank_you_text']).to include('cannot be blank')
      end

      it "doesn't require thank you text if after_email_submit_action is not :custom_thank_you_text" do
        allow(element.site.capabilities).to receive(:custom_thank_you_text?).and_return(true)
        element.save
        expect(element.errors['custom_thank_you_text']).to be_empty
      end
    end
  end

  describe '#toggle_paused!' do
    let(:site_element) { create(:site_element, :traffic) }

    it 'toggles an element from paused to unpaused' do
      expect {
        site_element.toggle_paused!
      }.to change(site_element, :paused?).from(false).to(true)
    end

    it 'toggles an element from unpaused to paused' do
      site_element.update_attribute :paused, true

      expect {
        site_element.toggle_paused!
      }.to change(site_element, :paused?).from(true).to(false)
    end
  end

  describe '#total_views' do
    let(:element) { create(:site_element, :traffic) }
    let(:site) { element.site }

    it 'returns total views as reported by the data API' do
      allow(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return(element.id.to_s => Hello::DataAPI::Performance.new([[10, 5], [12, 6]]))
      expect(element.total_views).to eq(12)
    end

    it 'returns zero if no data is returned from the data API' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({})
      expect(element.total_views).to eq(0)
    end

    it 'returns zero if data API returns nil' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return(nil)
      expect(element.total_views).to eq(0)
    end
  end

  describe '#total_conversions' do
    let(:element) { create(:site_element, :traffic) }
    let(:site) { element.site }

    it 'returns total views as reported by the data API' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return(element.id.to_s => Hello::DataAPI::Performance.new([[10, 5], [12, 6]]))
      expect(element.total_conversions).to eq(6)
    end

    it 'returns zero if no data is returned from the data API' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({})
      expect(element.total_conversions).to eq(0)
    end

    it 'returns zero if data API returns nil' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return(nil)
      expect(element.total_conversions).to eq(0)
    end
  end

  describe '#converted?' do
    let(:element) { create(:site_element, :traffic) }
    let(:site) { element.site }

    it 'is false when there are no conversions', aggregate_failures: true do
      expect(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return({})
      expect(element).not_to be_converted
    end

    it 'is true when there are conversions', aggregate_failures: true do
      expect(Hello::DataAPI).to receive(:lifetime_totals).with(site, site.site_elements, anything, {}).and_return(element.id.to_s => Hello::DataAPI::Performance.new([[10, 5], [12, 6]]))
      expect(element).to be_converted
    end
  end

  describe '#display_thank_you_text' do
    let(:site) { create(:site, :with_user) }
    let(:rule) { create(:rule, site: site) }
    let(:element) { create(:site_element, :email, rule: rule) }

    context 'when it is a free account' do
      before do
        allow(element.site).to receive(:free?) { true }
      end

      context 'and after_email_submit_action is :show_default_message' do
        before do
          allow(element).to receive(:after_email_submit_action) { :show_default_message }
        end

        it 'should return the default message regardless of the thank you text' do
          element.thank_you_text = 'do not show this'
          expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_FREE_EMAIL_THANK_YOU)
        end
      end

      context 'when after_email_submit_action is not :show_default_message' do
        before do
          allow(element).to receive(:after_email_submit_action) { :something }
        end

        it 'should return the default message if thank you text not set' do
          element.thank_you_text = ''
          expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_FREE_EMAIL_THANK_YOU)
        end

        it 'should still return the default thank you text' do
          element.thank_you_text = 'dont show this message'
          expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_FREE_EMAIL_THANK_YOU)
        end
      end
    end

    context 'when it is a pro site' do
      before do
        subscription = Subscription::Pro.new(schedule: 'monthly')
        element.site.change_subscription(subscription, nil, 90.days)
      end

      context 'when after_email_submit_action is :show_default_message' do
        it 'should return the default message regardless of the thank you text' do
          element.thank_you_text = 'test'
          allow(element).to receive(:after_email_submit_action).and_return(:show_default_message)
          expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_EMAIL_THANK_YOU)
        end
      end

      context 'when after_email_submit_action is not :show_default_message' do
        it 'should return the default message if thank you text not set' do
          element.thank_you_text = ''
          allow(element).to receive(:after_email_submit_action).and_return(:something)
          expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_EMAIL_THANK_YOU)
        end

        it 'should return the thank you text' do
          element.thank_you_text = 'test'
          allow(element).to receive(:after_email_submit_action).and_return(:something)
          expect(element.display_thank_you_text).to eq('test')
        end
      end
    end
  end

  describe '#email_redirect?' do
    it 'is false for showing default message submit action' do
      action_id = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:show_default_message]
      settings = { 'after_email_submit_action' => action_id }

      site_element = SiteElement.new settings: settings

      expect(site_element).not_to be_email_redirect
    end

    it 'is false for custom thank you text submit action' do
      action_id = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:custom_thank_you_text]
      settings = { 'after_email_submit_action' => action_id }

      site_element = SiteElement.new settings: settings

      expect(site_element).not_to be_email_redirect
    end

    it 'is true for redirect submit action' do
      action_id = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]
      settings = { 'after_email_submit_action' => action_id }

      site_element = SiteElement.new settings: settings

      expect(site_element).to be_email_redirect
    end
  end

  describe '#external_tracking' do
    let(:capabilities) { double 'Capabilities', external_tracking?: false }
    let(:site) { create :site }
    let(:id) { 777 }
    let(:site_element) { SiteElement.new id: id }

    before do
      allow(site).to receive(:capabilities).and_return capabilities
      allow(site_element).to receive(:site).and_return site
    end

    context 'when site does not have `external_tracking` capabilities' do
      it 'is an empty array' do
        expect(site_element.external_tracking).to eq []
      end
    end

    context 'when site has `external_tracking` capabilities' do
      it 'is an array of Google Analytics external events' do
        allow(capabilities).to receive(:external_tracking?).and_return true

        external_tracking = site_element.external_tracking

        expect(external_tracking).to be_an Array
        expect(external_tracking.count).to be > 1

        event = external_tracking.first

        expect(event).to be_a Hash
        expect(event[:provider]).to eq 'google_analytics'
        expect(event[:category]).to eq 'Hello Bar'
        expect(event[:site_element_id]).to eq id
        expect(event[:label]).to include id.to_s
      end
    end
  end
end
