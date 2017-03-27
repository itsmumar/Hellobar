RSpec.configure do |config|
  config.before :suite do
    # make class abstract so that no db queries are processed
    # and Hello::WordpressUser.respond_to?(:find_by_email) works
    Hello::WordpressUser.abstract_class = true
  end
end
