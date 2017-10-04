require 'integration_helper'

describe 'test_sites requests' do
  describe 'GET :show' do
    let!(:site) { create :site }
    let(:script) { "#{ target_site.id } script" }

    before do
      expect(GenerateStaticScriptModules).to receive_service_call
      expect(RenderStaticScript).to receive_service_call.and_return(script)
    end

    context 'with param :id' do
      let(:target_site) { site }

      it 'responds with generated html' do
        get test_site_path(site)

        expect(response).to be_successful
        expect(response.body).to include script
      end
    end

    context 'without param :id' do
      let!(:another_site) { create :site }
      let(:target_site) { Site.order(updated_at: :desc).first }

      it 'responds with generated html' do
        get latest_test_site_path

        expect(response).to be_successful
        expect(response.body).to include script
      end
    end

    context 'with param :fresh' do
      let(:target_site) { site }

      it 'responds with generated html', :freeze do
        expect(Site).to receive(:find).with(site.id.to_s).and_return(site)
        expect(site).to receive(:update_column).with(:updated_at, Time.current)

        get test_site_path(site, fresh: 1)
      end
    end
  end
end
