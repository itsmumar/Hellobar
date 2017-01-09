(function ($) {

  function getValueFromModel(model, defaultModel, property) {
    return model[property] || (defaultModel || {})[property] || '';
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

      function updateElement($element, model) {
        var rawHeadline = getValueFromModel(model, getOptions($element).defaultModel, 'headline');
        var parsedHeadline = parseHeadline(rawHeadline);
        $('.js-root', $element).html(parsedHeadline);
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
              $container.contentUpgradeOfferPreview('update', options.defaultModel);
            }, 1);
          });
        },
        destroy: function () {
          return this.each(function () {
            $(this).empty();
          });
        },
        update: function (model) {
          return this.each(function () {
            updateElement($(this), model);
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

      function updateElement($element, model) {
        $('.caption', $element).text(getFromModel($element, model, 'caption'));
        $('.headline', $element).text(getFromModel($element, model, 'headline'));
        $('.name', $element).attr('placeholder', getFromModel($element, model, 'namePlaceholder'));
        $('.email', $element).attr('placeholder', getFromModel($element, model, 'emailPlaceholder'));
        $('.cta', $element).text(getFromModel($element, model, 'cta'));
        $('.spam-disclaimer', $element).text(getFromModel($element, model, 'spamDisclaimer'));
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
              $container.contentUpgradeModalPreview('update', options.defaultModel);
            }, 1);
          });
        },
        destroy: function () {
          return this.each(function () {
            $(this).empty();
          });
        },
        update: function (model) {
          return this.each(function () {
            updateElement($(this), model);
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