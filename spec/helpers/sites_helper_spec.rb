module SitesHelper
  def current_site
  end
end

describe SitesHelper do
  let(:user) { create(:user, :with_site) }

  describe 'sites_for_team_view' do
    it 'should rank by current site followed by alphabetical sorting' do
      user.sites.destroy_all
      s1 = user.sites.create(url: 'http://asdf.com')
      s2 = user.sites.create(url: 'http://bsdf.com')
      s3 = user.sites.create(url: 'http://zsdf.com')
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_site).and_return(s2)
      expect(helper.sites_for_team_view).to eq([s2, s1, s3])
    end
  end

  describe 'bill_due_at' do
    it 'formats the due date of the bill' do
      bill = build(:bill)
      allow(bill).to receive(:due_at).and_return(Time.zone.local(2001, 2, 3, 4, 5, 6))
      expect(helper.bill_due_at(bill)).to eq('2-3-2001')
    end
  end

  describe 'bill_estimated_amount' do
    it 'formats the bills estimated amount' do
      bill = build(:bill)
      allow(bill).to receive(:estimated_amount).and_return(12.340)
      expect(helper.bill_estimated_amount(bill)).to eq('$12.34')
    end
  end
end
