describe SiteMailer do
  let!(:site) { create :site, :with_user, elements: [:email] }
  let(:site_element) { site.site_elements.first }
  let(:user) { site.owners.first }

  describe '.weekly_digest' do
    let(:mail) { SiteMailer.weekly_digest(site, user) }
    let(:views) { Array.new(6) { 1 } }
    let(:conversions) { Array.new(6) { 1 } }

    let(:statistics) do
      create :site_statistics,
        site_element_id: site_element.id,
        views: views,
        conversions: conversions,
        first_date: EmailDigestHelper.date_of_previous('Sunday') - 6.days
    end

    let(:email_subject) do
      "Hello Bar Weekly Digest for #{ site.url } - #{ week_for_subject }"
    end

    def week_for_subject
      start_date = EmailDigestHelper.last_week.first
      end_date = EmailDigestHelper.last_week.last
      end_date_format = start_date.month == end_date.month ? '%-d, %Y' : '%b %-d, %Y'
      from = start_date.strftime('%b %-d')
      till = end_date.strftime(end_date_format)
      "#{ from } - #{ till }"
    end

    before do
      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(site, site_element_ids: [site_element.id])
        .and_return(statistics)

      expect(FetchSiteStatistics)
        .to receive_service_call.with(site, days_limit: 90).and_return(statistics)
    end

    it 'renders headers' do
      expect(mail).to deliver_to(user.email)
      expect(mail).to have_subject(email_subject)
      expect(mail).to deliver_from('Hello Bar <contact@hellobar.com>')
    end

    it 'renders body' do
      expect(mail.body.encoded).to match(/Your Performance Last Week/)
    end

    context 'when history is too short' do
      it 'displays n/a', :freeze do
        # Travel to one day past the delivery date to ensure it's picking up the
        # mocked data regardless of when the test runs
        Timecop.travel(EmailDigestHelper.date_of_previous('Sunday') + 1.day) do
          expect(mail.body.encoded).to match('n/a')
        end
      end
    end
  end

  describe '.site_script_not_installed' do
    let(:mail) { SiteMailer.site_script_not_installed(site, user) }

    it 'renders headers' do
      expect(mail).to deliver_to(user.email)
      expect(mail).to have_subject('One final step and your Hello bar is live')
      expect(mail).to deliver_from('Hello Bar <contact@hellobar.com>')
    end

    it 'renders body' do
      expect(mail.body.encoded).to match 'Start using Hello Bar!'
      expect(mail.body.encoded).to match 'collecting emails'
    end
  end
end
