describe ContactFormMailer do
  shared_examples 'subject with message preview' do
    context 'when message has leading or trailing line ending' do
      let(:message) { "\r\nmessage \r\n one more line\r\n" }

      let(:expected_subject) { "Contact Form: message one more line" }

      it 'cuts it off when build subject' do
        expect(mail.subject).to eq expected_subject
      end
    end

    context 'when message is very long' do
      let(:message) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus blandit leo in velit.' }

      let(:expected_subject) { "Contact Form: Lorem ipsum dolor sit amet, consectetur adipiscing" }

      it 'includes only 50 first chars to subject' do
        expect(mail.subject).to eq expected_subject
      end
    end
  end

  describe '#generic_message' do
    let(:message) { 'message' }
    let(:user) { create :user }
    let(:site) { create :site }
    let(:mail) { ContactFormMailer.generic_message message, user, site }

    let(:subject) { "Contact Form: #{ message }" }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq ['support@hellobar.com']
      expect(mail.from).to eq [user.email]
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('message')
      expect(mail.body.encoded).to match(site.url)
    end

    include_examples 'subject with message preview'
  end

  describe '#guest_message' do
    let(:message) { 'message' }
    let(:email) { 'email@example.com' }
    let(:name) { 'Name' }
    let(:mail) { ContactFormMailer.guest_message message: message, name: name, email: email }

    let(:subject) { "Contact Form: #{ message }" }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq ['support@hellobar.com']
      expect(mail.from).to eq [email]
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('message')
    end

    include_examples 'subject with message preview'
  end

  describe '#forgot_email' do
    let(:params) do
      {
        site_url: 'http://example.com',
        first_name: 'FirstName',
        last_name: 'LastName',
        email: 'email@example.com'
      }
    end

    let(:mail) { ContactFormMailer.forgot_email params }

    let(:subject) do
      "Customer Support: Forgot Email #{ params[:first_name] } #{ params[:last_name] } #{ params[:email] }"
    end

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq ['support@hellobar.com']
      expect(mail.from).to eq [params[:email]]
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match(params[:site_url])
      expect(mail.body.encoded).to match(params[:email])
      expect(mail.body.encoded).to match(params[:first_name])
      expect(mail.body.encoded).to match(params[:last_name])
    end
  end

  describe '#contact_developer' do
    let(:developer_email) { 'developer@example.com' }
    let(:site) { create :site }
    let(:user) { create :user }

    let(:mail) { ContactFormMailer.contact_developer developer_email, site, user }

    let(:subject) do
      "Please install Hello Bar on #{ site.normalized_url }"
    end

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [developer_email]
      expect(mail.from).to eq ['contact@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match(site.normalized_url)
      expect(mail.body.encoded).to match(%(src="#{ site.script_url }"))
      expect(mail.body.encoded).to match(user.email)
    end
  end
end
