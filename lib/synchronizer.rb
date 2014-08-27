class Synchronizer
  def sync_all!
    fail NoMethodError, "You must define #sync_all! method in a subclass."
  end

  def sync_one!(item, name, options={})
    fail NoMethodError, "You must define #sync_one! in a subclass."
  end
end
