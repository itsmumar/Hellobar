$ ->

  # Remove Flash Messsages
  if $('.flash-block').length
    setTimeout ( ->
      $('.flash-block').addClass('show')
    ), 300

    $('.flash-block .icon-close').click (event) ->
      flash = $(event.currentTarget).parent('.flash-block')
      flash.removeClass('show')
      setTimeout ( ->
        flash.remove()
      ), 500
