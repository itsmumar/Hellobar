AmCharts.ready ->

  # Render appropriate chart on click
  $('body').on 'click', '.chart-block[data-chart]:not(.activated)', (event) ->
    # Don't allow clikcing during loading
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

    switch window.CurrentChart
      when 'views'    then new ViewsChart({siteID, numDays})
      when 'emails'   then new EmailsChart({siteID, numDays})
      when 'clicks'   then new ClicksChart({siteID, numDays})
      when 'social'   then new SocialChart({siteID, numDays})
      when 'feedback' then new FeedbackChart({siteID, numDays})

  # Trigger current chart or default when applicatble
  if $('.chart-wrapper .chart-block').length && typeof(window.CurrentChart) == "undefined"
    $(".chart-wrapper .chart-block").first().click()
  else
    $(".chart-wrapper .chart-block.#{CurrentChart}").click()

  $('body').on 'click', '.view-more', (event) ->
    event.preventDefault()

    window.location = "#{event.target.href}?chart=#{window.CurrentChart}"

$ ->
  window.CurrentChart = UrlParams.fetch('chart')
