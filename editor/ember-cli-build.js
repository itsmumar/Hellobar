/*jshint node:true*/
/* global require, module */
var EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function (defaults) {
  var app = new EmberApp(defaults, {
    sassOptions: {
      includePaths: [
        '../app/assets/stylesheets',
        '../app/assets/stylesheets/settings',
        '../app/assets/stylesheets/elements',
        '../app/assets/stylesheets/elements/forms',
        '../app/assets/stylesheets/components',
        '../app/assets/stylesheets/layouts/editor',
        'bower_components/bourbon/app/assets/stylesheets',
        'bower_components/normalize-css',
        'bower_components/jquery-minicolors',
        'bower_components/nouislider/distribute',
        'bower_components/froala-wysiwyg-editor/css'
      ]
    }
    // Add options here
  });

  // Use `app.import` to add additional libraries to the generated
  // output files.
  //
  // If you need to use different assets in different
  // environments, specify an object as the first parameter. That
  // object's keys should be the environment name and the values
  // should be the asset to use in that environment.
  //
  // If the library that you are including contains AMD or ES6
  // modules that you would like to import into your application
  // please specify an object with the list of modules as keys
  // along with the exports of each module as its value.
  app.import('bower_components/phoneformat/dist/phone-format.min.js');

  return app.toTree();
};
