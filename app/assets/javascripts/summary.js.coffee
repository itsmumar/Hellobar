AmCharts.ready ->

  if $('.statistics-page').length
    CE_SNAPSHOT_NAME="summary"

  # Render appropriate chart on click
  $('body').on 'click', '.chart-block[data-chart]:not(.activated)', (event) ->
    # Don't allow clicking during loading
    return false if $('#amchart').hasClass('loading')

    # Set up charting canvas (if it doesn't exist)
    $(@).parent().after('<div id="amchart"></div>') unless $('#amchart').length

    # Toggle activated state
    $(@).parent().find('.activated').removeClass('activated')
    $(@).addClass('activated')

    # Render appropriate chart
    siteID = $(@).attr('data-site-id')
    numDays = $(@).attr('data-num-days')

    window.CurrentChart = $(this).attr('data-chart')

    UrlParams.updateParam('chart', window.CurrentChart)
    $(".suggestions-wrapper").hide()
    $(".top-performers-wrapper").hide()

    switch window.CurrentChart
      when "views"
        new ViewsChart({siteID, numDays})
        $(".suggestions-wrapper.all").show()
        $(".top-performers-wrapper.all").show()
      when "emails"
        new EmailsChart({siteID, numDays})
        $(".suggestions-wrapper.email").show()
        $(".top-performers-wrapper.email").show()
      when "clicks"
        new ClicksChart({siteID, numDays})
        $(".suggestions-wrapper.traffic").show()
        $(".top-performers-wrapper.traffic").show()
      when "social"
        new SocialChart({siteID, numDays})
        $(".suggestions-wrapper.social").show()
        $(".top-performers-wrapper.social").show()

  # Trigger current chart or default when applicatble
  if $('.chart-wrapper .chart-block').length && typeof(window.CurrentChart) == "undefined"
    $(".chart-wrapper .chart-block").first().click()
  else
    $(".chart-wrapper .chart-block.#{CurrentChart}").click()

  $('body').on 'click', '.view-more a', (event) ->
    event.preventDefault()

    window.location = "#{event.target.href}?chart=#{window.CurrentChart}"

$ ->
  window.CurrentChart = UrlParams.fetch('chart')

  switch UrlParams.fetch("chart")
    when "emails"
      $(".suggestions-wrapper.email").show()
      $(".top-performers-wrapper.email").show()
    when "clicks"
      $(".suggestions-wrapper.traffic").show()
      $(".top-performers-wrapper.traffic").show()
    when "social"
      $(".suggestions-wrapper.social").show()
      $(".top-performers-wrapper.social").show()
    else
      $(".suggestions-wrapper.all").show()
      $(".top-performers-wrapper.all").show()
