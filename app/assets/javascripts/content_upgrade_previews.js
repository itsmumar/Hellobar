(function ($) {

  function getValueFromModel(model, defaultModel, property) {
    return (model || {})[property] || (defaultModel || {})[property] || '';
  }

  $.fn.extend({
    contentUpgradeOfferPreview: function (method) {

      var html = '<div class="content-upgrade-offer-preview js-root"></div>';

      function getOptions($element) {
        return $element.data('options') || {};
      }

      function parseHeadline(rawHeadline) {
        var s = $('<div></div>').text(rawHeadline).html();
        s = rawHeadline.replace(/{{/g, '<a href="javascript:void(0)">');
        s = s.replace(/}}/g, '</a>');
        return s;
      }

      function updateElement($element, model, styles) {
        // Update model
        var rawHeadline = getValueFromModel(model, getOptions($element).defaultModel, 'headline');
        var parsedHeadline = parseHeadline(rawHeadline);
        var $root = $('.js-root', $element);
        $root.html(parsedHeadline);
        // Update styles
        if (styles) {
          styles.offerBackgroundColor && $root.css('background-color', styles.offerBackgroundColor);
          styles.offerBorderColor && $root.css('border-color', styles.offerBorderColor);
          styles.offerBorderWidth && $root.css('border-width', styles.offerBorderWidth);
          styles.offerBorderStyle && $root.css('border-style', styles.offerBorderStyle);
          styles.offerBorderRadius && $root.css('border-radius', styles.offerBorderRadius);
        }
      }

      var methods = {
        init: function (options) {
          return this.each(function () {
            var defaults = {};
            var opts = $.extend(defaults, options);
            var $container = $(this);
            $container.data('options', opts);
            $container.append(html);
            options.defaultModel && setTimeout(function () {
              $container.contentUpgradeOfferPreview('update', options.defaultModel, options.defaultStyles);
            }, 1);
          });
        },
        destroy: function () {
          return this.each(function () {
            $(this).empty();
          });
        },
        update: function (model, styles) {
          return this.each(function () {
            updateElement($(this), model, styles);
          });
        }

      };

      if (methods[method]) {
        return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
      } else if (typeof method === 'object' || !method) {
        return methods.init.apply(this, arguments);
      } else {
        $.error('Method ' + method + ' not found');
      }
    }
  });


  /**
   * @function contentUpgradeOfferPreview jQuery plugin
   */
  $.fn.extend({
    contentUpgradeModalPreview: function (method) {

      var html = '<div class="content-upgrade-modal-preview js-root">' +
        '<div class="progress-bar"></div>' +
        '<div class="caption"></div>' +
        '<div class="headline"></div>' +
        '<div class="form">' +
        '<input class="name" placeholder="Name">' +
        '<input class="email" placeholder="email@example.com">' +
        '<div class="cta"></div>' +
        '</div>' +
        '<div class="spam-disclaimer"></div>' +
        '</div>';

      function getOptions($element) {
        return $element.data('options') || {};
      }

      function getFromModel($element, model, property) {
        return getValueFromModel(model, getOptions($element).defaultModel, property);
      }

      function updateElement($element, model, styles) {
        var $root = $('.js-root', $element);
        $('.caption', $element).text(getFromModel($element, model, 'caption'));
        $('.headline', $element).text(getFromModel($element, model, 'headline'));
        $('.name', $element).attr('placeholder', getFromModel($element, model, 'namePlaceholder'));
        $('.email', $element).attr('placeholder', getFromModel($element, model, 'emailPlaceholder'));
        $('.cta', $element).text(getFromModel($element, model, 'cta'));
        $('.spam-disclaimer', $element).text(getFromModel($element, model, 'spamDisclaimer'));
        if (styles) {
          styles.modalBackgroundColor && $root.css('background-color', styles.modalBackgroundColor);
          styles.modalBorderColor && $root.css('border-color', styles.modalBorderColor);
          styles.modalBorderWidth && $root.css('border-width', styles.modalBorderWidth);
          styles.modalBorderStyle && $root.css('border-style', styles.modalBorderStyle);
          styles.modalBorderRadius && $root.css('border-radius', styles.modalBorderRadius);
        }
      }

      var methods = {
        init: function (options) {
          return this.each(function () {
            var defaults = {};
            var opts = $.extend(defaults, options);
            var $container = $(this);
            $container.data('options', opts);
            $container.append(html);
            options.defaultModel && setTimeout(function () {
              $container.contentUpgradeModalPreview('update', options.defaultModel, options.defaultStyles);
            }, 1);
          });
        },
        destroy: function () {
          return this.each(function () {
            $(this).empty();
          });
        },
        update: function (model, styles) {
          return this.each(function () {
            updateElement($(this), model, styles);
          });
        }
      };

      if (methods[method]) {
        return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
      } else if (typeof method === 'object' || !method) {
        return methods.init.apply(this, arguments);
      } else {
        $.error('Method ' + method + ' not found');
      }
    }
  });


})(jQuery);
