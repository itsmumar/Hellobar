#= require hellobar.base

module 'hellobar_base',
  teardown: ->
    ok (new Date()).getUTCFullYear() > 2013, "clock was not restored using sinon"

# you can't easily create a date in a specific timezone.
localMillenium = -> new Date(2000, 0, 1)
currentTestBrowserOffset = -> (new Date()).getTimezoneOffset()
utcMillenium = -> new Date(localMillenium().getTime() - ( currentTestBrowserOffset() * 60000))

test 'utc dates string representation is what is expected', ->
  now = new Date()
  y = now.getUTCFullYear()
  m = _HB.zeropad(now.getUTCMonth()+1)
  d = _HB.zeropad(now.getUTCDate())
  utcStringDate = "#{y}/#{m}/#{d} +#{_HB.comparableOffset()}"
  strictEqual _HB.comparableDate(), utcStringDate, "#{_HB.comparableDate()} and #{utcStringDate} dates aren't equal"

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

  strictEqual _HB.comparableDate('auto'), "2000/01/01", "Auto mode should leave offset off"

  ok _HB.comparableDate('auto') >= "2000/01/01"
  ok _HB.comparableDate('auto') < "2000/01/02"

  ok !(_HB.comparableDate('auto') >= "2000/01/02")
  ok !(_HB.comparableDate('auto') < "2000/01/01")

  clock.restore()

test 'several compares', ->
  # there's no way to avoid local timezone being set in browser.
  clock = sinon.useFakeTimers(new Date(2010, 1, 3, 12, 0, 0).getTime())
  equal new Date().toDateString(), "Wed Feb 03 2010", "sinon isn't working"

  validAfterOffset = _HB.comparableOffset currentTestBrowserOffset()
  invalidAfterOffset = _HB.comparableOffset currentTestBrowserOffset() - 60

  ok _HB.comparableDate() >= "2010/02/03 +#{validAfterOffset}", "locally, it should be past 2010/02/03"
  ok _HB.comparableDate() < "2010/02/03 +#{invalidAfterOffset}", "locally, it should not yet be 2010/02/03" # in chicago, 7.00

  clock.restore()


