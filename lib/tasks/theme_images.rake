namespace :themes do
  desc "Create image uploads for themes with images"
  task image_upload_import: :environment do
    themes_with_images = Theme.all.select{|t| t.with_image?}
    themes_with_images.each do |theme|
      image_upload = ImageUpload.find_by_theme_id theme.id
      unless image_upload
        file_name = theme.image["default_url"].split(%r{(.*\/)(.*)})[-1]
        ImageUpload.create theme_id: theme.id, preuploaded_url: theme.image["default_url"], image_file_name: file_name
      end
    end
  end
end
