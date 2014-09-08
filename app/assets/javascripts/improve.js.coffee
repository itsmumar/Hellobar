$ ->
  calculateConversionLift = (select) ->
    select = $(select)
    tr = select.closest("tr")

    views = tr.data("views")
    conversions = tr.data("conversions")
    lift = parseInt(select.val()) / 100.0

    # how are these element currently converting?
    conversionRate = conversions * 1.0 / views

    # what new conversion rate do we want to simulate?
    newConversionRate = conversionRate * (1 + lift)

    # how many additional conversions would they get at the higher rate?
    newConversions = parseInt(views * newConversionRate) - conversions

    tr.find("span.calculator-results").html(newConversions)

  $("tr.improve-calculator select").each ->
    calculateConversionLift(this)

  $("tr.improve-calculator select").change (e) ->
    calculateConversionLift(e.target)
