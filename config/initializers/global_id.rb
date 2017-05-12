GlobalID::Locator.use GlobalID.app do |gid|
  case gid.model_name
  when 'Site'
    Site.preload_for_script.find(gid.model_id)
  else
    GlobalID::Locator::DEFAULT_LOCATOR.locate gid
  end
end
