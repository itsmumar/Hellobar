class GenerateTestSite
  def initialize(site_id, opts = {})
    @site = Site.preload_for_script.find(site_id)
    @full_path = opts[:full_path] || generate_full_path(opts)
    @compress = opts.fetch(:compress, false)
  end

  def call
    GenerateAndStoreStaticScript.new(site, path: 'test_site.js').call

    File.open(full_path, 'w') do |file|
      file.write(generate_html)
    end

    full_path
  end

  private

  attr_reader :full_path, :site

  def generate_html
    <<~EOS
      <!DOCTYPE html>
      <html>
      <head>
        <title>Hello Bar Test Site</title>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta charset="utf-8" />
        <link rel=icon href="favicon-test-site.png" sizes="16x16" type="image/png /">
        <style>
          body > section {
            margin-bottom: 60px;
          }
        </style>
      </head>

      <body>
        <section>
          <h1>Autofills</h1>
          <p>In order to test the autofills you need to:</p>

          <ul>
            <li>switch your site to the ProManaged subscription</li>
            <li>create an email collection bar (any style)</li>
            <li>create a new autofill rule: <code>listen_selector: `input#f-builtin-email`, populate_selector: `input.email`</code></li>
            <li>regenerate the site: <code>rake test_site:generate</code></li>
            <li>visit local testing page (this page)</li>
            <li>fill in the email address in the bar and click 'Subscribe'</li>
            <li>reload the page</li>
            <li>observe the input below is autofilled with the value from the the bar (from the localStorage value actually)</li>
          </ul>

          <p>
            Autofill: <input type="email" name="email" class="email" style="font-size: 14px; width: 300px; padding: 5px 6px" />
          </p>
        </section>

        <section id="content-upgrade-container">
          <h1>Content Upgrades</h1>
          #{ content_upgrades_script_tags }
        </section>

        <section id="content-upgrade-ab-test-container">
          <h1>Content Upgrade A/B test</h1>
          <div data-hb-cu-ab-test="#{ content_upgrade_tests.pluck(:id).join(',') }"></div>
        </section>

        <script src="generated_scripts/test_site.js"></script>

        <section>
          <h1>External Tracking</h1>
          <p><a href="?utm_source=Hello%20Bar&amp;utm_medium=test_site&amp;utm_campaign=test">utm tags</a> <a href="?">no utm tags</a></p>
          <pre class="events"></pre>

          <script>
            const events = document.querySelector('pre.events');

            // Google Tag Manager
            var dataLayer = {
              push: (externalEvent) => {
                const { event, category, action, label, utm_source, utm_medium, utm_campaign } = externalEvent;
                events.innerHTML += `[Google Tag Manager] event: '${ event }', category: '${ category }', action: '${ action }', label: '${ label }'`;

                utm_source && (events.innerHTML += `, utm_source: '${ utm_source }'`);
                utm_medium && (events.innerHTML += `, utm_medium: '${ utm_medium }'`);
                utm_campaign && (events.innerHTML += `, utm_campaign: '${ utm_campaign }'`);

                events.innerHTML += `\n<hr>`;
              }
            }

            // Google Analytics
            var ga = (action, externalEvent) => {
              const { hitType, eventCategory, eventAction, eventLabel } = externalEvent;
              events.innerHTML += `[Google Analytics] hitType: '${ hitType }', eventCategory: '${ eventCategory }', eventAction: '${ eventAction }', eventLabel: '${ eventLabel }'\n`;
            }

            // Google Analytics (Legacy)
            var _gaq =  {
              push: (externalEvent) => {
                const [event, category, action, label] = externalEvent;
                events.innerHTML += `[Google Analytics (Legacy)] event: '${ event }', category: '${ category }', action: '${ action }', label: '${ label }'\n`;
              }
            }
          </script>
        </section>

        <section>
          <p style="margin-top: 100px;">Generated on #{ Time.current }</p>
        </section>
      </body>
      </html>
    EOS
  end

  def generate_full_path(opts)
    directory = opts[:directory]

    return nil if directory.nil?
    directory = Pathname.new(directory) unless directory.respond_to?(:join)
    directory.join("#{ SecureRandom.hex }.html")
  end

  def content_upgrades
    @site.site_elements.active_content_upgrades
  end

  def content_upgrade_tests
    content_upgrades.where('offer_headline like ?', 'Test %')
  end

  def content_upgrades_script_tags
    content_upgrades.where.not('offer_headline like ?', 'Test %').first&.content_upgrade_script_tag
  end
end
