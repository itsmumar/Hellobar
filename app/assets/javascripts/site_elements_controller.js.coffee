$ ->
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

  setFilter = (type) ->
    typeClass = type.replace('#', 'is-')
    $('.rules-wrapper tbody').removeClass().addClass(typeClass)

  checkPaused = (rule_id) ->
    # Find the number of active and paused bars for this rule
    activeBarCount = $(".site-element-block.active[data-rule-id='#{rule_id}']").length
    pausedBarCount = $(".site-element-block.paused[data-rule-id='#{rule_id}']").length

    # Find the total number of active and paused bars across all rules
    allActiveBarsCount = $("tr.site-element-block.active").length
    allPausedBarsCount = $("tr.site-element-block.paused").length

    # The table rows for this rule
    ruleBlocks = $("tr[data-rule-id='#{rule_id}']").not(".site-element-block")

    ruleBlocks.removeClass('active paused')

    if activeBarCount == 0
      ruleBlocks.addClass('paused')
    else if pausedBarCount == 0
      ruleBlocks.addClass('active')

    if allActiveBarsCount == 0
      $("#paused-guidance").css({ display: "" });
      $("#active-guidance").hide();
    else if allPausedBarsCount == 0
      $("#paused-guidance").hide();
      $("#active-guidance").css({ display: "" });
    else
      $("#paused-guidance").hide();
      $("#active-guidance").hide();

  removeRow = (row) ->
    row.css({height: 0})
       .children('td, th')
       .animate({padding: 0})
       .wrapInner('<div style="overflow: hidden; height: 4rem;"></div>')
       .children().animate({height: 0}, 500, -> $(@).closest('tr').remove())

  recountDeletionString = (ruleId) ->
    $rule = $(".rule-block[data-rule-id=#{ruleId}]")
    $ruleDeleteElem = $rule.find('a.remove-rule')
    elementCount = parseInt($ruleDeleteElem.find('span').text())

    newString = switch
      when elementCount > 2 then "<i class='icon-trash'></i>Delete this and <span>#{elementCount-1}</span> bars"
      when elementCount == 2 then "<i class='icon-trash'></i>Delete this and <span>1</span> bar"
      else "<i class='icon-trash'></i>Delete this rule"

    $ruleDeleteElem.html(newString)

  #-----------  Filter Site Elemtents  -----------#

  $('body').on 'click', 'a.element-filter', (event) ->
    event.preventDefault()

    $anchor = $(this)
    currentFilter = $anchor.attr('href')

    $('a.element-filter').removeClass('active')
    $anchor.addClass('active')

    setFilter(currentFilter)

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

    # assume successful change for faster user feedback
    if $row.hasClass('paused')
      $row.removeClass('paused').addClass('active')
      $element.html('<i class="icon-pause"></i>Pause')
    else
      $row.addClass('paused').removeClass('active')
      $element.html('<i class="icon-play"></i>Unpause')

    # check if all are paused
    checkPaused $row.data('rule-id')

    $.ajax
      type: 'PUT'
      url: "/sites/#{siteID}/site_elements/#{elementId}/toggle_paused"
      error: (xhr, status, error) ->
        # toggle the class and text back to original and render any error
        console.log "Unexepcted error: #{error}"

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

    # check if all are paused
    checkPaused $row.data('rule-id')

    $.ajax
      contentType: "text/javascript"
      type: 'DELETE'
      url: "/sites/#{siteID}/site_elements/#{elementId}/"
      success: (xhr, status) ->
        removeRow($row)
        recountDeletionString($row.data('rule-id'))
      error: (xhr, status, error) ->
        $row.removeClass('deleting')
        console.log "Error removing site element: #{error}"

  #-----------  View Paused Bars  -----------#

  $('body').on 'click', '#paused-guidance a', (event) ->
    $('a.element-filter').removeClass('active')
    $('a.element-filter[href="#paused"]').addClass('active')
    setFilter('#paused')

  $('body').on 'click', '#active-guidance a', (event) ->
    $('a.element-filter').removeClass('active')
    $('a.element-filter[href="#active"]').addClass('active')
    setFilter('#active')

  #-----------  Render elements for default filter  -----------#

  currentFilter = $('nav.tabs-wrapper .element-filter.active').attr('href')
  setFilter(currentFilter) if currentFilter

  $('.rules-wrapper .rule-block').each (index, rule) ->
    checkPaused $(rule).data('rule-id')

  # On page load, see if they were linked to a particular bar
  window_anchor = window.location.hash
  if window_anchor
    highlightBar(window_anchor)
