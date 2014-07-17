#= require hellobar.base

module 'hellobar_base',
  teardown: ->
    ok (new Date()).getUTCFullYear() > 2013, "clock was not restored using sinon"

# you can't easily create a date in a specific timezone.
localMillenium = -> new Date(2000, 0, 1)
currentTestBrowserOffset = (date=new Date) -> date.getTimezoneOffset()
utcMillenium = -> new Date(localMillenium().getTime() - ( currentTestBrowserOffset(localMillenium()) * 60000))

test 'idl dates string representation is what is expected', ->
  clock = sinon.useFakeTimers(utcMillenium().getTime())

  now = new Date()
  y = now.getUTCFullYear()
  m = _HB.zeropad(now.getUTCMonth()+1)
  d = _HB.zeropad(now.getUTCDate())
  utcStringDate = "#{y}/#{m}/#{d} +#{_HB.comparableOffset()}"
  strictEqual _HB.comparableDate(), utcStringDate, "#{_HB.comparableDate()} and #{utcStringDate} dates aren't equal"

  clock.restore()

test 'dates string representation lacks bang before midnight', ->
  currentOffset = _HB.comparableOffset currentTestBrowserOffset(localMillenium())

  clock = sinon.useFakeTimers(localMillenium().getTime())
  strictEqual _HB.comparableDate(), "2000/01/01 +#{currentOffset}!", "#{_HB.comparableDate()} did not have bang"
  oneHourBefore = new Date( localMillenium().getTime() - (60000 * 60))
  clock.restore()

  clock = sinon.useFakeTimers(oneHourBefore.getTime())
  strictEqual _HB.comparableDate(), "2000/01/01 +#{currentOffset}", "#{_HB.comparableDate()} #{currentOffset}" # does not have bang
  clock.restore()

test 'comparableDate can be compared with GMT', ->
  clock = sinon.useFakeTimers(utcMillenium().getTime())

  dateString = _HB.comparableDate()
  currentOffset = _HB.comparableOffset currentTestBrowserOffset()
  strictEqual dateString, "2000/01/01 +#{currentOffset}", "#{dateString} was unexpected"

  clock.restore()
  
test 'zeropad behaves correctly', ->
  equal _HB.zeropad("5"), "05"
  equal _HB.zeropad(5), "05"

test 'comparableDates are fully sortable with a plain Array.sort()', ->
  correct = [ '2001/01/01 +06.25', '2002/08/02 +04.00', '2002/08/02 +12.00',
              '2003/01/01 +06.25', '2003/01/01 +09.25', '2003/01/02 +00.00' ]

  testOrder = [ '2003/01/02 +00.00', '2003/01/01 +09.25', '2002/08/02 +04.00',
                '2003/01/01 +06.25', '2001/01/01 +06.25', '2002/08/02 +12.00' ]

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

test 'several compares', ->
  # there's no way to avoid local timezone being set in browser.
  randomDayInFebruary = new Date(2010, 1, 3, 12, 0, 0)
  clock = sinon.useFakeTimers(randomDayInFebruary.getTime())
  equal new Date().toDateString(), "Wed Feb 03 2010", "sinon isn't working"

  validAfterOffset = _HB.comparableOffset currentTestBrowserOffset(randomDayInFebruary)
  invalidAfterOffset = _HB.comparableOffset currentTestBrowserOffset(randomDayInFebruary) - 60

  # the international day is already the 4th
  strictEqual _HB.ymd(_HB.idl()), "2010/02/04"

  ok _HB.comparableDate() >= "2010/02/04 +#{validAfterOffset}", "locally, it should be past 2010/02/03"
  ok _HB.comparableDate() < "2010/02/04 +#{invalidAfterOffset}", "locally, it should not yet be 2010/02/03"

  clock.restore()
