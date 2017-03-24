RSpec.configure do |config|
  config.before :suite do
    # stub columns hash so that Hello::WordpressUser.respond_to?(:find_by_email) works
    Hello::WordpressUser.instance_variable_set :@columns_hash, 'email' => ''
  end
end
