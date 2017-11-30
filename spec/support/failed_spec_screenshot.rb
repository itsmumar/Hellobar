RSpec.configure do |config|
  # Save a screenshot after JS spec failure
  config.after(:each, js: true) do |example|
    if example.exception
      meta = example.metadata
      description = example.description.gsub(/[ (),]/, '_')
      timestamp = Time.current.strftime('%Y%m%d-%H%M%S')
      filename = "js_failure_#{ timestamp }-#{ description }"

      dir = ENV.fetch('CIRCLE_ARTIFACTS', Rails.root.join('tmp', 'screenshots'))
      path = Pathname.new(dir).join(filename)
      path.mkpath

      png_path = "#{ path }.png"
      html_path = "#{ path }.html"

      # Save PNG screenshot
      page.save_screenshot png_path, width: 1000, height: 800

      # Save corresponding HTML
      page.save_page html_path

      puts "\nFAILED SPEC: #{ meta[:description] }"
      puts "Saving screenshot: #{ png_path }\n"
      puts "Saving HTML: #{ html_path }\n"
    end
  end
end
