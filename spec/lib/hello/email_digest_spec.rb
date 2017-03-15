require 'spec_helper'

describe Hello::EmailDigest do
  let(:site) { create(:site, :with_user, elements: [:email]) }

  describe 'mailer_for_site' do
    it "should use the 'not installed' mailer if script not installed and has site elements" do
      site.script_installed_at = nil
      site.stub(has_script_installed?: false)
      DigestMailer.should_receive(:not_installed).and_return(nil)
      Hello::EmailDigest.mailer_for_site(site, site.users.first)
    end

    it 'should return nil if script not installed and has no site elements created in the last 10 days' do
      site.stub(has_script_installed?: false)
      site.site_elements.each { |x| x.update_column(:created_at, 11.days.ago) }
      Hello::EmailDigest.mailer_for_site(site, site.users.first).should be_nil
    end

    it 'should return nil if there no site elements' do
      site.stub(has_script_installed?: true)
      site.site_elements.each(&:destroy)
      Hello::EmailDigest.mailer_for_site(site, site.users.first).should be_nil
    end

    it 'should return weekly digest mailer for sites that have installed the script' do
      site.stub(has_script_installed?: true)
      DigestMailer.should_receive(:weekly_digest).and_return(nil)
      Hello::EmailDigest.mailer_for_site(site, site.users.first)
    end

    it 'should attempt to send digest email to admins and owners' do
      create(:site_membership, :admin, site: site)
      site.stub(has_script_installed?: true)

      mail = Mail.new
      mail.html_part = Mail::Part.new
      allow(DigestMailer).to receive(:weekly_digest).and_return(mail)
      expect(DigestMailer).to receive(:weekly_digest).twice

      Hello::EmailDigest.send(site)
    end
  end
end
