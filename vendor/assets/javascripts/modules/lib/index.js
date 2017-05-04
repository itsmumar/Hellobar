//= require ./crypto
//= require_self

(function () {
  hellobar.defineModule('lib.crypto', [], function () {
    return CryptoJS;
  });
}())
