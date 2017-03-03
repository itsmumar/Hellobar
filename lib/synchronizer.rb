module Synchronizer
  NoMethodMessage = 'You must require a specific synchronizer (such as Synchronizers::Email) that implements '

  def sync_all!
    fail NoMethodError, NoMethodMessage + '#sync_all!'
  end

  def sync_one!(item, name, options={})
    fail NoMethodError, NoMethodMessage + '#sync_one!'
  end
end

module Synchronizers
end
