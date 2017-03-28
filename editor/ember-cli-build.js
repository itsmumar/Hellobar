/*jshint node:true*/
/* global require, module */
var EmberApp = require('ember-cli/lib/broccoli/ember-app');

module.exports = function (defaults) {
  var app = new EmberApp(defaults, {
    autoprefixer: { },
    fingerprint: {
      enabled: false
    },
    minifyJS: {
      enabled: false
    },
    minifyCSS: {
      enabled: false
    },
    sassOptions: {
      includePaths: [
        '../app/assets/stylesheets',
        'bower_components/bourbon/app/assets/stylesheets',
        'bower_components/normalize-css',
        'bower_components/jquery-minicolors',
        'bower_components/nouislider/distribute',
        'bower_components/froala-wysiwyg-editor/css',
        'node_modules',
        'vendor'
      ]
    },
    storeConfigInMeta: false,
    nodeAssets: {
      'codemirror': {
        srcDir: 'lib',
        'import': ['codemirror.css']
      }
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
  app.import('bower_components/dropzone/dist/dropzone.js');
  app.import('bower_components/color/one-color.js');
  app.import('bower_components/Sortable/Sortable.js');
  app.import('bower_components/nouislider/distribute/nouislider.js');
  app.import('bower_components/js-beautify/js/lib/beautify-html.js');
  app.import('bower_components/flexi-color-picker/colorpicker.js');
  app.import('bower_components/imagesloaded/imagesloaded.pkgd.js');
  app.import('bower_components/color-thief/dist/color-thief.min.js');
  app.import('vendor/dropper_trios.js');

  app.import('bower_components/froala-wysiwyg-editor/js/froala_editor.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/align.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/colors.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/emoticons.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/font_family.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/font_size.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/image.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/line_breaker.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/link.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/lists.min.js');
  app.import('bower_components/froala-wysiwyg-editor/js/plugins/quote.min.js');

  // This is needed to support non-SPA modals etc.
  app.import('bower_components/handlebars/handlebars.min.js');


  //var fontsDir = (EmberApp.env() === 'development') ? 'fonts' : '.';
  //console.log('fontsDir = ', fontsDir);
  var fontsDir = 'fonts';

  app.import('vendor/fonts/hellobar.eot', {destDir: fontsDir });
  app.import('vendor/fonts/hellobar.svg', {destDir: fontsDir });
  app.import('vendor/fonts/hellobar.ttf', {destDir: fontsDir });
  app.import('vendor/fonts/hellobar.woff', {destDir: fontsDir });

  app.import('vendor/fonts/hellobar-icons.eot', {destDir: fontsDir });
  app.import('vendor/fonts/hellobar-icons.svg', {destDir: fontsDir });
  app.import('vendor/fonts/hellobar-icons.ttf', {destDir: fontsDir });
  app.import('vendor/fonts/hellobar-icons.woff', {destDir: fontsDir });

  return app.toTree();
};
