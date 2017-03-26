hellobar.defineModule('base.timezone', [], function () {

  // Parses the zone and returns the offset in seconds. If it can
  // not be parsed returns null.
  // Valid formats for zone are:
  // "HHMM", "+HHMM", "-HHMM", "HH:MM", "+HH:MM and "-HH:MM".
  function parseTimezone(zone) {
    if (!zone || typeof(zone) != 'string')
      return null;
    // Add + if missing +/-
    if (zone[0] != '+' && zone[0] != '-')
      zone = '+' + zone;
    if (zone.indexOf(':') == -1)
      zone = zone.slice(0, zone.length - 2) + ':' + zone.slice(zone.length - 2);
    if (!zone.match(/^[\+-]\d{1,2}:\d\d$/))
      return null;
    // Parse it
    var parts = zone.split(':');
    var signMultiplier = zone[0] == '+' ? 1 : -1;
    var hour = Math.abs(parseInt(parts[0], 10));
    var minute = parseInt(parts[1], 10);

    return ((hour * 60 * 60) + (minute * 60)) * signMultiplier;
  }


  // TODO used in setDefaultSegments and elements.rules
  // Returns a Date object adjusted to the timezone specified (if none is
  // specified we try to use HB_TZ - if that is not present we use the user
  // timezone. The timezone of the actual Date object wills till be the
  // user's timezone since this can not be changed, but it will be offset
  // by the correct hours and minutes of the zone passed in.
  // If no valid format is found we use the current user's timezone
  // You can also pass in the value "visitor" which will use the visitor's
  // timezone
  function nowInTimezone(zone) {
    // If no zone is specified try the HB_TZ variable
    if (!zone && typeof(HB_TZ) == 'string')
      zone = HB_TZ;
    var zoneOffset = parseTimezone(zone);
    if (zoneOffset === null)
      return new Date();
    var now = new Date();
    return new Date(now.getTime() + (now.getTimezoneOffset() * 60 * 1000) + (zoneOffset * 1000))
  }

  return {
    nowInTimezone
  };

});
