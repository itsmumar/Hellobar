require 'spec_helper'

describe UserStateCloner, '#save' do
  let(:json) { File.read("#{Rails.root}/spec/fixtures/user_state.json") }

  before(:each) do
    allow_any_instance_of(User).to receive(:add_to_infusionsoft)
  end

  it 'creates the user' do
    cloner = UserStateCloner.new(json)

    expect { cloner.save }.to change(User, :count).by(1)
  end

  it 'resets the user password' do
    cloner = UserStateCloner.new(json)
    cloner.save

    user = cloner.user

    expect(user.valid_password?('password')).to be_true
  end

  it 'creates the sites' do
    cloner = UserStateCloner.new(json)
    site = cloner.sites.first

    expect { cloner.save }.to change { Site.exists?(site.id) }.from(false).to(true)
  end

  it 'creates the site memberships' do
    cloner = UserStateCloner.new(json)
    user = cloner.user
    site = cloner.sites.first

    cloner.save

    expect(user.sites).to include(site)
  end

  it 'creates the rules' do
    expect { UserStateCloner.new(json).save }.to change(Rule, :count).by(7)
  end

  it 'creates the site elements' do
    expect { UserStateCloner.new(json).save }.to change(SiteElement, :count).by(11)
  end

  it 'creates the payment methods' do
    expect { UserStateCloner.new(json).save }.to change(PaymentMethod, :count).by(1)
  end

  it 'upgrades the site to pro' do
    expect { UserStateCloner.new(json).save }.to change(Subscription::Pro, :count).by(2)
  end

  it 'creates conditions properly' do
    expect { UserStateCloner.new(json).save }.to change(Condition, :count)
  end
end
