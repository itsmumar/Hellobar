require 'integration_helper'

describe TestSiteController do
  describe 'GET :show' do
    let!(:site) { create :site }
    let(:path) { Rails.root.join('tmp', "#{ target_site.id }.html") }
    let(:html) { "#{ target_site.id } html" }

    before do
      expect(GenerateTestSite).to receive_service_call.and_return(path)
      path.write html
    end

    after { path.delete }

    context 'with param :id' do
      let(:target_site) { site }

      it 'responds generated html' do
        get '/test_site', id: site.id
        expect(response).to be_successful
        expect(response.body).to eql html
      end
    end

    context 'without param :id' do
      let!(:another_site) { create :site }
      let(:target_site) { Site.order(updated_at: :desc).first }

      it 'responds generated html' do
        get '/test_site'
        expect(response).to be_successful
        expect(response.body).to eql "#{ target_site.id } html"
      end
    end

    context 'with param :fresh' do
      let(:target_site) { site }

      it 'responds generated html', :freeze do
        expect(Site).to receive(:find).with(site.id.to_s).and_return(site)
        expect(site).to receive(:update_column).with(:updated_at, Time.current)
        get '/test_site', id: site.id, fresh: 1
      end
    end
  end
end
