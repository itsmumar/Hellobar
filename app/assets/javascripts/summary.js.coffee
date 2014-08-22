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
    switch $(@).attr('data-chart')
      when 'views'    then new ViewsChart(siteID: siteID)
      when 'emails'   then new EmailsChart(siteID: siteID)
      when 'clicks'   then new ClicksChart(siteID: siteID)
      when 'social'   then new SocialChart(siteID: siteID)
      when 'feedback' then new FeedbackChart(siteID: siteID)

  # Trigger default chart when applicatble
  $('.chart-wrapper .chart-block').first().trigger('click') if $('.chart-wrapper .chart-block').length 
