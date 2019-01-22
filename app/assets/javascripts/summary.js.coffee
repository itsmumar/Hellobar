startDate = moment().subtract(29, 'days').format('YYYY-MM-DD')
endDate = moment().format('YYYY-MM-DD')

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
    $(".top-performers-wrapper").hide()

    switch window.CurrentChart
      when "views"
        new ViewsChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.all").show()
      when "emails"
        new EmailsChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.email").show()
      when "clicks"
        new ClicksChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.traffic").show()
      when "social"
        new SocialChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.social").show()
      when "calls"
        new CallsChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.call").show()

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
      $(".top-performers-wrapper.email").show()
    when "clicks"
      $(".top-performers-wrapper.traffic").show()
    when "social"
      $(".top-performers-wrapper.social").show()
    when "calls"
      $(".suggestions-wrapper.calls").show()
      $(".top-performers-wrapper.calls").show()
    else
      $(".top-performers-wrapper.all").show()

  callback = () ->
    $('#reportrange span').html (moment(startDate)).format('MMMM D, YYYY') + ' - ' + (moment(endDate)).format('MMMM D, YYYY')
    return false if $('#amchart').hasClass('loading')

    # Set up charting canvas (if it doesn't exist)
    $(@).parent().after('<div id="amchart"></div>') unless $('#amchart').length

    # Toggle activated state
    $(@).parent().find('.activated').removeClass('activated')
    $(@).addClass('activated')

    # Render appropriate chart
    numDays = $(@).attr('data-num-days')

    UrlParams.updateParam('chart', UrlParams.fetch('chart'))
    $(".top-performers-wrapper").hide()

    switch window.CurrentChart
      when "views"
        new ViewsChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.all").show()
      when "emails"
        new EmailsChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.email").show()
      when "clicks"
        new ClicksChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.traffic").show()
      when "social"
        new SocialChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.social").show()
      when "calls"
        new CallsChart({siteID, numDays, startDate, endDate})
        $(".top-performers-wrapper.call").show()
    return

  if $('#reportrange').length > 0
    $('#reportrange').daterangepicker {
      startDate: moment().subtract(29, 'days')
      endDate: moment()
      ranges:
        'Last 7 Days': [
          moment().subtract(6, 'days')
          moment()
        ]
        'Last 30 Days': [
          moment().subtract(29, 'days')
          moment()
        ]
        'This Month': [
          moment().startOf('month')
          moment().endOf('month')
        ]
        'Last Month': [
          moment().subtract(1, 'month').startOf('month')
          moment().subtract(1, 'month').endOf('month')
        ]
    }

    $('#reportrange').on 'apply.daterangepicker', (ev, picker) ->
      startDate = picker.startDate.format('YYYY-MM-DD')
      endDate = picker.endDate.format('YYYY-MM-DD')
      callback()

    $('#reportrange span').html (moment(startDate)).format('MMMM D, YYYY') + ' - ' + (moment(endDate)).format('MMMM D, YYYY')
    return
