module Synchronizer
  NO_METHOD_MESSAGE = 'You must require a specific synchronizer (such as Synchronizers::Email) that implements '.freeze

  def sync_all!
    raise NoMethodError, NO_METHOD_MESSAGE + '#sync_all!'
  end

  def sync_one!(_item, _name, _options = {})
    raise NoMethodError, NO_METHOD_MESSAGE + '#sync_one!'
  end
end

module Synchronizers
end
