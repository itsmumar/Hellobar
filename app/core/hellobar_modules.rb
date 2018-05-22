module HellobarModules
  module_function

  def version
    @version ||= File.read('.hellobar-modules-version').chomp
  end

  def filename
    "modules-v#{ version }.js"
  end
end
