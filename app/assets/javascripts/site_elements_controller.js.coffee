$ ->

  # filter the site elements on the page
  $('body').on 'click', 'a.element-filter', (event) ->
    event.preventDefault()
    $anchor = $(this)
    href = $anchor.attr('href')

    # unset the current active filter
    $('a.element-filter').removeClass('active')

    if href == '#active'
      $('tr.site-element-block:not(.active)').hide()
      $('tr.site-element-block.active').show()
    else if href == '#paused'
      $('tr.site-element-block:not(.paused)').hide()
      $('tr.site-element-block.paused').show()
    else if href == '#all'
      $('tr.site-element-block').show()

    # set the current active anchor
    $anchor.addClass('active')

  # open the rule modal
  $('body').on 'click', '.edit-rule', (event) ->
    event.preventDefault()

    ruleJson = null
    ruleId = $(this).data('rule-id')

    for rule in window.rules
      ruleJson = rule if rule.id == ruleId

    ruleJson.siteId = window.siteID

    console.log "Couldnt find rule with ID: #{ruleId}" unless ruleJson

    options =
      ruleData: ruleJson
      successCallback: ->
        $ruleContent = $(".rule-block[data-rule-id=#{@id}]")
        $ruleContent.find("h4").text(@name)
        $ruleContent.find("span.rule-description").text(@description)

        ruleIds = window.rules.map (rule) -> rule.id

        if ruleIds.indexOf(@id) == -1 # we created the rule
          window.rules.push this
        else # we updated the rule
          window.rules[ruleIds.indexOf(@id)] = this

    new RuleModal(options).open()

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

  # send a request to delete the rule itself, let Rails
  # delete the children objects but remove entire
  # DOM object
  $('body').on 'click', '.remove-rule', (event) ->
    event.preventDefault()

    $rule = $(this).parents('tr')
    ruleId = $rule.data('rule-id')
    $siteElements = $rule.siblings("[data-rule-id=#{ruleId}]")

    # assume a successful delete
    $rule.hide()
    $siteElements.hide()

    $.ajax
      contentType: "text/javascript"
      type: 'DELETE'
      url: "/sites/#{window.siteID}/rules/#{ruleId}"
      error: (xhr, status, error) ->
        $rule.show()
        $siteElements.show()
        console.log "Error removing rule #{ruleId}: #{error}"

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
    ruleId = $(this).data('rule-id')
    $rule = $row.siblings(".rule-block[data-rule-id=#{ruleId}]")
    $elementCount = $rule.find('a.remove-rule span')
    newValue = parseInt($elementCount.text()) - 1
    $elementCount.text(newValue) # FIXME: does not handle "bar/s" pluralization when 0 or 1 element

    $.ajax
      contentType: "text/javascript"
      type: 'DELETE'
      url: "/sites/#{siteId}/site_elements/#{elementId}/"
      error: (xhr, status, error) ->
        $row.show()
        originalValue = parseInt($count.text()) + 1
        $elementCount.text(originalValue)
        console.log "Error removing site element: #{error}"
