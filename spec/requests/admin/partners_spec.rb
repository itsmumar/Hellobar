describe 'Admin::Partners requests' do
  let!(:admin) { create(:admin) }

  before { stub_current_admin(admin) }

  describe 'GET admin_partners_path' do
    before do
      create_list(:partner, 3)
    end

    it 'renders list of partners' do
      get admin_partners_path
      expect(response).to be_success
    end
  end

  describe 'POST admin_partners_path' do
    let(:partner_attributes) { attributes_for(:partner) }

    it 'creates a new partner' do
      expect {
        post admin_partners_path, partner: partner_attributes
      }.to change { Partner.count }.by(1)
    end

    it 'redirects to partners list' do
      post admin_partners_path, partner: partner_attributes
      expect(response).to redirect_to(admin_partners_path)
    end
  end

  describe 'PATCH admin_partner_path' do
    let!(:partner) { create(:partner) }

    it 'update an existing partner' do
      put admin_partner_path(partner), partner: { require_credit_card: true }

      partner.reload
      expect(partner.require_credit_card).to be_truthy
    end

    it 'redirects to partners list' do
      put admin_partner_path(partner), partner: { require_credit_card: true }
      expect(response).to redirect_to(admin_partners_path)
    end
  end

  describe 'DELETE admin_partner_path' do
    let!(:partner) { create(:partner) }

    it 'deletes partner' do
      expect {
        delete admin_partner_path(partner)
      }.to change { Partner.count }.by(-1)
    end

    it 'redirects to partners list' do
      delete admin_partner_path(partner)
      expect(response).to redirect_to(admin_partners_path)
    end
  end
end
