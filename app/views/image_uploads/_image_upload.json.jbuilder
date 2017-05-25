json.cache! image_upload do
  json.extract! image_upload,
    :id,
    :description,
    :url,
    :large_url,
    :medium_url,
    :image_file_name,
    :image_content_type,
    :image_file_size,
    :image_updated_at,
    :created_at,
    :updated_at,
    :site_id,
    :preuploaded_url,
    :theme_id,
    :version
end
