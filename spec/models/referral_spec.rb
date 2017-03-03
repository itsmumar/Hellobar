require 'spec_helper'

describe Referral do
  fixtures :all
  before do
    @user = users(:joey)
    @referral = @user.sent_referrals.build
  end

  it 'has no body set by default' do
    @referral.body.should be_nil
  end

  it 'has a standard body that can be set explicitly' do
    @referral.set_standard_body

    expect(@referral.body).to include(@user.name)
  end

  it 'has no site by default' do
    @referral.site.should be_nil
  end

  it 'has a site if the referral sender only has one site' do
    @referral.sender = users(:pro)
    @referral.set_site_if_only_one
    @referral.site.should_not be_nil
  end

  it 'is invalid if the email belongs to an existing user' do
    @referral.email = users(:wootie).email
    @referral.state = 'sent'
    @referral.should_not be_valid
  end

  it 'has a URL once it gets saved and has a token' do
    expect(@referral.url).to be_empty
    @referral.email = 'referral@hellobar.com'
    @referral.state = 'sent'
    @referral.save!
    expect(@referral.url).not_to be_empty
    expect(@referral.url).to match(@referral.referral_token.token)
  end

  it 'has a formatted expiration date string' do
    @referral.stub(created_at: Date.new(2016,1,15).to_time)
    expect(@referral.expiration_date_string).to eq('January 20th')
  end

  it 'is accepted if the state is not sent' do
    @referral.state = 'signed_up'

    expect(@referral.accepted?).to be_true
  end

  it 'is not accepted if the state is sent' do
    @referral.state = 'sent'

    expect(@referral.accepted?).to be_false
  end

  describe 'to be followed up' do
    before :each do
      @referral.email = 'referral@hellobar.com'
      @referral.state = 'sent'
      @referral.save!
    end

    it 'does not include referrals older than the interval' do
      @referral.created_at -= (Referral::FOLLOWUP_INTERVAL + 1.day)
      @referral.save!

      expect(Referral.to_be_followed_up.all).not_to include(@referral)
    end

    it 'does not include referrals more recent than the interval' do
      @referral.created_at -= (Referral::FOLLOWUP_INTERVAL - 2.days)
      @referral.save!

      expect(Referral.to_be_followed_up.all).not_to include(@referral)
    end

    it 'does not include referrals in the interval if they are signed up' do
      @referral.created_at -= (Referral::FOLLOWUP_INTERVAL - 1.hour)
      @referral.state = 'signed_up'
      @referral.save!

      expect(Referral.to_be_followed_up.all).not_to include(@referral)
    end

    it 'does not include referrals in the interval if they have installed' do
      @referral.created_at -= (Referral::FOLLOWUP_INTERVAL - 1.hour)
      @referral.state = 'installed'
      @referral.save!

      expect(Referral.to_be_followed_up.all).not_to include(@referral)
    end

    it 'does not include referrals in the interval if they have installed' do
      @referral.created_at -= (Referral::FOLLOWUP_INTERVAL - 1.hour)
      @referral.save!

      expect(Referral.to_be_followed_up.all).to include(@referral)
    end
  end

  describe 'redeemable_for_site' do
    before :each do
      @referral.sender = @user
      @referral.email = 'referral@hellobar.com'
      @referral.state = 'installed'
    end

    it 'shows up as the only available one for the site' do
      ownership = create(:site_ownership)
      @referral.recipient = ownership.user
      @referral.save!

      expect(Referral.redeemable_for_site(ownership.site).count).to eq(1)
    end

    it 'shows up as one of many available one for the site' do
      ownership = create(:site_ownership)
      @referral.available_to_sender = true
      @referral.site = ownership.site
      second = @referral.dup
      second.email = 'second-referral@hellobar.com'
      @referral.save!
      second.save!

      expect(Referral.redeemable_for_site(ownership.site).count).to eq(2)
    end

    it 'does not show up if there is no owner' do
      ownership = create(:site_ownership)
      ownership.site.owners.delete_all
      @referral.recipient = ownership.user
      @referral.save!
      expect(Referral.redeemable_for_site(ownership.site).count).to eq(0)
    end
  end

  describe 'redeemable? and redeemed?' do
    before :each do
      @referral.sender = @user
      @referral.email = 'referral@hellobar.com'
    end

    it 'is redeemable when installed and available' do
      @referral.state = 'installed'
      @referral.available_to_sender = true
      @referral.redeemed_by_sender_at = nil

      expect(@referral.redeemable_by_sender?).to be_true
      expect(@referral.redeemed_by_sender?).to be_false
    end

    it 'is redeemed when installed and already used' do
      @referral.state = 'installed'
      @referral.available_to_sender = false
      @referral.redeemed_by_sender_at = Time.now

      expect(@referral.redeemable_by_sender?).to be_false
      expect(@referral.redeemed_by_sender?).to be_true
    end
  end
end
