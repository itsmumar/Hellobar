describe LeadsController do
  let!(:user) { create(:user) }
  let!(:lead) { create(:lead, :empty, user: user) }

  before { stub_current_user user }

  context 'POST create' do
    context 'with valid data' do
      context 'with phone' do
        let(:lead_params) { attributes_for :lead, :interesting }

        it 'renders nothing' do
          post :create, lead: lead_params
          expect(response.status).to eq(200)
          expect(response.body).to be_blank
        end
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
