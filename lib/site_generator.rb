class SiteGenerator
  attr_reader :full_path, :site

  def initialize(site_id, opts = {})
    @site = Site.preload_for_script.find(site_id)
    @full_path = opts[:full_path] || generate_full_path(opts)
    @compress = opts.fetch(:compress, false)
    ScriptGenerator.compile
  end

  def generate_file
    File.open(@full_path, 'w') do |file|
      file.write(generate_html)
    end
  end

  def generate_html
    <<~EOS
      <!DOCTYPE html>
      <html>
      <head>
        <title>Hello Bar Test Site</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta charset="utf-8" />
      </head>

      <body style="background-color: #FFFFFF;">
        <a onclick="console.log('BUTTON PUSHED')" style="cursor: pointer">CLICK ME</a>

        <div style="height:200px; background-color: yellow;">
          TOP OF PAGE CONTENT
          <script id="hb-cu-2">
            window.onload = function() {hellobar('contentUpgrades').show(1);};
          </script>
        </div>

        <div style="height:400px;">
          <h1>Autofills testing playground</h1>
          <p>In order to test the autofills you need to:</p>

          <ul>
            <li>switch your site to the ProManaged subscription</li>
            <li>create an email collection bar (any style)</li>
            <li>create a new autofill rule: <code>listen_selector: `input#f-builtin-email`, populate_selector: `input.email`</code></li>
            <li>regenerate the site: <code>rake test_site:generate</code></li>
            <li>visit local testing page (this page)</li>
            <li>fill in the email address in the bar and click 'Subscripbe'</li>
            <li>reload the page</li>
            <li>observe the input below is autofilled with the value from the the bar (from the localStorage value actually)</li>
          </ul>

          <p>
            Autofill: <input type="email" name="email" class="email" style="font-size: 14px; width: 300px; padding: 5px 6px" />
          </p>
        </div>

        <script>#{ @site.script_content(@compress) }</script>

        <p>Generated on #{ Time.current }</p>
      </body>
      </html>
    EOS
  end

  private

  def generate_full_path(opts)
    directory = opts[:directory]

    return nil if directory.nil?

    directory = Pathname.new(directory) unless directory.respond_to?(:join)
    @full_path = directory.join("#{ SecureRandom.hex }.html")
  end
end
