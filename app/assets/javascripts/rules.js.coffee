$ ->
  
  $('body').on 'click', '.edit-rule', (event) ->
    ruleId = $(this).attr('data-rule-id')
    $form = $("form#rule-#{ruleId}")
    $modal = $form.parents('.modal-wrapper:first')

    options =
      successCallback: ->
        $(".rule##{@id}").text("Rule set: #{@name}")

    new RuleModal($modal, options).open()
