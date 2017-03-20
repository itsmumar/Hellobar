namespace :site_element do
  desc 'Set `use_default_images` flag to false to maintain expected behavior on existing sites.'
  task theme_default_images: :environment do
    SiteElement.update_all(use_default_image: false)
  end
end
