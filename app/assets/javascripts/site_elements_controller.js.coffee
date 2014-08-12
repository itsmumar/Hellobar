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

  # delete site element
  $('body').on 'click', '.delete-element', (event) ->
    event.preventDefault()

    $element = $(this)
    $row = $element.parents('tr')
    siteId = $element.attr('data-site-id')
    elementId = $element.attr('data-element-id')
    $row.hide()
    # REFACTOR
    # traversing the DOM like this is asinine. There should be an object that we
    # can just update & query against to tell us how many rules there are.
    $elementCount = $element.parents('table').find('a.remove-rule span')
    newValue = parseInt($elementCount.text()) - 1
    $elementCount.text(newValue)

    $.ajax
      contentType: "text/javascript"
      type: 'DELETE'
      url: "/sites/#{siteId}/site_elements/#{elementId}/"
      error: (xhr, status, error) ->
        $row.show()
        originalValue = parseInt($count.text()) + 1
        $elementCount.text(originalValue)
        console.log "Error removing site element: #{error}"
