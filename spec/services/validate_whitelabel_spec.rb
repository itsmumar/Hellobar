describe ValidateWhitelabel do
  describe '#call' do
    let(:whitelabel) { create :whitelabel }

    let(:api_url) { 'https://api.sendgrid.com/v3' }
    let(:url) { "#{ api_url }/whitelabel/domains/#{ whitelabel.domain_identifier }/validate" }

    let(:error_message) { 'Domain whitelabel does not exist.' }
    let(:erroneous_api_response) { Hash[errors: [{ message: error_message }]] }

    let(:validation_failed_results) do
      {
        mail_cname: {
          valid: false,
          reason: 'Expected CNAME to match'
        },
        dkim1: {
          valid: false,
          reason: 'Expected CNAME to match'
        },
        dkim2: {
          valid: false,
          reason: 'Expected CNAME to match'
        }
      }
    end

    let(:validation_failed_api_response) do
      Hash[valid: false, validation_results: validation_failed_results]
    end

    let(:validation_successful_results) do
      {
        mail_cname: {
          valid: true
        },
        dkim1: {
          valid: true
        },
        dkim2: {
          valid: true
        }
      }
    end

    let(:validation_succeeded_api_response) do
      Hash[valid: true, validation_results: validation_successful_results]
    end

    it 'returns a general error if SendGrid returns an error' do
      stub_request(:post, url)
        .to_return status: 400, body: erroneous_api_response.to_json

      expect {
        ValidateWhitelabel.new(whitelabel: whitelabel).call
      }.to raise_exception ActiveRecord::RecordInvalid, /Validation failed/
    end

    context 'when validation fails' do
      it 'marks whitelabel as invalid and attaches dns records with error response' do
        stub_request(:post, url)
          .to_return status: 200, body: validation_failed_api_response.to_json

        expect {
          ValidateWhitelabel.new(whitelabel: whitelabel).call
        }.to raise_exception ActiveRecord::RecordInvalid, /Validation failed/

        expect(whitelabel.status).to eql Whitelabel::INVALID

        expect(whitelabel.errors.messages).to be_present
        expect(whitelabel.errors.messages[:base]).to include 'Validation failed'
        expect(whitelabel.errors.messages[:domain]).to include 'Expected CNAME to match'
      end
    end

    context 'when validation succeeds' do
      before do
        stub_request(:post, url)
          .to_return status: 200, body: validation_succeeded_api_response.to_json
      end

      it 'marks whitelabel as valid' do
        expect {
          ValidateWhitelabel.new(whitelabel: whitelabel).call
        }.not_to raise_exception

        expect(whitelabel).to be_valid
      end

      it 'returns whitelabel' do
        result = ValidateWhitelabel.new(whitelabel: whitelabel).call

        expect(result).to eql whitelabel
      end
    end
  end
end
