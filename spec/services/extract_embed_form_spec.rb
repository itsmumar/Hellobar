describe ExtractEmbedForm do
  let(:service) { described_class.new(embed_code) }
  let(:form) { service.call }

  context 'when error is raised while remote request' do
    let(:embed_code) { 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a' }

    it 'returns invalid EmbedForm' do
      allow(HTTParty).to receive(:get).and_raise HTTParty::Error
      expect { service.call }.not_to raise_error
    end
  end

  context 'when embed code is a form' do
    let(:embed_code) { build :embed_code, provider: 'mad_mimi_form' }

    it 'has form' do
      expect(form.form).to be_a Nokogiri::XML::Element
      expect(form.form.name).to eql 'form'
    end

    it 'has inputs' do
      expect(form.inputs).to match('signup[email]' => '')
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://madmimi.com/signups/subscribe/103242'
    end
  end

  context 'when embed code is a url' do
    let(:embed_code) { 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a' }

    before do
      stub_request(
        :get, 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
      ).and_return(webmock_fixture('my_emma_form.txt'))
    end

    it 'has form' do
      expect(form.form).to be_a Nokogiri::XML::Element
      expect(form.form.name).to eql 'form'
    end

    it 'has inputs' do
      expect(form.inputs).to match(
        'prev_member_email' => '',
        'source' => '',
        'invalid_signup' => '',
        'email' => '',
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql embed_code
    end
  end

  context 'when embed code contains "#load_check a" element (my emma js)' do
    let(:embed_code) { build :embed_code, provider: 'my_emma_js' }

    before do
      stub_request(
        :get, 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
      ).and_return(webmock_fixture('my_emma_form.txt'))
    end

    it 'has form' do
      expect(form.form).to be_a Nokogiri::XML::Element
      expect(form.form.name).to eql 'form'
    end

    it 'has inputs' do
      expect(form.inputs).to match(
        'source' => '',
        'prev_member_email' => '',
        'invalid_signup' => '',
        'email' => '',
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    end
  end

  context 'when embed code is a link element (my emma pop up)' do
    let(:embed_code) { build :embed_code, provider: 'my_emma_popup' }

    before do
      stub_request(
        :get, 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
      ).and_return(webmock_fixture('my_emma_form.txt'))
    end

    it 'has form' do
      expect(form.form).to be_a Nokogiri::XML::Element
      expect(form.form.name).to eql 'form'
    end

    it 'has inputs' do
      expect(form.inputs).to match(
        'source' => '',
        'prev_member_email' => '',
        'invalid_signup' => '',
        'email' => '',
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    end
  end

  context 'when embed code is an iframe' do
    let(:embed_code) { build :embed_code, provider: 'my_emma_iframe' }

    before do
      stub_request(
        :get, 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
      ).and_return(webmock_fixture('my_emma_form.txt'))
    end

    it 'has form' do
      expect(form.form).to be_a Nokogiri::XML::Element
      expect(form.form.name).to eql 'form'
    end

    it 'has inputs' do
      expect(form.inputs).to match(
        'source' => '',
        'prev_member_email' =>  '',
        'invalid_signup' =>  '',
        'email' => '',
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    end
  end

  context 'when ExtractEmbedForm::Error is raised' do
    let(:embed_code) { build :embed_code, provider: 'my_emma_iframe' }

    it 'returns invalid/empty form' do
      allow(HTTParty).to receive(:get).and_return ''
      expect(form).not_to be_valid
    end
  end
end
