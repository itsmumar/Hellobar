require 'spec_helper'

describe DigestMailer do
  fixtures :all

  describe 'weekly_digest' do
    let(:site) { sites(:zombo) }
    let(:user) { site.owners.first }
    let(:mail) { DigestMailer.weekly_digest(site, user) }

    it 'should work correctly when there are no site elements' do
      site.site_elements.each(&:destroy)
      site.reload
      Hello::DataAPI.stub(lifetime_totals: {})
      expect{mail.body}.to_not raise_error
    end

    it 'should display n/a if history is too short' do
      # Travel to one day past the delivery date to ensure it's picking up the
      # mocked data regardless of when the test runs
      travel_to(EmailDigestHelper.date_of_previous('Sunday') + 1.day) do
        data = {}.tap do |d|
          site.site_elements.each { |se| d[se.id.to_s] = Hello::DataAPI::Performance.new([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]])}
        end
        Hello::DataAPI.stub(:lifetime_totals).and_return(data)
        Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [2, 2]])})
        expect(mail.body.encoded).to match('n/a')
      end
    end

    it 'should be nil if there were no views in the past week' do
      data = {}.tap do |d|
        site.site_elements.each { |se| d[se.id.to_s] = Hello::DataAPI::Performance.new([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1]])}
      end
      Hello::DataAPI.stub(:lifetime_totals).and_return(data)
      Hello::DataAPI.stub(:lifetime_totals_by_type).and_return({:total=>Hello::DataAPI::Performance.new([[1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1], [1, 1]])})
      expect(mail.class).to eq(ActionMailer::Base::NullMail)
    end
  end
end
