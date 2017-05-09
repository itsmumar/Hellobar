function modules(data) { $INJECT_MODULES };
(function test(data) {
  return modules(data);
})($INJECT_DATA)
