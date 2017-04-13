describe LeadsController do
  let!(:user) { create :user, first_name: 'Foo', last_name: 'Bar' }

  before { stub_current_user user }

  context 'POST create' do
    context 'with valid data' do
      let(:lead_params) { attributes_for :lead, first_name: 'F', last_name: 'L' }

      context 'when interested' do
        let(:lead_params) { attributes_for :lead, :interested }

        it 'renders nothing' do
          post :create, lead: lead_params
          expect(response.status).to eq(200)
          expect(response.body).to be_blank
        end
      end

      context 'when not interested' do
        let(:lead_params) { attributes_for :lead }

        it 'renders nothing' do
          post :create, lead: lead_params
          expect(response.status).to eq(200)
          expect(response.body).to be_blank
        end
      end

      it 'update user first_name and last_name' do
        expect { post :create, lead: lead_params }
          .to change { user.reload.first_name }.to('F')
          .and change { user.reload.last_name }.to('L')
      end
    end

    context 'with invalid file' do
      let(:lead_params) { attributes_for :lead, :empty }

      it 'renders validation errors' do
        post :create, lead: lead_params
        expect(response.status).to eq(422)
      end

      it 'sends exception to Raven' do
        expect(Raven).to receive(:capture_exception).with(instance_of(ActiveRecord::RecordInvalid))
        post :create, lead: lead_params
      end
    end
  end
end
