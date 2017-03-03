module Synchronizer
  NoMethodMessage = 'You must require a specific synchronizer (such as Synchronizers::Email) that implements '

  def sync_all!
    raise NoMethodError, NoMethodMessage + '#sync_all!'
  end

  def sync_one!(_item, _name, _options = {})
    raise NoMethodError, NoMethodMessage + '#sync_one!'
  end
end

module Synchronizers
end
