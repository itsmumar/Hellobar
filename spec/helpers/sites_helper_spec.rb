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

  describe 'install_help_data' do
    let(:install_help_data) { helper.install_help_data(site) }

    context 'when install_type is "weebly"' do
      let(:site) { build :site, install_type: 'weebly' }

      specify do
        expect(install_help_data)
          .to match ['Weebly', a_string_matching(/support\.hellobar\.com.+weebly/)]
      end
    end

    context 'when install_type is "squarespace"' do
      let(:site) { build :site, install_type: 'squarespace' }

      specify do
        expect(install_help_data)
          .to match ['Squarespace', a_string_matching(/support\.hellobar\.com.+squarespace/)]
      end
    end

    context 'when install_type is "shopify"' do
      let(:site) { build :site, install_type: 'shopify' }

      specify do
        expect(install_help_data)
          .to match ['Shopify', a_string_matching(/support\.hellobar\.com.+shopify/)]
      end
    end

    context 'when install_type is "blogspot"' do
      let(:site) { build :site, install_type: 'blogspot' }

      specify do
        expect(install_help_data)
          .to match ['Blogger', a_string_matching(/support\.hellobar\.com.+bloggerblogspot/)]
      end
    end
  end
end
