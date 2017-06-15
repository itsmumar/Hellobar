import Ember from 'ember';
import Resolver from './resolver';
import loadInitializers from 'ember-load-initializers';
import config from './config/environment';


// TODO this is temporary solution. Remove it:
window.HelloBar = {};


let App;

Ember.MODEL_FACTORY_INJECTIONS = true;

App = Ember.Application.extend({
  modulePrefix: config.modulePrefix,
  podModulePrefix: config.podModulePrefix,
  Resolver,
  rootElement: "#ember-root"
});

loadInitializers(App, config.modulePrefix);


//-----------  Set Application Height  -----------#

$(function () {

  let setHeight = function () {
    // TODO it seems that we don't have .header-wrapper in editor SPA
    let height = $(window).height() - ($('.header-wrapper').height() || 0);
    return $('#ember-root').height(height);
  };

  $(window).resize(() => setHeight());

  setHeight();

  // Workaround for setting styles for application view
  Ember.run.next(() => {
    function waitForChildren() {
      const $rootChildren = $('#ember-root').children();
      if ($rootChildren.length > 0) {
        $rootChildren.css('height', '100%');
      } else {
        Ember.run.later(waitForChildren, 80);
      }
    }
    waitForChildren();
  });

});

export default App;
