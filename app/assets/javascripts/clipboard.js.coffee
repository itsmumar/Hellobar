$ () ->
  $('[data-clipboard-target]').on 'click', (e) =>
    e.preventDefault()

    button = $(e.target).closest('[data-clipboard-target]')
    target = $(button.data('clipboard-target'))[0]

    return unless target

    target.select()
    document.execCommand('copy')

    if window.getSelection
      window.getSelection().removeAllRanges()
    else if document.selection
      document.selection.empty()

    displayFlashMessage('Copied!')
