$ ->

  renderElements = (type) ->
    if type == '#active'
      $('tr.site-element-block:not(.active)').hide()
      $('tr.site-element-block.active').show()
    else if type == '#paused'
      $('tr.site-element-block:not(.paused)').hide()
      $('tr.site-element-block.paused').show()
    else if type == '#all'
      $('tr.site-element-block').show()

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
    href = $anchor.attr('href')

    # unset the current active filter
    $('a.element-filter').removeClass('active')

    renderElements(href)

    # set the current active anchor
    $anchor.addClass('active')

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
        $ruleContent.find("span.rule-description").text(@description)

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
      $row.removeClass('paused')
      $row.addClass('active')
      $element.html('<i class="icon-pause"></i>Pause')
    else
      $row.addClass('paused')
      $row.removeClass('active')
      $element.html('<i class="icon-play"></i>Unpause')

    currentFilter = $('nav.tabs-wrapper .element-filter.active')
    renderElements(currentFilter.attr('href'))

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

  #-----------  Render elements for default filter  -----------#

  currentFilter = $('nav.tabs-wrapper .element-filter.active')
  renderElements(currentFilter.attr('href'))
