#= require hellobar.base

module 'hellobar_base',
  teardown: ->
    ok (new Date()).getUTCFullYear() > 2013, "clock was not restored using sinon"

# you can't easily create a date in a specific timezone.
localMillenium = -> new Date(2000, 0, 1)
currentTestBrowserOffset = (date=new Date) -> date.getTimezoneOffset()
adjustedOffset = (hours, date=new Date) -> Math.abs(date.getTimezoneOffset() - (Math.floor(hours) * 60))
utcMillenium = -> new Date(localMillenium().getTime() - ( currentTestBrowserOffset(localMillenium()) * 60000))

test 'zeropad behaves correctly', ->
  equal _HB.zeropad("5"), "05"
  equal _HB.zeropad(5), "05"
