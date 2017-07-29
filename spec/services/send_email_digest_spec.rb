describe SendEmailDigest, :freeze do
  let(:service) { described_class.new(site) }
  let(:site) { create(:site, :with_user, elements: [:email]) }
  let(:site_element) { site.site_elements.first }
  let(:recipient) { site.owners.first }

  before { allow(Settings).to receive(:fake_data_api).and_return(true) }

  describe '#call' do
    context 'when site has elements' do
      context 'and script not installed' do
        before { site.script_installed_at = nil }
        before { allow(site).to receive(:script_installed?).and_return(false) }

        def update_elements(attrs)
          site.site_elements.each { |element| element.update_columns(attrs) }
        end

        context 'and elements are created less than 10 days ago' do
          before { update_elements(created_at: 9.days.ago) }

          it 'sends the "not installed" mail' do
            service.call
            expect(last_email_sent).to deliver_to(recipient.email)
            expect(last_email_sent).to have_subject('One final step and your Hello bar is live')
            expect(last_email_sent).to deliver_from('Hello Bar <contact@hellobar.com>')
          end
        end

        context 'and elements are created more than 10 days ago' do
          before { update_elements(created_at: 11.days.ago) }

          it 'does not send email' do
            expect { service.call }.not_to change { all_emails.count }
          end
        end
      end

      context 'and script installed' do
        let(:statistics) do
          create(:site_statistics, :with_views,
            first_date: EmailDigestHelper.last_week.first,
            site_element_id: site_element.id)
        end

        before do
          allow_any_instance_of(FetchSiteStatistics)
            .to receive(:call).and_return(statistics)
        end

        before { allow(site).to receive(:script_installed?).and_return(true) }

        let(:subject) do
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

        it 'sends the "weekly digest" mail' do
          service.call
          expect(last_email_sent).to deliver_to(recipient.email)
          expect(last_email_sent).to have_subject(subject)
          expect(last_email_sent).to deliver_from('Hello Bar <contact@hellobar.com>')
        end
      end
    end

    context 'when site has no elements' do
      let(:site) { create(:site, :with_user) }

      before { allow(site).to receive(:script_installed?).and_return(false) }

      it 'does not send email' do
        expect { service.call }.not_to change { all_emails.count }
      end
    end
  end
end
