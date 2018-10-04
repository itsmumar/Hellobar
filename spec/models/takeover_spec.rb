describe Takeover do
  let(:element) { create(:takeover, :email) }
  let(:contact_list) { create(:contact_list) }
  let(:site) { element.site }
  let(:supposed_thank_you_text) { 'do not show this message' }

  context 'when it is a free account' do
    before do
      allow(element.site).to receive(:free?) { true }
    end

    context 'and after_email_submit_action is :show_default_message' do
      before do
        allow(element).to receive(:after_email_submit_action) { :show_default_message }
      end

      it 'should return the default message regardless of the thank you text' do
        element.thank_you_text = supposed_thank_you_text
        expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_FREE_EMAIL_POPUP_THANK_YOU_TEXT)
      end
    end

    context 'when after_email_submit_action is not :show_default_message' do
      before do
        allow(element).to receive(:after_email_submit_action) { :something }
      end

      it 'should return the default message if thank you text not set' do
        element.thank_you_text = ''
        expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_FREE_EMAIL_POPUP_THANK_YOU_TEXT)
      end

      it 'should still return the default thank you text' do
        element.thank_you_text = supposed_thank_you_text
        expect(element.display_thank_you_text).to eq(SiteElement::DEFAULT_FREE_EMAIL_POPUP_THANK_YOU_TEXT)
      end
    end
  end
end
