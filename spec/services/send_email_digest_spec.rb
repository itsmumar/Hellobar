describe SendEmailDigest, :freeze do
  let(:service) { described_class.new(site) }
  let(:site) { create(:site, :with_user, elements: [:email]) }
  let(:recipient) { site.owners.first }
  let(:options) do
    hash_including(
      site_url: site.url,
      date: 'May 8 - 14, 2017',
      text: mailer.text_part.body.raw_source,
      content: mailer.html_part.body.raw_source
    )
  end

  before { allow(Settings).to receive(:fake_data_api).and_return(true) }

  describe '#call' do
    context 'when site has elements' do
      context 'and script not installed' do
        before { site.script_installed_at = nil }
        before { allow(site).to receive(:script_installed?).and_return(false) }

        context 'and elements are created less than 10 days ago' do
          let(:mailer) { DigestMailer.not_installed(site, recipient) }

          before { site.site_elements.each { |element| element.update_column(:created_at, 9.days.ago) } }

          it 'sends the "not installed" mail' do
            expect(MailerGateway)
              .to receive(:send_email).with('New Email Digest (Not Installed)', recipient.email, options)
            service.call
          end
        end

        context 'and elements are created more than 10 days ago' do
          before { site.site_elements.each { |element| element.update_column(:created_at, 11.days.ago) } }

          it 'does not send email' do
            expect(DigestMailer).not_to receive(:not_installed)
            expect(DigestMailer).not_to receive(:weekly_digest)
            expect(MailerGateway).not_to receive(:send_email)
            service.call
          end
        end
      end

      context 'and script installed' do
        let(:mailer) { DigestMailer.weekly_digest(site, recipient) }
        before { allow(site).to receive(:script_installed?).and_return(true) }

        context 'when script is installed more than a week ago' do
          before { site.script_installed_at = 1.week.ago }

          context 'with free site' do
            before { allow(site).to receive(:free?).and_return(true) }

            it 'sends "weekly digest" with template "New Email Digest"' do
              expect(MailerGateway)
                .to receive(:send_email).with('New Email Digest', recipient.email, options)
              service.call
            end
          end

          context 'with pro site' do
            before { allow(site).to receive(:free?).and_return(false) }

            it 'sends "weekly digest" with template "New Email Digest (Pro)"' do
              expect(MailerGateway)
                .to receive(:send_email).with('New Email Digest (Pro)', recipient.email, options)
              service.call
            end
          end
        end

        context 'when script is installed less than a week ago' do
          before { site.script_installed_at = 6.days.ago }

          context 'with free site' do
            before { allow(site).to receive(:free?).and_return(true) }

            it 'sends "weekly digest" with template "New Email Digest (First Time)"' do
              expect(MailerGateway)
                .to receive(:send_email).with('New Email Digest (First Time)', recipient.email, options)
              service.call
            end
          end

          context 'with pro site' do
            before { allow(site).to receive(:free?).and_return(false) }

            it 'sends "weekly digest" with template "New Email Digest (First Time, Pro)"' do
              expect(MailerGateway)
                .to receive(:send_email).with('New Email Digest (First Time, Pro)', recipient.email, options)
              service.call
            end
          end
        end
      end
    end

    context 'when site has no elements' do
      let(:site) { create(:site, :with_user) }

      before { allow(site).to receive(:script_installed?).and_return(false) }

      it 'does not send email' do
        expect(DigestMailer).not_to receive(:not_installed)
        expect(DigestMailer).not_to receive(:weekly_digest)
        expect(MailerGateway).not_to receive(:send_email)
        service.call
      end
    end
  end
end
