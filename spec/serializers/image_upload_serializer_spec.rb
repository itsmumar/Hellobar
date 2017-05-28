describe ImageUploadSerializer do
  it 'serializes ImageUpload' do
    image_upload = build_stubbed :image_upload

    serialized_image_upload = ImageUploadSerializer.new image_upload
    serialized_hash = serialized_image_upload.serializable_hash

    %i[id description url small_url medium_url large_url modal_url image_file_name
       image_content_type image_file_size image_updated_at created_at updated_at
       site_id preuploaded_url theme_id version].each do |attribute|
      expect(serialized_hash).to have_key attribute
    end
  end
end
