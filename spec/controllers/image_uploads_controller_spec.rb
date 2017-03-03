require 'spec_helper'

describe ImageUploadsController do
  before do
    @user = create(:user)
    stub_current_user(@user)
    @site_element = create(:site_element)
    @site_element.site.users << @user
  end

  context 'POST create' do
    context 'with valid image' do
      let (:image) {Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'images', 'coupon.png'), 'image/png')}

      it 'returns success' do
        post :create, file: image, format: :json, site_id: @site_element.site.id, site_element_id: @site_element.id

        expect(response.status).to eq(200)
      end

      it 'saves attached file' do
        post :create, file: image, format: :json, site_id: @site_element.site.id, site_element_id: @site_element.id

        expect(ImageUpload.last).to have_attached_file(:image)
      end
    end

    context 'with invalid file' do
      let (:image) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'images', 'not_an_image.txt'), 'text/plain') }

      it 'returns failure and errors when the file is not an image' do
        post :create, file: image, format: :json, site_id: @site_element.site.id, site_element_id: @site_element.id

        expect(response.status).to eq(500)
        response_body = JSON.parse(response.body)
        expect(response_body['error'].include?('Image content type is invalid')).to be_true
      end
    end
  end
end
