class TestProvider < ServiceProvider::Adapters::Base
  configure do |config|
  end

  def initialize(identity)
  end

  def tags
    [{ 'id' => 'tag1', 'name' => 'Tag 1' }]
  end

  def lists
    [{ 'id' => 'list1', 'name' => 'List 1' }]
  end

  def subscribe(email:, name:)
  end
end
