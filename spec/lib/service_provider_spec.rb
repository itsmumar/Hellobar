require 'spec_helper'

describe 'service providers' do
  let(:identity) { double(:identity, credentials: {}).as_null_object }
  subject(:service_provider) { described_class.new(identity: identity) }

  describe ServiceProviders::AWeber do
    describe '#name' do
      specify { expect(service_provider.name).to eql 'AWeber' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :aweber }
    end
  end

  describe ServiceProviders::CampaignMonitor do
    let(:client) { double(:client) }
    before { expect_any_instance_of(described_class).to receive(:initialize_client).and_return(client) }

    describe '#name' do
      specify { expect(service_provider.name).to eql 'Campaign Monitor' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :createsend }
    end
  end

  describe ServiceProviders::ConstantContact do
    before do
      allow(ConstantContact::Api).to receive(:new).and_return(double(:client))
    end

    describe '#name' do
      specify { expect(service_provider.name).to eql 'Constant Contact' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :constantcontact }
    end
  end

  describe ServiceProviders::GetResponse do
    describe '#name' do
      specify { expect(service_provider.name).to eql 'GetResponse' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :get_response }
    end
  end

  describe ServiceProviders::IContact do
    describe '#name' do
      specify { expect(service_provider.name).to eql 'iContact' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :icontact }
    end
  end

  describe ServiceProviders::MadMimiForm do
    describe '#name' do
      specify { expect(service_provider.name).to eql 'MadMimi' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :mad_mimi_form }
    end
  end

  describe ServiceProviders::MailChimp do
    describe '#name' do
      specify { expect(service_provider.name).to eql 'MailChimp' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :mailchimp }
    end
  end

  describe ServiceProviders::MyEmma do
    describe '#name' do
      specify { expect(service_provider.name).to eql 'MyEmma' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :my_emma }
    end
  end

  describe ServiceProviders::VerticalResponse do
    describe '#name' do
      specify { expect(service_provider.name).to eql 'VerticalResponse' }
    end

    describe '#key' do
      specify { expect(service_provider.key).to eql :vertical_response }
    end
  end
end
