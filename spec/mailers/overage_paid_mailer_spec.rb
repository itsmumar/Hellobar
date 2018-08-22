require 'rails_helper'

RSpec.describe OveragePaidMailer, type: :mailer do
  describe '.send_overage_paid_email' do
    let(:site) { create :site, :pro, :with_user }
    let(:user) { site.users.first }
    let(:number_of_views) { site.visit_warning_one }
    let(:limit) { site.views_limit }

    subject { OveragePaidMailer.overage_email(site, number_of_views, limit) }

    it 'set to be delivered to user\'s email' do
      expect(subject).to deliver_to(user.email)
    end

    it 'has correct subject' do
      expect(subject).to have_subject('You have exceeded your Hello Bar monthly view limit!')
    end

    it 'is sent from hello bar contact email' do
      expect(subject).to deliver_from('Hello Bar <contact@hellobar.com>')
    end

    it 'includes site\'s URL' do
      expect(subject).to have_body_text(site.url)
    end
  end
end
