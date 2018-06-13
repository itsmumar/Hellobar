module HellobarModules
  module_function

  def version
    @version ||= File.read('.hellobar-modules-version').chomp
  end

  def filename
    "modules-v#{ version }.js"
  end

  def local_modules_url
    return if Settings.local_modules_url && !check_local_modules
    Settings.local_modules_url
  end

  def bump!
    version.to_i.next.tap do |next_version|
      File.write('.hellobar-modules-version', next_version)
    end
  end

  private

  def check_local_modules
    HTTParty.get(Settings.local_modules_url).success?
  rescue Errno::ECONNREFUSED
    false
  end
end
