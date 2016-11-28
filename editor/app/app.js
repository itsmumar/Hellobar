import Ember from 'ember';
import Resolver from './resolver';
import loadInitializers from 'ember-load-initializers';
import config from './config/environment';

let App;

Ember.MODEL_FACTORY_INJECTIONS = true;

App = Ember.Application.extend({
  modulePrefix: config.modulePrefix,
  podModulePrefix: config.podModulePrefix,
  Resolver,
  rootElement: "#ember-root"
});

loadInitializers(App, config.modulePrefix);

// TODO cleanup this file, split to submodules

//-----------  Debounce/Throttle Observers  -----------#

const slice = [].slice;

Ember.debouncedObserver = function () {
  let func, i, keys, time;
  keys = 3 <= arguments.length ?
    slice.call(arguments, 0, i = arguments.length - 2) :
    (i = 0, []), time = arguments[i++], func = arguments[i++];
  return Ember.observer.apply(Ember, [function () {
    return Ember.run.debounce(this, func, time);
  }].concat(slice.call(keys)));
};

Ember.throttledObserver = function () {
  let func, i, keys, time;
  keys = 3 <= arguments.length ?
    slice.call(arguments, 0, i = arguments.length - 2) :
    (i = 0, []), time = arguments[i++], func = arguments[i++];
  return Ember.observer.apply(Ember, [function () {
    return Ember.run.throttle(this, func, time);
  }].concat(slice.call(keys)));
};

//-----------  Preview Injection  -----------#

// TODO why HB is not defined here? Fix this
if (typeof HB === 'undefined') {
  window.HB = {};
}

HB._listeners = [];

HB.addPreviewInjectionListener = listener => HB._listeners.push(listener);

HB.injectAtTop = function (element) {
  let container = HB.$("#hellobar-preview-container");

  if (container.children[0]) {
    container.insertBefore(element, container.children[0]);
  } else {
    container.appendChild(element);
  }

  return HB._listeners.forEach(listener => listener(container));
};

//-----------  Set Application Height  -----------#

$(function () {

  let setHeight = function () {
    let height = $(window).height() - $('.header-wrapper').height();
    return $('#ember-root').height(height);
  };

  $(window).resize(() => setHeight());

  return setHeight();
});

//-----------  Phone Data  -----------#

