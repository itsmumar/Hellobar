describe SaveCardToCyberSource do
  let(:user) { create :user }
  let(:form) { create :payment_form }
  let(:params) { { order_id: '999-1497468514', email: "user#{ user.id }@hellobar.com", address: form.address_attributes } }
  let(:service) { SaveCardToCyberSource.new(user, form.card, params) }

  describe '#call' do
    context 'without successful payment method' do
      it 'sends store request to CyberSource gateway' do
        expected_args = [
          instance_of(ActiveMerchant::Billing::CreditCard),
          hash_including(params)
        ]

        expect { service.call }
          .to make_gateway_call(:store)
          .with(*expected_args)
          .and_succeed
          .with_response(params: { 'subscriptionID' => '999' }, message: 'ok')
      end

      it 'returns subscriptionID from gateway' do
        stub_cyber_source :store, params: { 'subscriptionID' => '999' }
        expect(service.call).to eql '999'
      end
    end

    context 'with successful payment method' do
      before do
        create :cyber_source_credit_card, user: user
      end

      it 'sends update request to CyberSource gateway' do
        expected_args = [
          ';token;',
          instance_of(ActiveMerchant::Billing::CreditCard),
          hash_including(params)
        ]

        expect { service.call }
          .to make_gateway_call(:update)
          .with(*expected_args)
          .and_succeed
          .with_response(params: { 'subscriptionID' => '999' }, message: 'ok')
      end

      it 'returns subscriptionID from gateway' do
        stub_cyber_source :update, params: { 'subscriptionID' => '999' }
        expect(service.call).to eql '999'
      end
    end

    context 'with unsuccessful response' do
      it 'raises error' do
        expect { service.call }
          .to make_gateway_call(:store).and_fail.with_response(message: 'error', params: {})
          .and raise_error 'error'
      end

      context 'when invalid cardType' do
        it 'raises error' do
          expect { service.call }
            .to make_gateway_call(:store).and_fail.with_response(params: { 'invalidField' => 'c:cardType' })
            .and raise_error 'Invalid credit card'
        end
      end

      context 'when invalid field' do
        it 'raises error' do
          expect { service.call }
            .to make_gateway_call(:store).and_fail.with_response(params: { 'invalidField' => 'c:number' })
            .and raise_error 'Invalid number'
        end
      end
    end
  end
end
