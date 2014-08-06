class @Chart

  constructor: ->
    @_setupChart()
    @_fetchData()

  _setupChart: ->
    @$el = $('#amchart')
    @$el.removeClass().addClass(@type + ' loading')

  _fetchData: ->
    # ----- FIXTURES (remove when live) -----
    unless @url
      setTimeout ( =>
        if Math.random() >= 0.1
          @_renderData(@_fixtureData())
        else        
          @_failedAttempt()
        @$el.removeClass('loading')
      ), 2000
      return false
    # ----- END FIXTURES -----

    $.ajax(@url)
      .done(@_renderData(data))
      .fail(@_failedAttempt(data))
      .always =>
        @$el.removeClass('loading')

  _renderData: (data) ->
    @chart = AmCharts.makeChart "amchart",
      type: "serial"
      theme: "none"
      colors: [@color]
      dataProvider: data
      categoryField: "date"
      fontFamily: "Open Sans"
      autoMargins: false
      marginBottom: 40
      marginRight: 25
      marginLeft: 60
      marginTop: 25

      graphs: [
        id: "g1"
        bullet: "round"
        lineThickness: 2
        valueField: "value"
        type: "smoothedLine"
        bulletBorderAlpha: 1
        hideBulletsCount: 50
        bulletColor: "#FFFFFF"
        useLineColorForBulletBorder: true
        balloonText: "<i class='#{@icon}'></i> [[value]] #{@text}"
      ]

      balloon:
        color: '#ffffff'
        offsetY: 40
        fontSize: 12
        fillAlpha: 1
        shadowAlpha: 0
        fillColor: @color
        borderThickness: 0
        verticalPadding: 5
        fixedPosition: true
        animationDuration: 0
        horizontalPadding: 10

      categoryAxis:
        dashLength: 1
        tickLength: 0
        color: "#c6c6c6"
        axisThickness: 2
        gridColor: "#f6f6f6"
        axisColor: "#c6c6c6"

      valueAxes: [
        gridAlpha: 1
        tickLength: 0
        color: "#c6c6c6"
        position: "left"
        gridThickness: 1
        axisThickness: 0
        gridColor: "#f6f6f6"
        showFirstLabel: false
      ]

  _failedAttempt: ->
    @$el.addClass('failed')

  # ----- FIXTURES (remove when live) -----
  _fixtureData: ->
    data = []
    for i in [8..0] by -1
      min = 250*(9-i)
      max = 1000*(9-i) 
      
      data.push
        date: moment().clone().subtract('days', i).format('ddd')
        value: Math.floor(Math.random() * (max - min)) + min

    return data
  # ----- END FIXTURES -----
