Handlebars.registerHelper 'rule-option', (method, value, text) ->
  $option = $('<option>')
  $option.val(value)
         .text(text)
  $option.attr('selected', 'selected') if method == value

  new Handlebars.SafeString($option.prop('outerHTML'))

Handlebars.registerHelper 'image-path', (image) ->
  new Handlebars.SafeString(window.image_path(image))

Handlebars.registerHelper 'toArray', (item) ->
  if typeof item == "object"
    return item
  else
    return [item]
