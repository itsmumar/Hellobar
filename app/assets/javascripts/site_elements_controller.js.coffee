$ ->
  # prevent this script from executing on other pages
  return unless $("#site_elements-index").length > 0

  highlightBar = (elementId) ->
    # Add the highlight animation to the bar
    bar = $(elementId)
    bar.addClass("flash")

    # Remove the flash after a period of time to ensure it doesn't flash
    # again while toggling between paused and unpaused
    removeFlash = -> bar.removeClass("flash")
    setTimeout removeFlash, 2000

    # If the bar is paused, trigger the "view paused" functionality
    if bar.hasClass( "paused" )
      $("#paused-guidance a").trigger("click")

  #-----------  Show elements of currently active tab  -----------#

  renderBars = ->
    hideSpacers()
    active = currentSelection()
    if $(".site-element-block").length == 0
      active = null

    for i, rule of rules()
      showRule(rule)
      updateRuleLinks(rule)
      showBars = []
      for bar in rule.site_elements
        bar = $(bar)
        bar.hide()
        showBars.push(bar) if active == null || bar.data('active') == active

      if showBars.length == 0 && active != null
        hideRule(rule)
      for bar, k in showBars
        nextBar = showBars[k+1]
        if nextBar && (bar.data('type') != nextBar.data('type'))
          $("<tr class='spacer'>").insertAfter(bar)
        bar.show()
        bar.removeClass("active paused").addClass(if bar.data('active') then "active" else "paused")

    renderGuidance(active)

  hideSpacers = ->
    $('tr.spacer').remove()

  renderGuidance = (active) ->
    $("#active-guidance").hide()
    $("#paused-guidance").hide()
    return if active == null

    if active && $(".site-element-block").filter((index) -> $(@).data('active')).length == 0
      $("#paused-guidance").show()
    else if active == false && $(".site-element-block").filter((index) -> $(@).data('active') == false).length == 0
      $("#active-guidance").show()

  hideRule = (rule) ->
    $("tr[data-rule-id='#{rule.id}']").hide()

  showRule = (rule) ->
    $("tr[data-rule-id='#{rule.id}']").show()

  removeRow = (row) ->
    if $('.site-element-block:not(.deleting)').length < $('[data-max-site-elements]').data('max-site-elements')
      $('[data-prompt-upgrade]').data('prompt-upgrade', false)

    row.css({height: 0})
       .children('td, th')
       .animate({padding: 0})
       .wrapInner('<div style="overflow: hidden; height: 4rem;"></div>')
       .children().animate({height: 0}, 500, ->
         $(@).closest('tr').remove()
         renderBars()
        )

  #-----------  Filter Site Elements  -----------#

  $('body').on 'click', 'a.element-filter', (event) ->
    event.preventDefault()

    $('a.element-filter').removeClass('active')
    $(this).addClass('active')

    renderBars()

  #-----------  Open Rules Modal  -----------#

  $('body').on 'click', '.edit-rule', (event) ->
    event.preventDefault()

    unless $(event.currentTarget).data("can-edit")
      return new UpgradeAccountModal({site: window.site, upgradeBenefit: "create custom-targeted rules"}).open()

    ruleJson = null
    ruleId = $(this).data('rule-id')

    for rule in window.rules
      ruleJson = rule if rule.id == ruleId

    ruleJson.siteID = window.siteID

    console.log "Couldnt find rule with ID: #{ruleId}" unless ruleJson

    options =
      ruleData: ruleJson
      successCallback: ->
        $ruleContent = $(".rule-block[data-rule-id=#{@id}]")
        $ruleContent.find("h4").text(@name)
        $ruleContent.find(".rule-description span").text(@description)

        ruleIds = window.rules.map (rule) -> rule.id

        if ruleIds.indexOf(@id) == -1 # we created the rule
          window.rules.push this
        else # we updated the rule
          window.rules[ruleIds.indexOf(@id)] = this

    new RuleModal(options).open()

  #-----------  Toggle Pause/Unpause  -----------#

  $('body').on 'click', '.toggle-pause', (event) ->
    event.preventDefault()

    $element = $(this)
    $row = $element.parents('tr')
    siteID = $element.attr('data-site-id')
    elementId = $element.attr('data-element-id')

    $row.data('active', !$row.data('active'))

    # assume successful change for faster user feedback
    if $row.data('active')
      $element.html('<i class="icon-pause"></i>Pause')
    else
      $element.html('<i class="icon-play"></i>Unpause')

    renderBars()

    $.ajax
      type: 'PUT'
      url: "/sites/#{siteID}/site_elements/#{elementId}/toggle_paused"
      error: (xhr, status, error) ->
        # toggle the class and text back to original and render any error
        console.log "Unexpected error: #{error}"

  #-----------  Delete Rule  -----------#

  # send a request to delete the rule itself, let Rails
  # delete the children objects but remove entire
  # DOM object

  $('body').on 'click', '.remove-rule', (event) ->
    event.preventDefault()

    $rule = $(this).parents('tr')
    ruleId = $rule.data('rule-id')
    $siteElements = $rule.siblings("[data-rule-id=#{ruleId}]")

    $siteElements.addClass('deleting')

    $.ajax
      contentType: "text/javascript"
      type: 'DELETE'
      url: "/sites/#{window.siteID}/rules/#{ruleId}"
      success: (xhr, status) ->
        removeRow($rule)
        for row in $siteElements
          removeRow($(row))
      error: (xhr, status, error) ->
        $siteElements.removeClass('deleting')
        console.log "Error removing rule #{ruleId}: #{error}"

  #-----------  Delete Site Element  -----------#

  $('body').on 'click', '.delete-element', (event) ->
    event.preventDefault()

    $element = $(this)
    $row = $element.parents('tr')
    siteID = $element.attr('data-site-id')
    elementId = $element.attr('data-element-id')

    $row.addClass('deleting')

    $.ajax
      contentType: "text/javascript"
      type: 'DELETE'
      url: "/sites/#{siteID}/site_elements/#{elementId}/"
      success: (xhr, status) ->
        removeRow($row)
      error: (xhr, status, error) ->
        $row.removeClass('deleting')
        console.log "Error removing site element: #{error}"

  # Returns the currently active tab
  # active = true, paused = false, all = null
  currentSelection = ->
    target = $('a.element-filter.active').attr('href')
    selection = target && target.replace(/\W/g, '')
    return null if selection == "all"
    selection == "active"

  rules = ->
    result = []
    $('.rules-wrapper .rule-block').each (index, rule) ->
      id = $(rule).data('rule-id')
      result.push({
        element: $(rule),
        id: id,
        site_elements: $(".site-element-block[data-rule-id=#{id}]")
      })
    result

  updateRuleLinks = (rule) ->
    suggestions = $(".rules-wrapper [data-rule-id=#{rule.id}] > .suggestion-block")

    if rule.site_elements.length == 0
      suggestions.children("[data-display-when=empty]").show()
      suggestions.children("[data-display-when=any]").hide()
    else
      suggestions.children("[data-display-when=empty]").hide()
      suggestions.children("[data-display-when=any]").show()

  #-----------  View Paused Bars  -----------#

  $('body').on 'click', '#paused-guidance a', (event) ->
    $('a.element-filter').removeClass('active')
    $('a.element-filter[href="#paused"]').addClass('active')
    renderBars()

  $('body').on 'click', '#active-guidance a', (event) ->
    $('a.element-filter').removeClass('active')
    $('a.element-filter[href="#active"]').addClass('active')
    renderBars()

  renderBars()
  # On page load, see if they were linked to a particular bar
  window_anchor = window.location.hash
  if window_anchor
    highlightBar(window_anchor)
