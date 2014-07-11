$ ->
  $('body').on 'click', '.edit-rule', (event) ->
    ruleId = $(this).attr('data-rule-id')
    $form = $("form#rule-#{ruleId}")
    $modal = $form.parents('.modal-wrapper:first')

    new RuleModal($modal).open()
