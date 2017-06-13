describe ServiceProvider::Adapters::IContact do
  let(:defined_urls) do
    {
      form: 'http://app.icontact.com/icp/loadsignup.php/form.js?c=1450422&f=564&l=7290',
      subscribe: 'http://app.icontact.com/icp/signup.php'
    }
  end

  let(:identity) { double('identity', provider: 'icontact') }
  include_examples 'service provider'
  let(:contact_list) { create(:contact_list, :icontact) }

  before { allow_request :get, :form }

  describe '#initialize' do
    it 'initializes Faraday::Connection' do
      expect(adapter.client).to be_a Faraday::Connection
    end
  end

  describe '#subscribe' do
    let(:body) do
      {
        'Submit' => 'Submit',
        'clientid' => '1450422',
        'doubleopt' => '0',
        'errorredirect' => 'http://www.hellobar.com/emailsignup/icontact/error',
        'fields_email' => 'example@email.com',
        'fields_fname' => 'FirstName',
        'fields_lname' => 'LastName',
        'formid' => '564',
        'listid' => '10108',
        'reallistid' => '1',
        'redirect' => 'http://www.hellobar.com/emailsignup/icontact/success',
        'specialid:10108' => 'O2D3'
      }
    end
    let!(:subscribe_request) { allow_request :post, :subscribe, body: body }

    it 'sends subscribe request' do
      provider.subscribe(email: email, name: name)
      expect(subscribe_request).to have_been_made
    end
  end
end
