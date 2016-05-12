require 'spec_helper'

describe UserStateCloner, '#save' do
  let(:json) { File.read("#{Rails.root}/spec/fixtures/user_state.json") }

  it 'creates the user' do
    cloner = UserStateCloner.new(json)

    expect {
      cloner.save
    }.to change{User.exists?(321624)}.from(false).to(true)
  end

  it 'resets the user password' do
    cloner = UserStateCloner.new(json)
    cloner.save

    user = User.find(321624)

    expect(user.valid_password?('password')).to be_true
  end

  it 'creates the sites' do
    cloner = UserStateCloner.new(json)

    expect {
      cloner.save
    }.to change{Site.exists?(286334)}.from(false).to(true)
  end

  it 'creates the site memberships' do
    UserStateCloner.new(json).save

    user = User.find(321624)
    site = Site.find(286334)

    expect(user.sites).to include(site)
  end

  it 'creates the rules' do
    expect {
      UserStateCloner.new(json).save
    }.to change{Rule.exists?(320510)}.from(false).to(true)
  end

  it 'creates the site elements' do
    UserStateCloner.new(json).save

    expect{SiteElement.exists?(253168)}.to be_true
    expect{SiteElement.exists?(259251)}.to be_true
  end

  it 'creates the payment methods' do
    UserStateCloner.new(json).save

    expect{PaymentMethod.exists?(1)}.to be_true
  end
end
