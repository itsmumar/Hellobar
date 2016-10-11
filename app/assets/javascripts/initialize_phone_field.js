$(function() {
                      var inputField = $("iframe").contents().find("input[type=\'tel\']");
                      setTimeout(function() {
                        if(inputField.length > 0) {
                          inputField.intlTelInput({
                            initialCountry: "auto",
                            autoPlaceholder: "aggressive",
                            geoIpLookup: function(callback) {
                              $.get("http://ipinfo.io", function() {}, "jsonp")
                              .always(function(resp) {
                                var countryCode = (resp && resp.country) ? resp.country : "";
                                inputField.intlTelInput("setCountry", countryCode);
                              });
                            },
                            utilsScript: "https://cdnjs.cloudflare.com/ajax/libs/intl-tel-input/9.2.0/js/utils.js"});
                          }
                        }, 500); 
                      });
