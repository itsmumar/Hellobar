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
    switch $(@).attr('data-chart')
      when 'views'    then new ViewsChart()
      when 'emails'   then new EmailsChart()
      when 'clicks'   then new ClicksChart()
      when 'social'   then new SocialChart()
      when 'feedback' then new FeedbackChart()

  # Trigger default chart when applicatble
  $('.chart-wrapper .chart-block').first().trigger('click') if $('.chart-wrapper .chart-block').length 