HB.countryCodes = [
  {code: "AF", name: "Afghanistan"},
  {code: "AL", name: "Albania"},
  {code: "DZ", name: "Algeria"},
  {code: "AS", name: "American Samoa"},
  {code: "AD", name: "Andorra"},
  {code: "AO", name: "Angola"},
  {code: "AI", name: "Anguilla"},
  {code: "AQ", name: "Antarctica"},
  {code: "AG", name: "Antigua And Barbuda"},
  {code: "AR", name: "Argentina"},
  {code: "AM", name: "Armenia"},
  {code: "AW", name: "Aruba"},
  {code: "AU", name: "Australia"},
  {code: "AT", name: "Austria"},
  {code: "AZ", name: "Azerbaijan"},
  {code: "BS", name: "Bahamas"},
  {code: "BH", name: "Bahrain"},
  {code: "BD", name: "Bangladesh"},
  {code: "BB", name: "Barbados"},
  {code: "BY", name: "Belarus"},
  {code: "BE", name: "Belgium"},
  {code: "BZ", name: "Belize"},
  {code: "BJ", name: "Benin"},
  {code: "BM", name: "Bermuda"},
  {code: "BT", name: "Bhutan"},
  {code: "BO", name: "Bolivia"},
  {code: "BA", name: "Bosnia And Herzegovina"},
  {code: "BW", name: "Botswana"},
  {code: "BV", name: "Bouvet Island"},
  {code: "BR", name: "Brazil"},
  {code: "IO", name: "British Indian Ocean Territory"},
  {code: "BN", name: "Brunei"},
  {code: "BG", name: "Bulgaria"},
  {code: "BF", name: "Burkina Faso"},
  {code: "BI", name: "Burundi"},
  {code: "KH", name: "Cambodia"},
  {code: "CM", name: "Cameroon"},
  {code: "CA", name: "Canada"},
  {code: "CV", name: "Cape Verde"},
  {code: "KY", name: "Cayman Islands"},
  {code: "CF", name: "Central African Republic"},
  {code: "TD", name: "Chad"},
  {code: "CL", name: "Chile"},
  {code: "CN", name: "China"},
  {code: "CX", name: "Christmas Island"},
  {code: "CC", name: "Cocos (Keeling) Islands"},
  {code: "CO", name: "Columbia"},
  {code: "KM", name: "Comoros"},
  {code: "CG", name: "Congo"},
  {code: "CK", name: "Cook Islands"},
  {code: "CR", name: "Costa Rica"},
  {code: "CI", name: "Cote D'Ivorie (Ivory Coast)"},
  {code: "HR", name: "Croatia (Hrvatska)"},
  {code: "CU", name: "Cuba"},
  {code: "CY", name: "Cyprus"},
  {code: "CZ", name: "Czech Republic"},
  {code: "CD", name: "Democratic Republic Of Congo (Zaire)"},
  {code: "DK", name: "Denmark"},
  {code: "DJ", name: "Djibouti"},
  {code: "DM", name: "Dominica"},
  {code: "DO", name: "Dominican Republic"},
  {code: "TP", name: "East Timor"},
  {code: "EC", name: "Ecuador"},
  {code: "EG", name: "Egypt"},
  {code: "SV", name: "El Salvador"},
  {code: "GQ", name: "Equatorial Guinea"},
  {code: "ER", name: "Eritrea"},
  {code: "EE", name: "Estonia"},
  {code: "ET", name: "Ethiopia"},
  {code: "FK", name: "Falkland Islands (Malvinas)"},
  {code: "FO", name: "Faroe Islands"},
  {code: "FJ", name: "Fiji"},
  {code: "FI", name: "Finland"},
  {code: "FR", name: "France"},
  {code: "FX", name: "France Metropolitan"},
  {code: "GF", name: "French Guinea"},
  {code: "PF", name: "French Polynesia"},
  {code: "TF", name: "French Southern Territories"},
  {code: "GA", name: "Gabon"},
  {code: "GM", name: "Gambia"},
  {code: "GE", name: "Georgia"},
  {code: "DE", name: "Germany"},
  {code: "GH", name: "Ghana"},
  {code: "GI", name: "Gibraltar"},
  {code: "GR", name: "Greece"},
  {code: "GL", name: "Greenland"},
  {code: "GD", name: "Grenada"},
  {code: "GP", name: "Guadeloupe"},
  {code: "GU", name: "Guam"},
  {code: "GT", name: "Guatemala"},
  {code: "GN", name: "Guinea"},
  {code: "GW", name: "Guinea-Bissau"},
  {code: "GY", name: "Guyana"},
  {code: "HT", name: "Haiti"},
  {code: "HM", name: "Heard And McDonald Islands"},
  {code: "HN", name: "Honduras"},
  {code: "HK", name: "Hong Kong"},
  {code: "HU", name: "Hungary"},
  {code: "IS", name: "Iceland"},
  {code: "IN", name: "India"},
  {code: "ID", name: "Indonesia"},
  {code: "IR", name: "Iran"},
  {code: "IQ", name: "Iraq"},
  {code: "IE", name: "Ireland"},
  {code: "IM", name: "Isle of Man"},
  {code: "IL", name: "Israel"},
  {code: "IT", name: "Italy"},
  {code: "JM", name: "Jamaica"},
  {code: "JP", name: "Japan"},
  {code: "JO", name: "Jordan"},
  {code: "KZ", name: "Kazakhstan"},
  {code: "KE", name: "Kenya"},
  {code: "KI", name: "Kiribati"},
  {code: "KW", name: "Kuwait"},
  {code: "KG", name: "Kyrgyzstan"},
  {code: "LA", name: "Laos"},
  {code: "LV", name: "Latvia"},
  {code: "LB", name: "Lebanon"},
  {code: "LS", name: "Lesotho"},
  {code: "LR", name: "Liberia"},
  {code: "LY", name: "Libya"},
  {code: "LI", name: "Liechtenstein"},
  {code: "LT", name: "Lithuania"},
  {code: "LU", name: "Luxembourg"},
  {code: "MO", name: "Macau"},
  {code: "MK", name: "Macedonia"},
  {code: "MG", name: "Madagascar"},
  {code: "MW", name: "Malawi"},
  {code: "MY", name: "Malaysia"},
  {code: "MV", name: "Maldives"},
  {code: "ML", name: "Mali"},
  {code: "MT", name: "Malta"},
  {code: "MH", name: "Marshall Islands"},
  {code: "MQ", name: "Martinique"},
  {code: "MR", name: "Mauritania"},
  {code: "MU", name: "Mauritius"},
  {code: "YT", name: "Mayotte"},
  {code: "MX", name: "Mexico"},
  {code: "FM", name: "Micronesia"},
  {code: "MD", name: "Moldova"},
  {code: "MC", name: "Monaco"},
  {code: "MN", name: "Mongolia"},
  {code: "MS", name: "Montserrat"},
  {code: "MA", name: "Morocco"},
  {code: "MZ", name: "Mozambique"},
  {code: "MM", name: "Myanmar (Burma)"},
  {code: "NA", name: "Namibia"},
  {code: "NR", name: "Nauru"},
  {code: "NP", name: "Nepal"},
  {code: "NL", name: "Netherlands"},
  {code: "AN", name: "Netherlands Antilles"},
  {code: "NC", name: "New Caledonia"},
  {code: "NZ", name: "New Zealand"},
  {code: "NI", name: "Nicaragua"},
  {code: "NE", name: "Niger"},
  {code: "NG", name: "Nigeria"},
  {code: "NU", name: "Niue"},
  {code: "NF", name: "Norfolk Island"},
  {code: "KP", name: "North Korea"},
  {code: "MP", name: "Northern Mariana Islands"},
  {code: "NO", name: "Norway"},
  {code: "OM", name: "Oman"},
  {code: "PK", name: "Pakistan"},
  {code: "PW", name: "Palau"},
  {code: "PA", name: "Panama"},
  {code: "PG", name: "Papua New Guinea"},
  {code: "PY", name: "Paraguay"},
  {code: "PE", name: "Peru"},
  {code: "PH", name: "Philippines"},
  {code: "PN", name: "Pitcairn"},
  {code: "PL", name: "Poland"},
  {code: "PT", name: "Portugal"},
  {code: "PR", name: "Puerto Rico"},
  {code: "QA", name: "Qatar"},
  {code: "RE", name: "Reunion"},
  {code: "RO", name: "Romania"},
  {code: "RU", name: "Russia"},
  {code: "RW", name: "Rwanda"},
  {code: "SH", name: "Saint Helena"},
  {code: "KN", name: "Saint Kitts And Nevis"},
  {code: "LC", name: "Saint Lucia"},
  {code: "PM", name: "Saint Pierre And Miquelon"},
  {code: "VC", name: "Saint Vincent And The Grenadines"},
  {code: "SM", name: "San Marino"},
  {code: "ST", name: "Sao Tome And Principe"},
  {code: "SA", name: "Saudi Arabia"},
  {code: "SN", name: "Senegal"},
  {code: "SC", name: "Seychelles"},
  {code: "SL", name: "Sierra Leone"},
  {code: "SG", name: "Singapore"},
  {code: "SK", name: "Slovak Republic"},
  {code: "SI", name: "Slovenia"},
  {code: "SB", name: "Solomon Islands"},
  {code: "SO", name: "Somalia"},
  {code: "ZA", name: "South Africa"},
  {code: "GS", name: "South Georgia And South Sandwich Islands"},
  {code: "KR", name: "South Korea"},
  {code: "ES", name: "Spain"},
  {code: "LK", name: "Sri Lanka"},
  {code: "SD", name: "Sudan"},
  {code: "SR", name: "Suriname"},
  {code: "SJ", name: "Svalbard And Jan Mayen"},
  {code: "SZ", name: "Swaziland"},
  {code: "SE", name: "Sweden"},
  {code: "CH", name: "Switzerland"},
  {code: "SY", name: "Syria"},
  {code: "TW", name: "Taiwan"},
  {code: "TJ", name: "Tajikistan"},
  {code: "TZ", name: "Tanzania"},
  {code: "TH", name: "Thailand"},
  {code: "TG", name: "Togo"},
  {code: "TK", name: "Tokelau"},
  {code: "TO", name: "Tonga"},
  {code: "TT", name: "Trinidad And Tobago"},
  {code: "TN", name: "Tunisia"},
  {code: "TR", name: "Turkey"},
  {code: "TM", name: "Turkmenistan"},
  {code: "TC", name: "Turks And Caicos Islands"},
  {code: "TV", name: "Tuvalu"},
  {code: "UG", name: "Uganda"},
  {code: "UA", name: "Ukraine"},
  {code: "AE", name: "United Arab Emirates"},
  {code: "GB", name: "United Kingdom"},
  {code: "UM", name: "United States Minor Outlying Islands"},
  {code: "US", name: "United States"},
  {code: "UY", name: "Uruguay"},
  {code: "UZ", name: "Uzbekistan"},
  {code: "VU", name: "Vanuatu"},
  {code: "VA", name: "Vatican City (Holy See)"},
  {code: "VE", name: "Venezuela"},
  {code: "VN", name: "Vietnam"},
  {code: "VG", name: "Virgin Islands (British)"},
  {code: "VI", name: "Virgin Islands (US)"},
  {code: "WF", name: "Wallis And Futuna Islands"},
  {code: "EH", name: "Western Sahara"},
  {code: "WS", name: "Western Samoa"},
  {code: "YE", name: "Yemen"},
  {code: "YU", name: "Yugoslavia"},
  {code: "ZM", name: "Zambia"},
  {code: "ZW", name: "Zimbabwe"},
  {code: "XX", name: "Custom"}
];


export default App;
