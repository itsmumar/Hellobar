class TestSite
  def self.path(relative_path = '')
    Rails.root.join(relative_path)
  end

  def self.default_site_id
    Site.order(updated_at: :desc).first.id
  end

  def self.default_path
    path('public/test_site.html')
  end

  def self.generate(site_id, full_path)
    raise 'site id is empty' if site_id.blank?
    GenerateTestSite.new(site_id, full_path: full_path).call
  end

  def self.generate_default(site_id = nil)
    site_id ||= default_site_id
    generate(site_id, default_path)
  end

  def self.run_file
    path('lib/test_site.rb')
  end
end
