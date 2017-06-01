describe ExtractEmbedForm, :no_vcr do
  let(:service) { described_class.new(embed_code) }

  context 'when embed code is a form' do
    let(:embed_code) { embed_code_file_for 'mad_mimi_form' }
    let(:form) { service.call }

    it 'has form' do
      expect(form.form).to be_a Nokogiri::XML::Element
      expect(form.form.name).to eql 'form'
    end

    it 'has inputs' do
      expect(form.inputs).to match('signup[email]' => nil, nil => 'Subscribe')
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://madmimi.com/signups/subscribe/103242'
    end
  end

  context 'when embed code is a url' do
    let(:embed_code) { 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a' }
    let(:form) { service.call }

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
        'source' => nil,
        'invalid_signup' => '',
        'email' => nil,
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql embed_code
    end
  end

  context 'when embed is a script (icontact)' do
    let(:embed_code) { embed_code_file_for 'icontact' }
    let(:form) { service.call }

    before do
      stub_request(
        :get, 'http://app.icontact.com/icp/loadsignup.php/form.js?c=1450422&f=564&l=7290'
      ).and_return(webmock_fixture('icontact_form.txt'))
    end

    it 'has form' do
      expect(form.form).to be_a Nokogiri::XML::Element
      expect(form.form.name).to eql 'form'
    end

    it 'has inputs' do
      expect(form.inputs).to match(
        'redirect' => 'http://www.hellobar.com/emailsignup/icontact/success',
        'errorredirect' => 'http://www.hellobar.com/emailsignup/icontact/error',
        'fields_email' => nil,
        'fields_fname' => nil,
        'fields_lname' => nil,
        'listid' => '10108',
        'specialid:10108' => 'O2D3',
        'clientid' => '1450422',
        'formid' => '564',
        'reallistid' => '1',
        'doubleopt' => '0',
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'http://app.icontact.com/icp/signup.php'
    end
  end

  context 'when embed code contains "#load_check a" element (my emma js)' do
    let(:embed_code) { embed_code_file_for 'my_emma_js' }
    let(:form) { service.call }

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
        'source' => nil,
        'prev_member_email' => '',
        'invalid_signup' => '',
        'email' => nil,
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    end
  end

  context 'when embed code is a link element (my emma pop up)' do
    let(:embed_code) { embed_code_file_for 'my_emma_popup' }
    let(:form) { service.call }

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
        'source' => nil,
        'prev_member_email' => '',
        'invalid_signup' => '',
        'email' => nil,
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    end
  end

  context 'when embed code is an iframe' do
    let(:embed_code) { embed_code_file_for 'my_emma_iframe' }
    let(:form) { service.call }

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
        'source' => nil,
        'prev_member_email' =>  '',
        'invalid_signup' =>  '',
        'email' => nil,
        'Submit' => 'Submit'
      )
    end

    it 'has action_url' do
      expect(form.action_url).to eql 'https://app.e2ma.net/app2/audience/signup/1759483/1735963/?v=a'
    end
  end
end
