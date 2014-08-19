require 'spec_helper'

describe "service providers" do
  let(:identity) { double(:identity, credentials: {}).as_null_object }

  describe ServiceProviders::AWeber do
    subject { described_class.new(identity: identity) }
    its(:name) { should == "AWeber" }
  end

  describe ServiceProviders::CampaignMonitor do
    let(:client) { double(:client) }
    before { expect_any_instance_of(described_class).to receive(:initialize_client).and_return(client) }
    subject { described_class.new(identity: identity) }
    its(:name) { should == "Campaign Monitor" }
  end

  describe ServiceProviders::ConstantContact do
    before do
      ConstantContact::Api.stub_chain(:new) { double(:client) }
    end
    subject { described_class.new(identity: identity) }
    its(:name) { should == "Constant Contact" }
  end

  describe ServiceProviders::GetResponse do
    subject { described_class.new(identity: identity) }
    its(:name) { should == "GetResponse" }
  end

  describe ServiceProviders::IContact do
    subject { described_class.new(identity: identity) }
    its(:name) { should == "iContact" }
  end

  describe ServiceProviders::MadMimi do
    subject { described_class.new(identity: identity) }
    its(:name) { should == "Mad Mimi" }
  end

  describe ServiceProviders::MailChimp do
    subject { described_class.new(identity: identity) }
    its(:name) { should == "MailChimp" }
  end

  describe ServiceProviders::MyEmma do
    subject { described_class.new(identity: identity) }
    its(:name) { should == "MyEmma" }
  end

  describe ServiceProviders::VerticalResponse do
    subject { described_class.new(identity: identity) }
    its(:name) { should == "VerticalResponse" }
  end
end
