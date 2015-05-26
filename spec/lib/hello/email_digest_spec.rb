require "spec_helper"

describe Hello::EmailDigest do
  fixtures :all

  describe "mailer_for_site" do
    it "should use the 'not installed' mailer if script not installed and has site elements" do
      site = sites(:zombo)
      site.script_installed_at = nil
      site.stub(has_script_installed?: false)
      DigestMailer.should_receive(:not_installed).and_return(nil)
      Hello::EmailDigest.mailer_for_site(site)
    end

    it "should return nil if script not installed and has no site elements created in the last 10 days" do
      site = sites(:zombo)
      site.stub(has_script_installed?: false)
      site.site_elements.each { |x| x.update_column(:created_at, 11.day.ago) }
      Hello::EmailDigest.mailer_for_site(site).should be_nil
    end

    it "should return nil if there no site elements" do
      site = sites(:zombo)
      site.stub(has_script_installed?: true)
      site.site_elements.each(&:destroy)
      Hello::EmailDigest.mailer_for_site(site).should be_nil
    end

    it "should return weekly digest mailer for sites that have installed the script" do
      site = sites(:zombo)
      site.stub(has_script_installed?: true)
      DigestMailer.should_receive(:weekly_digest).and_return(nil)
      Hello::EmailDigest.mailer_for_site(site)
    end
  end

end
