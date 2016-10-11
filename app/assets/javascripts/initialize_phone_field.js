HB.initializePhoneFields = function () {
  var HB_PHONE_COUNTRY_CODE = 'HB_PHONE_COUNTRY_CODE';
  function saveCountryCode(countryCode) {
    window[HB_PHONE_COUNTRY_CODE] = countryCode;
  }
  function restoreCountryCode() {
    return window[HB_PHONE_COUNTRY_CODE];
  }
  setTimeout(function() {
    var inputField = $("iframe").contents().find("input[type='tel']");
    setTimeout(function() {
      if (inputField.length > 0) {
        inputField.intlTelInput({
          initialCountry: "auto",
          autoPlaceholder: "aggressive",
          geoIpLookup: function (callback) {
            $.get("http://ipinfo.io", function () {
            }, "jsonp")
              .always(function (resp) {
                var countryCode = (resp && resp.country) ? resp.country : "";
                inputField.intlTelInput("setCountry", countryCode);
                saveCountryCode(countryCode);
              });
          },
          utilsScript: "https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/9.2.0/js/utils.js"
        });
        inputField.on("countrychange", function(e, countryData) {
          saveCountryCode(countryData.iso2);
        });
        var restoredCountryCode = restoreCountryCode();
        restoredCountryCode && inputField.intlTelInput("setCountry", restoredCountryCode);
      }
    }, 500);
  }, 0);
};
