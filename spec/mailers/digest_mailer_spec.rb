require "spec_helper"

describe DigestMailer do
  fixtures :all

  describe 'weekly_digest' do
    let(:site) { sites(:zombo) }
    let(:user) { site.owner }
    let(:mail) { DigestMailer.weekly_digest(site) }

    it 'should work correctly when there are no site elements' do
      site.site_elements.each(&:destroy)
      Hello::DataAPI.stub(lifetime_totals: {})
      expect{mail.body}.to_not raise_error
    end

    it 'should display n/a if history is too short' do
      data = {}.tap do |d|
        site.site_elements.each { |se| d[se.id.to_s] = Hello::DataAPI::Performance.new([[0, 1]])}
      end
      Hello::DataAPI.stub(:lifetime_totals).and_return(data)
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new([[0, 1]])})
      expect(mail.body.encoded).to match("n/a")
    end
  end
end
