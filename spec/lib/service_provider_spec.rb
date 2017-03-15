require 'spec_helper'

describe 'service providers' do
  let(:identity) { double(:identity, credentials: {}).as_null_object }

  describe ServiceProviders::AWeber do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'AWeber' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :aweber }
    end
  end

  describe ServiceProviders::CampaignMonitor do
    let(:client) { double(:client) }
    before { expect_any_instance_of(described_class).to receive(:initialize_client).and_return(client) }
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'Campaign Monitor' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :createsend }
    end
  end

  describe ServiceProviders::ConstantContact do
    before do
      ConstantContact::Api.stub_chain(:new) { double(:client) }
    end
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'Constant Contact' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :constantcontact }
    end
  end

  describe ServiceProviders::GetResponse do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'GetResponse' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :get_response }
    end
  end

  describe ServiceProviders::IContact do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'iContact' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :icontact }
    end
  end

  describe ServiceProviders::MadMimiForm do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'MadMimi' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :mad_mimi_form }
    end
  end

  describe ServiceProviders::MailChimp do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'MailChimp' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :mailchimp }
    end
  end

  describe ServiceProviders::MyEmma do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'MyEmma' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :my_emma }
    end
  end

  describe ServiceProviders::VerticalResponse do
    subject { described_class.new(identity: identity) }

    describe '#name' do
      subject { super().name }
      it { should == 'VerticalResponse' }
    end

    describe '#key' do
      subject { super().key }
      it { should == :vertical_response }
    end
  end
end
