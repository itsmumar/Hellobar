$ ->

  $('body').on 'click', '.edit-rule', (event) ->
    event.preventDefault()

    ruleId = $(this).attr('data-rule-id')
    $form = $("form#rule-#{ruleId}")
    $modal = $form.parents('.modal-wrapper:first')

    options =
      successCallback: ->
        $(".rule##{@id}").text("Rule set: #{@name}")

    new RuleModal($modal, options).open()

  # toggle pause / unpause
  $('body').on 'click', '.toggle-pause', (event) ->
    event.preventDefault()

    $element = $(this)
    $row = $element.parents('tr')

    siteId = $element.attr('data-site-id')
    elementId = $element.attr('data-element-id')

    # assume successful change for faster user feedback
    if $row.hasClass('paused')
      $row.removeClass('paused')
      $element.html('<i class="icon-edit"></i>Pause')
    else
      $row.addClass('paused')
      $element.html('<i class="icon-edit"></i>Unpause')

    $.ajax
      type: 'PUT'
      url: "/sites/#{siteId}/site_elements/#{elementId}/toggle_paused"
      error: (xhr, status, error) ->
        # toggle the class and text back to original and render any error
        console.log "Unexepcted error: #{error}"
