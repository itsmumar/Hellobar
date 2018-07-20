$ ->
  setTimeout ( ->
    $('.flash-block').addClass('show')
  ), 300

  $(document).on 'click', '.flash-block .icon-close', (event) ->
    flash = $(event.currentTarget).parent('.flash-block')
    flash.removeClass('show')
    setTimeout ( ->
      flash.remove()
    ), 500


@displayFlashMessage = (message, type = 'success') ->
  div = $('<div class="flash-block"><i class="icon-close"></i></div>')
  div.addClass(type).append(message).prependTo($('.global-content'))
  setTimeout ( ->
    div.addClass('show')
  ), 100
  setTimeout ( ->
    div.removeClass('show')
  ), 5000

@displayAlert = (type, message) ->
  configToastr
  if type == 'notice'
    type = 'info'
  else if type == 'alert'
    type = 'warning'
  toastr[type] message
  return

@configToastr = () ->
  toastr.options = {
    "closeButton": true,
    "debug": false,
    "progressBar": true,
    "positionClass": "toast-top-right",
    "showDuration": "300",
    "hideDuration": "1000",
    "timeOut": "5000",
    "extendedTimeOut": "1000",
    "showEasing": "swing",
    "hideEasing": "linear",
    "showMethod": "fadeIn",
    "hideMethod": "fadeOut"
  };