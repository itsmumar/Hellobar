displayAlert = (type, message) ->
  if type == 'notice'
    type = 'info'
  else if type == 'alert'
    type = 'warning'
  window['toastr.' + type] message
  return
