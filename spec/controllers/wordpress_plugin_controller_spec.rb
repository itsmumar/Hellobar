require 'spec_helper'

describe WordpressPluginController do
  it 'generates the wordpress plugin without errors' do
    site = create(:site, :with_user)
    stub_current_user(site.owners.first)

    get :show, site_id: site.to_param

    expect(response).to be_success
    expect(response.header['Content-Type']).to eq('application/zip')
  end
end
