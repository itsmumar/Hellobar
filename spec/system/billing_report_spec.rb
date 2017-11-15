describe BillingReport, :freeze do
  let(:bills_count) { 999 }
  let(:report) { BillingReport.new(bills_count) }
  let(:bill) { create :bill }

  before { allow(report).to receive(:puts) }

  matcher :log do |logs|
    supports_block_expectations

    match do |block|
      @level ||= :info

      logs.each do |l|
        allow(BillingLogger).to receive(:info).with(l)
        expect(PostToSlack).to receive_service_call.with(:billing, text: l)
        allow(report).to receive(:puts).with(l)
      end
      block.call
      expect(report.log).to match_array logs
    end
  end

  describe '#email' do
    before do
      allow_any_instance_of(PostToSlack).to receive(:call)

      report.start
      report.attempt(bill) do
        report.fail 'error'
        report.success
      end
    end

    let(:subject) { "#{ Time.current.strftime('%Y-%m-%d') } - 999 bills processed for $10.00 with 1 failures" }
    let(:body) do
      [
        '  test: ' + Time.current.to_s,
        '  --------------------------------------------------------------------------------',
        '  Found 999 pending bills...',
        "  Attempting to bill #{ bill.id }: #{ bill.site.url } for $10.00... Failed: error",
        "  Attempting to bill #{ bill.id }: #{ bill.site.url } for $10.00... OK"
      ].join("\n")
    end

    specify do
      expect(Pony).to receive(:mail).with(to: 'dev@hellobar.com', subject: subject, body: body)
      report.email
    end

    context 'when production' do
      before { allow(Rails.env).to receive(:production?).and_return true }

      specify do
        expect(Pony).to receive(:mail).with(to: 'mailmanager@hellobar.com', subject: subject, body: body)
        report.email
      end
    end
  end

  describe '#start' do
    specify do
      expect { report.start }.to log [
        'test: ' + Time.current.to_s,
        '-' * 80,
        'Found 999 pending bills...'
      ]
    end
  end

  describe '#finish' do
    specify do
      expect { report.finish }.to log [
        '-' * 80,
        '0 successful bills for $0.00',
        '0 failed bills for $0.00',
        '0 skipped bills for $0.00',
        '0 bills have been processed',
        '',
        ''
      ]
    end
  end

  describe '#interrupt' do
    specify do
      expect { report.interrupt(nil) }.to log [
        '---- INTERRUPT ----',
        '-' * 80,
        '0 successful bills for $0.00',
        '0 failed bills for $0.00',
        '0 skipped bills for $0.00',
        '0 bills have been processed',
        '',
        ''
      ]
    end
  end

  describe '#count' do
    specify do
      expect { 1500.times { report.count } }.to log [
        '500 bills processed...',
        '1000 bills processed...',
        '1500 bills processed...'
      ]
    end
  end

  context 'within #attempt block' do
    let(:attempting_msg) do
      "Attempting to bill #{ bill.id }: #{ bill.subscription.site.url } for $#{ bill.amount.to_i }.00..."
    end

    describe '#cannot_pay' do
      specify do
        report.attempt(bill) do
          expect { report.cannot_pay }.to log [
            "#{ attempting_msg } Cannot pay the bill"
          ]
        end
      end
    end

    describe '#fail' do
      specify do
        report.attempt(bill) do
          expect { report.fail 'some message' }.to log([
            "#{ attempting_msg } Failed: some message"
          ])
        end
      end
    end

    describe '#success' do
      specify do
        report.attempt(bill) do
          expect { report.success }.to log([
            "#{ attempting_msg } OK"
          ])
        end
      end
    end

    context 'when exception occurs' do
      specify do
        report.attempt(bill) do
          expect { report.attempt(bill) { raise 'error' } }
            .to log(["#{ attempting_msg } ERROR", anything])
            .and raise_error('error')
        end
      end
    end
  end

  describe '#void' do
    specify do
      expect { report.void(bill) }.to log [
        "Voiding bill #{ bill.id } because subscription or site not found"
      ]
    end
  end

  describe '#downgrade' do
    specify do
      expect { report.downgrade(bill) }.to log [
        "Voiding outdated bill #{ bill.id }",
        "Downgrading site ##{ bill.site.id } #{ bill.site.url }"
      ]
    end
  end

  describe '#skip' do
    let(:bill) { create :bill, :with_attempt }
    let(:last_billing_attempt) { bill.billing_attempts.last }

    specify do
      expect { report.skip(bill, last_billing_attempt) }.to log [
        "Not attempting bill #{ bill.id } because last billing attempt was #{ last_billing_attempt.created_at }"
      ]
    end
  end
end
