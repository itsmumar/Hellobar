if Rails.env.development? || Rails.env.test?
  require Rails.root.join('lib/site_generator.rb')
end
