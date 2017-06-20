describe CreateOrUpdatePaymentMethod do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:payment_form_params) { create :payment_form_params }
  let(:payment_form) { create :payment_form, params: payment_form_params }
  let(:params) { { payment_method_details: payment_form_params } }
  let(:service) { CreateOrUpdatePaymentMethod.new(site, user, params) }

  before { stub_gateway_methods :store, :update }

  describe '.call' do
    it 'creates CyberSourceCreditCard' do
      expect { service.call }.to change(user.payment_method_details, :count).to 1
    end

    it 'creates PaymentMethod' do
      expect { service.call }.to change(user.payment_methods, :count).to 1
    end

    context 'when params are invalid' do
      let(:params) { {} }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { service.call }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'with existing payment method' do
      let!(:payment_method) { create :payment_method }
      let(:service) { CreateOrUpdatePaymentMethod.new(site, user, params, payment_method: payment_method) }

      it 'creates new CyberSourceCreditCard' do
        expect { service.call }
          .to change(CyberSourceCreditCard, :count).by(1)
      end

      it 'returns given payment method' do
        expect(service.call).to be payment_method
      end

      context 'and blank payment_method_details' do
        let(:params) { {} }

        it 'does not create new CyberSourceCreditCard' do
          expect { service.call }
            .not_to change(CyberSourceCreditCard, :count)
        end

        it 'returns given payment method' do
          expect(service.call).to be payment_method
        end
      end
    end

    context 'without successful payment method' do
      before { allow_any_instance_of(CyberSourceCreditCard).to receive(:order_id).and_return '999-1497468514' }

      let(:card_params) do
        {
          order_id: '999-1497468514',
          email: "user#{ user.id }@hellobar.com",
          address: payment_form.address_attributes
        }
      end

      it 'stores subscriptionID from gateway to CyberSourceCreditCard#token' do
        expect { service.call }
          .to make_gateway_call(:store)
          .and_succeed
          .with_response(params: { 'subscriptionID' => '999' })

        expect(CyberSourceCreditCard.last.token).to eql '999'
      end
    end

    context 'with successful payment method' do
      before { allow_any_instance_of(CyberSourceCreditCard).to receive(:order_id).and_return '999-1497468514' }

      let(:card_params) do
        {
          order_id: '999-1497468514',
          email: "user#{ user.id }@hellobar.com",
          address: payment_form.address_attributes
        }
      end

      before do
        create :cyber_source_credit_card, user: user
      end

      it 'sends update request to CyberSource gateway' do
        expected_args = [
          ';token;',
          instance_of(ActiveMerchant::Billing::CreditCard),
          hash_including(card_params)
        ]

        expect { service.call }
          .to make_gateway_call(:update)
          .with(*expected_args)
          .and_succeed
          .with_response(params: { 'subscriptionID' => '1' })
      end
    end

    context 'when error is raised' do
      it 'raises error and creates BillingLog' do
        expect { service.call }
          .to make_gateway_call(:store).and_raise_error('an error')
          .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: an error')

        expect(BillingLog.last.message).to match(/Error tokenizing with/)
      end
    end

    context 'with unsuccessful response' do
      it 'raises error and creates BillingLog' do
        expect { service.call }
          .to make_gateway_call(:store).and_fail.with_response(message: 'error', params: {})
          .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: error')

        expect(BillingLog.first.message).to match(/Create new token with/)
        expect(BillingLog.second.message).to match(/Error tokenizing with/)
      end

      context 'when invalid cardType' do
        it 'raises error and creates BillingLog' do
          expect { service.call }
            .to make_gateway_call(:store).and_fail.with_response(params: { 'invalidField' => 'c:cardType' })
            .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Invalid credit card')

          expect(BillingLog.first.message).to match(/Create new token with/)
          expect(BillingLog.second.message).to match(/Error tokenizing with/)
        end
      end

      context 'when invalid field' do
        it 'raises error and creates BillingLog' do
          expect { service.call }
            .to make_gateway_call(:store).and_fail.with_response(params: { 'invalidField' => 'c:number' })
            .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Invalid number')

          expect(BillingLog.first.message).to match(/Create new token with/)
          expect(BillingLog.second.message).to match(/Error tokenizing with/)
        end
      end
    end
  end
end
