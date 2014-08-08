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

test 'comparableDates are fully sortable with a plain Array.sort()', ->
  correct = [ '2001/01/01 +06:15', '2002/08/02 +04:00', '2002/08/02 +12:00',
              '2003/01/01 +06:15', '2003/01/01 +09:15', '2003/01/02 +00:00' ]

  testOrder = [ '2003/01/02 +00:00', '2003/01/01 +09:15', '2002/08/02 +04:00',
                '2003/01/01 +06:15', '2001/01/01 +06:15', '2002/08/02 +12:00' ]

  deepEqual testOrder.sort(), correct, "Array.sort didn't work"

test 'comparableDates will compare to dates without timezones', ->
  clock = sinon.useFakeTimers(utcMillenium().getTime())

  # Again, we cannot manually change the test browser's offset.
  if currentTestBrowserOffset() > 0
    baselineDate = "1999/12/31"
    nextDate = "2000/01/01"
  else
    baselineDate = "2000/01/01"
    nextDate = "2000/01/02"

  strictEqual _HB.comparableDate('auto'), baselineDate, "Auto mode should leave offset off"

  ok _HB.comparableDate('auto') >= baselineDate, "We're already on the baseline date"
  ok _HB.comparableDate('auto') < nextDate, "We are not yet on the next day"

  ok !(_HB.comparableDate('auto') >= nextDate), "We are not yet past the next date (nor on it)"
  ok !(_HB.comparableDate('auto') < baselineDate), "We are not less than the base date (we are on it)"

  clock.restore()

test 'comparableDate works right', ->
  clock = sinon.useFakeTimers(utcMillenium().getTime())

  # only positive offsets allowed now
  equal _HB.comparableDate(+6).split('+')[1], "#{_HB.zeropad(adjustedOffset(6)/60)}:00"
  equal _HB.comparableDate(+18).split('+')[1], "#{_HB.zeropad(adjustedOffset(18)/60)}:00"
  equal _HB.comparableDate(+18.5).split('+')[1], "#{_HB.zeropad(adjustedOffset(18.5)/60)}:30", "#{_HB.comparableDate(18.5).split('+')[1]} wasn't #{_HB.zeropad(adjustedOffset(18.5)/60)}:30"

  clock.restore()
