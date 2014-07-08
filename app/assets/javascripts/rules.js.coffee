$ ->
  $('body').on 'click', '.edit-rule', (event) ->
    ruleId = $(this).attr('data-rule-id')
    form = $("form#rule-" + ruleId)
    modal = form.parents('.modal-wrapper:first')
    modal.addClass('show-modal')

    $(document).on 'keyup', (event) ->
      if event.keyCode == 27
        $('.modal-wrapper.show-modal').removeClass('show-modal')

    # bind to the + and - conditions
