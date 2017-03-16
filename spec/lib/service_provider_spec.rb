require 'spec_helper'

describe 'service providers' do
  let(:identity) { double(:identity, credentials: {}).as_null_object }

  describe ServiceProviders::AWeber do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'AWeber' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :aweber }
    end
  end

  describe ServiceProviders::CampaignMonitor do
    let(:client) { double(:client) }
    before { expect_any_instance_of(described_class).to receive(:initialize_client).and_return(client) }
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'Campaign Monitor' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :createsend }
    end
  end

  describe ServiceProviders::ConstantContact do
    before do
      ConstantContact::Api.stub_chain(:new) { double(:client) }
    end
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'Constant Contact' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :constantcontact }
    end
  end

  describe ServiceProviders::GetResponse do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'GetResponse' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :get_response }
    end
  end

  describe ServiceProviders::IContact do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'iContact' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :icontact }
    end
  end

  describe ServiceProviders::MadMimiForm do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'MadMimi' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :mad_mimi_form }
    end
  end

  describe ServiceProviders::MailChimp do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'MailChimp' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :mailchimp }
    end
  end

  describe ServiceProviders::MyEmma do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'MyEmma' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :my_emma }
    end
  end

  describe ServiceProviders::VerticalResponse do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      it { expect(subject.name).to eql 'VerticalResponse' }
    end

    describe '#key' do
      it { expect(subject.key).to eql :vertical_response }
    end
  end
end
