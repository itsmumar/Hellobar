(function() {
  if (typeof(hellobar) === 'undefined') {

    // Load HelloBar JS Core and Modules
    (function() {
      // Data
      var data = {{{data}}};

      // Loading core for module management
      var hellobar = {{{core_js}}}

      // Loading all HelloBar modules
      {{{modules_js}}}

      // A few helper functions
      function hasCapability(capability) {
        return hellobar('base.capabilities').has(capability);
      }

      function isPreviewMode() {
        return hellobar('base.preview').isActive();
      }

      function scriptIsInstalledProperly() {
        return hellobar('base.selfcheck').scriptIsInstalledProperly();
      }

      function configure(moduleName, configurator) {
        hellobar(moduleName, { configurator: configurator });
      }

      // Initialize and configure modules
      configure('base.preview', function(configuration) {
        configuration.previewIsActive(data.preview_is_active);
      });

      configure('base.metainfo', function(configuration) {
        configuration.version(data.version);
        configuration.timestamp(data.timestamp);
      });

      configure('base.capabilities', function(configuration) {
        configuration.capabilities(data.capabilities);
      });

      configure('base.site', function(configuration) {
        configuration.siteId(data.site_id).siteUrl(data.site_url).secret(data.pro_secret);
      });

      function initializeProtectedModules() {

        configure('base.timezone', function(configuration) {
          configuration.defaultTimezone(data.site_timezone);
        });

        configure('base.styling', function(configuration) {
          configuration.externalCSS(data.hellobar_container_css);
        });

        configure('base.templating', function(configuration) {
          for (var template in data.templates) {
            configuration.addTemplate(template.name, template.markup);
          }

          for (var template in data.branding_templates) {
            configuration.addTemplate(template.name, template.markup);
          }

          for (var template in data.content_upgrade_template) {
            configuration.addTemplate(template.name, template.markup);
          }
        });

        configure('geolocation', function(configuration) {
          configuration.geolocationUrl(data.geolocation_url);
        });

        !isPreviewMode() && hasCapability('geolocation_injection') && configure('geolocation.injection', function(configuration) {
          configuration.autoRun(true);
        });

        !isPreviewMode() && configure('tracking.internal', function(configuration) {
          configuration.backendHost(data.hb_backend_host).siteWriteKey(data.site_write_key);
        });

        !isPreviewMode() && hasCapability('external_tracking') && configure('tracking.external', function(configuration) {
          configuration.externalTrackings(data.external_tracking);
        });

        configure('elements.rules', function(configuration) {
          for (var rule in data.rules) {
            configuration.addRule(rule.match, rule.conditions, rule.site_elements);
          }
        });

        configure('elements', function(configuration) {
          configuration.elementCSS(data.hellobar_element_css).autoRun(true);
        });

        configure('contentUpgrades', function(configuration) {
          configuration.contentUpgrades(data.content_upgrades).styles(data.content_upgrades_styles);
        });

        !isPreviewMode() && hasCapability('autofills') && configure('autofills', function(configuration) {
          configuration.autofills(data.autofills).autoRun(true);
        });
      }

      if(!hellobar('base.environment').isIEXOrLess(8) && data.script_is_installed_properly) {
        initializeProtectedModules();
      }
    })();

  } else {
    console.warn('Hello Bar script is already loaded. It seems like you are including the Hello Bar script more than once. Ignoring.');
  }
})();
