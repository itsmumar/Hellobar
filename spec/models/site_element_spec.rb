describe SiteElement do
  let(:element) { create(:site_element, :traffic) }
  let(:contact_list) { create(:contact_list) }
  let(:site) { element.site }

  def stub_capability(site, capability, value = true)
    allow_any_instance_of(site.capabilities.class).to receive(capability).and_return(value)
  end

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
        allow(site).to receive(:capabilities).and_return(capability)

        element = SiteElement.new
        allow(element).to receive(:site).and_return(site)
        element.valid?

        expect(element.errors[:site]).to eq(['is currently at its limit to create site elements'])
      end

      it 'allows a persisted element to be updated when site is at its limit' do
        capability = double('capability', at_site_element_limit?: true)
        allow(site).to receive(:capabilities).and_return(capability)
        allow(element).to receive(:site).and_return(site)
        expect(element).to be_valid
      end
    end

    describe 'callbacks' do
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

    shared_examples 'capability validation' do |capability, attribute, error|
      context "when capabilities allows #{ capability }" do
        before do
          stub_capability(element.site, "#{ capability }?", true)
        end

        it "accept #{ capability } for paused element" do
          element.update(paused: true)
          expect(element.errors[attribute]).not_to include(error)
        end

        it "accept #{ capability } for unpaused element" do
          element.update(paused: false)
          expect(element.errors[attribute]).not_to include(error)
        end
      end

      context 'when capabilities denies closable' do
        before do
          stub_capability(element.site, :closable?, false)
        end

        it "accept #{ capability } for paused element" do
          element.update(paused: true)
          expect(element.errors[attribute]).not_to include(error)
        end

        it "rejects #{ capability } for unpaused element" do
          element.update(paused: false)
          expect(element.errors[attribute]).to include(error)
        end
      end
    end

    describe '#closable' do
      before do
        element.closable = true
      end

      include_examples 'capability validation', :closable, :site, 'subscription does not support closable elements. Upgrade subscription.'
    end

    describe '#custom_targeting' do
      before do
        element.rule.conditions << build(:condition, :url_path_includes, rule: element.rule)
      end

      include_examples 'capability validation', :custom_targeted_bars, :site, 'subscription does not support custom targeting. Upgrade subscription.'
    end

    describe '#precise_geolocation_targeting' do
      before do
        element.rule.conditions << build(:condition, :city, rule: element.rule)
      end

      include_examples 'capability validation', :precise_geolocation_targeting, :site, 'subscription does not support precise geolocation targeting. Upgrade subscription.'
    end

    describe '#thank_you_text' do
      context 'when subtype is email' do
        let(:element) { create(:site_element, :email) }

        context 'when after_email_submit_action is custom thank you' do
          before do
            element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:custom_thank_you_text]
          end

          include_examples 'capability validation', :custom_thank_you_text, :thank_you_text, 'subscription does not support custom thank you text. Upgrade subscription.'

          it 'requires custom thank_you_text' do
            stub_capability(element.site, :custom_thank_you_text?, true)

            element.save

            expect(element.errors[:thank_you_text]).to include('can\'t be blank')
          end
        end

        context 'when after_email_submit_action is not custom thank you' do
          before do
            element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:show_default_message]
          end

          it 'does not require custom thank_you_text' do
            stub_capability(element.site, :custom_thank_you_text?, true)

            element.save

            expect(element.errors[:thank_you_text]).to be_empty
          end
        end
      end

      context 'when subtype is not email' do
        it "doesn't care about thank you text" do
          element.save
          expect(element.errors[:thank_you_text]).to be_empty
        end
      end
    end

    describe '#redirect_url' do
      context 'when subtype is email' do
        let(:element) { create(:site_element, :email) }

        context 'when after_email_submit_action is custom redirect' do
          before do
            element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]
          end

          include_examples 'capability validation', :after_submit_redirect, :redirect_url, 'subscription does not support custom redirect URL. Upgrade subscription.'

          it 'requires custom redirect_url' do
            stub_capability(element.site, :after_submit_redirect?, true)
            element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]

            element.save

            expect(element.errors[:redirect_url]).to include('can\'t be blank')
          end
        end

        context 'when after_email_submit_action is not custom thank you' do
          before do
            element.settings['after_email_submit_action'] = SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:show_default_message]
          end

          it 'does not require custom redirect_url' do
            stub_capability(element.site, :after_submit_redirect?, true)

            element.save

            expect(element.errors[:redirect_url]).to be_empty
          end
        end
      end

      context 'when subtype is not email' do
        it "doesn't care about redirect url" do
          element.save
          expect(element.errors[:redirect_url]).to be_empty
        end
      end
    end
  end

  describe '#destroy' do
    let(:element) { create :site_element, :traffic, :with_active_image }

    it 'marks the record as deleted', :freeze do
      expect(element.deleted_at).to be_nil

      element.destroy

      expect(element.deleted_at).to eq Time.current

      expect {
        SiteElement.find(element.id)
      }.to raise_exception ActiveRecord::RecordNotFound
    end

    it 'destroys the record and nullifies active_image_id' do
      active_image = element.active_image

      element.destroy

      expect(active_image).to be_destroyed
      expect(element.reload.active_image_id).to be_nil
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

  describe '#toggle_paused!' do
    it 'toggles an element from paused to unpaused' do
      expect {
        element.toggle_paused!
      }.to change(element, :paused?).from(false).to(true)
    end

    it 'toggles an element from unpaused to paused' do
      element.update_attribute :paused, true

      expect {
        element.toggle_paused!
      }.to change(element, :paused?).from(true).to(false)
    end

    context 'when site is downgraded to free subscription' do
      before do
        create(:subscription, :pro, site: site, user: site.users.first, schedule: :monthly)
        element.rule.conditions << create(:condition, rule: element.rule)
        DowngradeSiteToFree.new(site).call
      end

      it 'pauses active site' do
        expect { element.toggle_paused! }.to change(element, :paused?).from(false).to(true)
      end

      it 'raise an error when toggling paused site' do
        element.update_attribute :paused, true

        expect { element.toggle_paused! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe '#total_views' do
    let(:element) { create(:site_element) }

    it 'returns total views' do
      allow(element).to receive(:statistics).and_return(double(views: 12))
      expect(element.total_views).to eq(12)
    end

    it 'returns zero if no data is returned from the data API' do
      allow(element).to receive(:statistics).and_return(double(views: 0))
      expect(element.total_views).to eq(0)
    end
  end

  describe '#total_conversions' do
    let(:element) { create(:site_element) }

    it 'returns total conversions' do
      allow(element).to receive(:statistics).and_return(double(conversions: 6))
      expect(element.total_conversions).to eq(6)
    end

    it 'returns zero if no data is returned from the data API' do
      allow(element).to receive(:statistics).and_return(double(conversions: 0))
      expect(element.total_conversions).to eq(0)
    end
  end

  describe '#converted?' do
    let(:element) { create(:site_element) }

    context 'when there are no conversions' do
      before { allow(element).to receive(:statistics).and_return(double(conversions: 0)) }

      specify { expect(element).not_to be_converted }
    end

    context 'when there are conversions' do
      before { allow(element).to receive(:statistics).and_return(double(conversions: 1)) }

      specify { expect(element).to be_converted }
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
        AddTrialSubscription.new(element.site, subscription: 'pro', trial_period: 90).call
        element.site.reload
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

  describe '#image_modal_url' do
    let(:image_modal_url) { element.image_modal_url }

    context 'when the element has no image' do
      let(:element) { create(:site_element, :traffic) }

      it { expect(image_modal_url).to be_nil }
    end

    context 'when the element has an image' do
      let(:element) { create(:site_element, :traffic, :with_active_image) }

      it 'returns the "modal" style URL' do
        expect(image_modal_url).to include 'modal'
      end
    end
  end

  describe '#image_large_url' do
    let(:element) { create(:site_element, :traffic, :with_active_image) }

    let(:image_large_url) { element.image_large_url }

    context 'when the element has no image' do
      let(:element) { create(:site_element, :traffic) }

      it { expect(image_large_url).to be_nil }
    end

    context 'when the element has an image' do
      it 'returns the "large" style URL' do
        expect(image_large_url).to include 'large'
      end
    end
  end

  describe 'fonts' do
    before do
      element.update(
        headline: '<span style="font-family: HeadlineFont, sans-serif;">text</span>',
        caption: '<span style="font-family: CaptionFont, sans-serif;">text</span>',
        link_text: '<span style="font-family: LinkTextFont, sans-serif;">text</span>'
      )
    end

    it 'does not include system fonts' do
      %w[Arial Georgia Impact Tahoma Times\ New\ Roman Verdana].each do |font|
        element.headline = %(<span style="font-family: #{ font }, sans-serif;">text</span>)
        expect(element.fonts).not_to include font
      end
    end

    it 'grabs font from headline, caption and link_text' do
      expect(element.fonts).to match %w[HeadlineFont CaptionFont LinkTextFont]
    end

    context 'when no custom fonts are used' do
      before do
        element.update(
          headline: 'Headline',
          caption: '',
          link_text: nil
        )
      end

      it 'returns empty array' do
        expect(element.fonts).to eql []
      end
    end
  end

  describe 'sanitized attributes' do
    let(:text) { '<p><span style="color: rgb(1,1,1);font-family: \'Times New Roman\', Times, serif;"></span></p>' }

    describe '#link_text=' do
      it 'does not remove style' do
        element.link_text = text
        expect(element.link_text).to eql text
      end
    end

    describe '#headline=' do
      it 'does not remove style' do
        element.headline = text
        expect(element.headline).to eql text
      end
    end

    describe '#caption=' do
      it 'does not remove style' do
        element.caption = text
        expect(element.caption).to eql text
      end
    end

    describe '#content=' do
      it 'does not remove style' do
        element.content = text
        expect(element.content).to eql text
      end
    end
  end
end
