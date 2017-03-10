require 'spec_helper'

describe 'service providers' do
  let(:identity) { double(:identity, credentials: {}).as_null_object }

  describe ServiceProviders::AWeber do
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'AWeber' }
    its(:key) { should == :aweber }
  end

  describe ServiceProviders::CampaignMonitor do
    let(:client) { double(:client) }
    before { expect_any_instance_of(described_class).to receive(:initialize_client).and_return(client) }
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'Campaign Monitor' }
    its(:key) { should == :createsend }
  end

  describe ServiceProviders::ConstantContact do
    before do
      ConstantContact::Api.stub_chain(:new) { double(:client) }
    end
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'Constant Contact' }
    its(:key) { should == :constantcontact }
  end

  describe ServiceProviders::GetResponse do
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'GetResponse' }
    its(:key) { should == :get_response }
  end

  describe ServiceProviders::IContact do
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'iContact' }
    its(:key) { should == :icontact }
  end

  describe ServiceProviders::MadMimiForm do
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'MadMimi' }
    its(:key) { should == :mad_mimi_form }
  end

  describe ServiceProviders::MailChimp do
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'MailChimp' }
    its(:key) { should == :mailchimp }
  end

  describe ServiceProviders::MyEmma do
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'MyEmma' }
    its(:key) { should == :my_emma }
  end

  describe ServiceProviders::VerticalResponse do
    subject { described_class.new(identity: identity) }
    its(:name) { should == 'VerticalResponse' }
    its(:key) { should == :vertical_response }
  end
end
