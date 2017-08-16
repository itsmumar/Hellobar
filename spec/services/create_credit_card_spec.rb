describe CreateCreditCard do
  let(:user) { create :user }
  let(:site) { create :site, user: user }
  let(:payment_form_params) { create :payment_form_params }
  let(:payment_form) { create :payment_form, params: payment_form_params }
  let(:params) { { credit_card: payment_form_params } }
  let(:service) { CreateCreditCard.new(site, user, params) }

  before { stub_cyber_source :store }

  describe '#call' do
    before do
      allow_any_instance_of(CreditCard)
        .to receive(:order_id)
        .and_return '999-1497468514'
    end

    let(:card_params) do
      {
        order_id: '999-1497468514',
        email: "user#{ user.id }@hellobar.com",
        address: payment_form.address_attributes
      }
    end

    it 'creates CreditCard' do
      expect { service.call }.to change(user.credit_cards, :count).by 1
    end

    it 'stores subscriptionID from gateway to #token' do
      expect { service.call }
        .to make_gateway_call(:store)
        .and_succeed
        .with_response(params: { 'subscriptionID' => '999' }, message: 'ok')

      expect(CreditCard.last.token).to eql '999'
    end

    context 'when params are invalid' do
      let(:params) { {} }

      it 'raises ActiveRecord::RecordInvalid' do
        expect { service.call }.to raise_error ActiveRecord::RecordInvalid
      end
    end

    context 'when error is raised' do
      it 'raises error' do
        expect { service.call }
          .to make_gateway_call(:store)
          .and_raise_error('an error')
          .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: an error')
      end
    end

    context 'with unsuccessful response from CyberSource' do
      it 'raises error' do
        expect { service.call }
          .to make_gateway_call(:store)
          .and_fail.with_response(message: 'error', params: {})
          .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: error')
      end

      context 'when invalid cardType' do
        it 'raises error' do
          expect { service.call }
            .to make_gateway_call(:store)
            .and_fail.with_response(params: { 'invalidField' => 'c:cardType' })
            .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Invalid credit card')
        end
      end

      context 'when invalid field' do
        it 'raises error' do
          expect { service.call }
            .to make_gateway_call(:store)
            .and_fail.with_response(params: { 'invalidField' => 'c:number' })
            .and raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Invalid number')
        end
      end
    end
  end
end
