Handlebars.registerHelper 'option', (method, value, text) ->
  $option = $('<option>')
  $option.val(value)
         .text(text)
  $option.attr('selected', 'selected') if method == value

  new Handlebars.SafeString($option.prop('outerHTML'))

Handlebars.registerHelper 'image-path', (image) ->
  new Handlebars.SafeString(window.image_path(image))
