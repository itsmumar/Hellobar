describe ChangeSubscription, :freeze do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:credit_card) { create :credit_card, user: user }
  let(:params) { { subscription: 'pro', schedule: 'yearly' } }
  let(:service) { ChangeSubscription.new(site, params, credit_card) }
  let(:last_subscription) { Subscription.last }
  let(:overage_service) { HandleOverageSite.new(site, number_of_views, limit) }

  before do
    stub_cyber_source :purchase
    change_subscription 'free'

    allow(TrackSubscriptionChange).to receive_message_chain(:new, :call)
  end

  def change_subscription(subscription, schedule = 'monthly', new_credit_card: nil)
    ChangeSubscription.new(
      site,
      { subscription: subscription, schedule: schedule },
      new_credit_card || credit_card
    ).call
  end

  describe '#same_subscription?' do
    context 'when subscription is changed' do
      let(:params) { { subscription: 'pro', schedule: 'yearly' } }

      it 'returns false' do
        expect(service.same_subscription?).to be_falsey
      end
    end

    context 'when schedule is changed' do
      before { change_subscription('pro', 'monthly') }

      let(:params) { { subscription: 'pro', schedule: 'yearly' } }

      it 'returns false' do
        expect(service.same_subscription?).to be_falsey
      end
    end

    context 'when neither subscription nor schedule is changed' do
      before { change_subscription('pro', 'monthly') }

      let(:params) { { subscription: 'pro', schedule: 'monthly' } }

      it 'returns true' do
        expect(service.same_subscription?).to be_truthy
      end
    end
  end

  describe '#call' do
    it 'creates a bill for current period' do
      expect { service.call }
        .to change(site.bills.where(bill_at: Time.current), :count).by(1)
    end

    it 'creates a bill for next period' do
      expect { service.call }.to change(site.bills.pending, :count).by(1)
    end

    it 'pays bill' do
      expect(PayBill).to receive_service_call.and_return(build_stubbed(:bill))
      service.call
    end

    it 'regenerates script' do
      expect { service.call }
        .to have_enqueued_job(GenerateStaticScriptJob).with(site).twice
    end

    it 'returns paid bill' do
      expect(service.call).to be_a(Bill).and be_paid
    end

    context 'with pending bills' do
      let!(:pending_bill) { create :bill, :free, subscription: site.current_subscription }

      it 'voids pending bills' do
        service.call
        expect(pending_bill.reload).to be_voided
      end
    end

    context 'without credit card' do
      let(:credit_card) { nil }

      it 'raises PayBill::MissingCreditCard' do
        expect { service.call }
          .to raise_error PayBill::MissingCreditCard, 'Could not pay bill without credit card'
      end
    end

    context 'with monthly schedule' do
      let(:params) { { subscription: 'pro', schedule: 'monthly' } }

      it 'creates a bill for next period' do
        expect { service.call }.to change(site.bills.pending, :count).to(1)
      end
    end

    context 'upgrade to Pro' do
      it 'creates Subscription::Pro' do
        expect { service.call }
          .to change(site.subscriptions, :count)
          .by(1)
          .and change(credit_card.subscriptions, :count)
          .by(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Pro
      end

      it 'tracks subscription change event' do
        expect(TrackSubscriptionChange).to receive_service_call.with(
          user,
          instance_of(Subscription::Free),
          instance_of(Subscription::Pro)
        )

        service.call
      end
    end

    context 'upgrade to elite' do
      let(:params) { { subscription: 'elite', schedule: 'yearly' } }

      it 'creates Subscription::Elite' do
        expect { service.call }
          .to change(site.subscriptions, :count)
          .by(1)
          .and change(credit_card.subscriptions, :count)
          .by(1)

        expect(last_subscription.schedule).to eql 'yearly'
        expect(last_subscription).to be_a Subscription::Elite
      end

      it 'tracks subscription change event' do
        expect(TrackSubscriptionChange).to receive_service_call.with(
          user,
          instance_of(Subscription::Free),
          instance_of(Subscription::Elite)
        )

        service.call
      end
    end

    context 'when error is raised during transaction' do
      it 'does not create neither a subscription nor a bill' do
        expect(PayBill).to receive_service_call.and_raise(StandardError)
        expect { service.call }
          .to raise_error(StandardError)
          .and change(Subscription, :count)
          .by(0)
          .and change(Bill, :count)
          .by(0)
      end
    end

    context 'when could not charge credit card' do
      it 'raises ActiveRecord::RecordInvalid' do
        expect {
          expect { service.call }.to make_gateway_call(:purchase).and_fail
        }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    describe 'upgrading/downgrading' do
      def refund(bill)
        RefundBill.new(bill).call
      end

      context 'when changing to the same type' do
        before { change_subscription('pro', 'monthly') }

        it 'does not change subscription' do
          expect { change_subscription('pro', 'monthly') }
            .not_to change { site.reload.current_subscription }
        end

        it 'updates payment method' do
          site.current_subscription.update credit_card: create(:credit_card)

          expect { change_subscription('pro', 'monthly') }
            .to change { site.current_subscription.reload.credit_card }
        end

        it 'tracks subscription change event' do
          expect(TrackSubscriptionChange).to receive_service_call.with(
            user,
            instance_of(Subscription::Pro),
            instance_of(Subscription::Pro)
          )

          service.call
        end

        context 'when there is a problem bill' do
          let!(:new_credit_card) { create :credit_card }
          let(:failed_bill) { site.current_subscription.bills.last }

          before do
            change_subscription('pro', 'monthly')
            failed_bill.fail!
          end

          it 'pays the failed bill' do
            expect { change_subscription('pro', 'monthly') }
              .to change(site.bills.failed, :count)
              .by(-1)
          end

          it 'uses new credit card if provided' do
            expect(failed_bill.reload.subscription.credit_card).to eql credit_card

            Timecop.travel site.current_subscription.active_until + 1.day do
              change_subscription('pro', 'monthly', new_credit_card: new_credit_card)
              expect(failed_bill.reload.subscription.credit_card).to eql new_credit_card
            end
          end
        end
      end

      context 'when starting with Free plan' do
        before { site.current_subscription.destroy }

        it 'changes subscription and capabilities' do
          expect { change_subscription('free') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Free
          expect(site).to be_capable_of :free
        end

        it 'does not create a bill' do
          expect(PayBill).not_to receive_service_call
          expect { change_subscription('free') }.not_to change(Bill, :count)
        end

        it 'tracks subscription change event' do
          expect(TrackSubscriptionChange).to receive_service_call.with(
            user,
            nil,
            instance_of(Subscription::Free)
          )

          change_subscription('free')
        end
      end

      context 'when upgrading to ProManaged' do
        it 'changes subscription and capabilities' do
          expect { change_subscription('pro_managed') }
            .to change { site.reload.current_subscription }

          expect(site.current_subscription).to be_instance_of Subscription::ProManaged
          expect(site).to be_capable_of :pro_managed
        end

        it 'pays bill' do
          expect(PayBill).to receive_service_call
          change_subscription('pro_managed')
        end

        it 'does not create pending bill for next period' do
          expect { change_subscription('pro_managed') }
            .not_to change { site.reload.bills.pending }
        end

        it 'never expires' do
          change_subscription('pro_managed')
          Timecop.travel 10.years.from_now do
            expect(site.current_subscription).to be_instance_of Subscription::ProManaged
            expect(site).to be_capable_of :pro_managed
          end
        end

        it 'tracks subscription change event' do
          expect(TrackSubscriptionChange).to receive_service_call.with(
            user,
            instance_of(Subscription::Free),
            instance_of(Subscription::ProManaged)
          )

          change_subscription('pro_managed')
        end
      end

      context 'when upgrading to Pro from FreePlus' do
        before { change_subscription('free_plus') }

        it 'changes subscription and capabilities' do
          expect { change_subscription('pro') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Pro
          expect(site).to be_capable_of :pro
        end

        it 'pays bill' do
          expect(PayBill).to receive_service_call
          change_subscription('pro')
        end

        it 'voids free bill' do
          expect(PayBill).to receive_service_call
          change_subscription('pro')
          expect(site.previous_subscription.bills).to match_array([kind_of(Bill)])
          expect(site.previous_subscription.bills.first).to be_voided
        end

        it 'tracks subscription change event' do
          expect(TrackSubscriptionChange).to receive_service_call.with(
            user,
            instance_of(Subscription::FreePlus),
            instance_of(Subscription::Pro)
          )

          change_subscription('pro')
        end

        it 'resets overage count' do
          site.update_attribute('overage_count', 999)
          expect { change_subscription('pro') }
            .to have_enqueued_job(ResetCurrentOverageJob)
            .with(site)

          expect(site.reload.overage_count).to eql 0
        end

        context 'and then to Elite from Pro' do
          before { change_subscription('pro') }

          it 'changes subscription and capabilities' do
            expect { change_subscription('elite') }.to change { site.reload.current_subscription }
            expect(site.current_subscription).to be_instance_of Subscription::Elite
            expect(site).to be_capable_of :elite
          end

          it 'excludes a paid amount from new bill' do
            expect(change_subscription('elite').amount).to eql 99 - 29
          end

          it 'pays bill' do
            expect(PayBill).to receive_service_call
            change_subscription('elite')
          end

          it 'tracks subscription change event' do
            expect(TrackSubscriptionChange).to receive_service_call.with(
              user,
              instance_of(Subscription::Pro),
              instance_of(Subscription::Elite)
            )

            change_subscription('elite')
          end

          context 'when a refund has been made' do
            before { stub_cyber_source :refund, :purchase }
            before { RefundBill.new(site.reload.current_subscription.bills.paid.last).call }

            it 'charges full amount' do
              expect(change_subscription('elite').amount).to eql 99
            end
          end
        end
      end

      context 'when downgrading to Free from Pro' do
        before { change_subscription('pro') }

        it 'changes subscription' do
          expect { change_subscription('free') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Free
        end

        it 'does not change capabilities' do
          expect { change_subscription('free') }.not_to change { site.reload.capabilities }
        end

        it 'does not pay bill' do
          expect(PayBill).not_to receive_service_call
          change_subscription('free')
        end

        it 'voids pending bill' do
          expect { change_subscription('free') }
            .to change { site.bills.voided.count }
            .by(1)
        end

        it 'tracks subscription change event' do
          expect(TrackSubscriptionChange).to receive_service_call.with(
            user,
            instance_of(Subscription::Pro),
            instance_of(Subscription::Free)
          )

          change_subscription('free')
        end

        context 'when Pro subscription expires' do
          it 'changes capabilities to Free' do
            change_subscription('free')

            Timecop.travel 1.month.from_now + 1.day do
              expect(site).to be_capable_of :free
            end
          end
        end

        it 'returns a bill' do
          bill = change_subscription('free')
          expect(bill).to be_a(Bill)
        end
      end

      context 'when downgrading to Free from Elite' do
        before { change_subscription('elite') }

        it 'changes subscription' do
          expect { change_subscription('free') }.to change { site.reload.current_subscription }
          expect(site.current_subscription).to be_instance_of Subscription::Free
        end

        it 'does not change capabilities' do
          expect { change_subscription('free') }.not_to change { site.reload.capabilities }
        end

        it 'does not pay bill' do
          expect(PayBill).not_to receive_service_call
          change_subscription('free')
        end

        it 'tracks subscription change event' do
          expect(TrackSubscriptionChange).to receive_service_call.with(
            user,
            instance_of(Subscription::Elite),
            instance_of(Subscription::Free)
          )

          change_subscription('free')
        end

        context 'when Pro subscription expires' do
          it 'changes capabilities to Free' do
            change_subscription('free')

            Timecop.travel 1.month.from_now + 1.day do
              expect(site).to be_capable_of :free
            end
          end
        end
      end

      context 'when payment fails' do
        let(:last_bill) { site.reload.current_subscription.bills.non_free.last }

        it 'returns problem bill' do
          expect {
            expect { service.call }.to make_gateway_call(:purchase).and_fail
          }.to raise_error ActiveRecord::RecordInvalid
          expect(last_bill).to be_nil
          expect(site.current_subscription).to be_instance_of Subscription::Free
          expect(site).to be_capable_of :free
        end
      end

      context 'when switching from yearly to monthly' do
        it 'does not create a negative bill' do
          yearly_bill = change_subscription('pro', 'yearly')
          expect(yearly_bill.amount).to eql Subscription::Pro.defaults[:yearly_amount]
          expect(yearly_bill).to be_paid

          monthly_bill = change_subscription('pro', 'monthly')
          expect(monthly_bill.amount).to eql Subscription::Pro.defaults[:monthly_amount]
          expect(monthly_bill.due_at).to eql yearly_bill.due_at + 1.year
          expect(monthly_bill).to be_pending
        end
      end

      context 'accidentally signed up for the annual plan' do
        before { stub_cyber_source :refund, :purchase }

        it 'sets correct bill_at, start_date and end_date' do
          yearly_bill = change_subscription('pro', 'yearly')
          refund(yearly_bill)
          monthly_bill = change_subscription('pro', 'monthly')
          expect(monthly_bill.bill_at).to eql Time.current
          expect(monthly_bill.start_date).to eql Time.current
          expect(monthly_bill.end_date).to eql 1.month.from_now
        end
      end
    end

    context 'pro special $1 trial' do
      it 'sets amount to $1', freeze: ChangeSubscription::ONE_DOLLAR_PRO_SPECIAL_END_DATE do
        bill = change_subscription('pro_special', 'monthly')
        expect(bill.amount).to eql 1
      end

      context 'after 2019-06-01', freeze: '2019-06-02' do
        it 'does not change amount' do
          bill = change_subscription('pro_special', 'monthly')
          expect(bill.amount).to eql Subscription::ProSpecial.defaults[:monthly_amount]
        end
      end
    end
  end
end
