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

    switch $(@).attr('data-chart')
      when 'views'    then new ViewsChart({siteID, numDays})
      when 'emails'   then new EmailsChart({siteID, numDays})
      when 'clicks'   then new ClicksChart({siteID, numDays})
      when 'social'   then new SocialChart({siteID, numDays})
      when 'feedback' then new FeedbackChart({siteID, numDays})

  # Trigger default chart when applicatble
  $('.chart-wrapper .chart-block').first().trigger('click') if $('.chart-wrapper .chart-block').length
