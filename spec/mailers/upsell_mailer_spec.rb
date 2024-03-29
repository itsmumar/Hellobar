require 'rails_helper'

RSpec.describe UpsellMailer, type: :mailer do
  describe '.upsell_email' do
    let(:site) { create :site, :pro, :with_user }
    let(:user) { site.users.first }
    let(:number_of_views) { site.visit_warning_one }
    let(:limit) { site.views_limit }

    subject { UpsellMailer.upsell_email(site, number_of_views, limit) }

    it 'set to be delivered to user\'s email' do
      expect(subject).to deliver_to(user.email)
    end

    it 'has correct subject' do
      expect(subject).to have_subject('You could be saving money by upgrading your Hello Bar Subscription')
    end

    it 'is sent from hello bar contact email' do
      expect(subject).to deliver_from('Hello Bar <contact@hellobar.com>')
    end

    it 'includes site\'s URL' do
      expect(subject).to have_body_text(site.url)
    end

    let(:mail) { UpsellMailer.elite_upsell_email(site, number_of_views, limit) }

    it 'has correct subject' do
      expect(mail).to have_subject('Heads up! An Elite customer is paying a lot in overage fees')
    end

    it 'set to be delivered to admin email' do
      expect(mail).to deliver_to('karen@hellobar.com', 'lindsey@hellobar.com', 'mike@hellobar.com', 'ryan@hellobar.com', 'seth@hellobar.com')
    end
  end

  describe '.auto_upgrade_email' do
    let(:site) { create :site, :pro, :with_user }
    let(:user) { site.users.first }
    let(:number_of_views) { 400_001 }
    let(:limit) { site.views_limit }

    subject { UpsellMailer.auto_upgrade_email(site, number_of_views, limit) }

    it 'set to be delivered to user\'s email' do
      expect(subject).to deliver_to(user.email)
    end

    it 'has correct subject' do
      expect(subject).to have_subject('We’re Saving You Money: Changes to Your Hello Bar Account')
    end

    it 'is sent from hello bar contact email' do
      expect(subject).to deliver_from('Hello Bar <contact@hellobar.com>')
    end

    it 'includes site\'s URL' do
      expect(subject).to have_body_text(site.url)
    end
  end
end
