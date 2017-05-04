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

// TODO cleanup this file, split to submodules

//-----------  Preview Injection  -----------#

// TODO remove this global
window.HBEditor = {};

// TODO remove  this from global space
HBEditor._listeners = [];

// TODO remove  this from global space
HBEditor.addPreviewInjectionListener = listener => HBEditor._listeners.push(listener);

hellobar('elements.injection').overrideInjectionPolicy(function (element) {
  const dom = hellobar('base.dom');
  const container = dom.$("#hellobar-preview-container");
  if (container.children[0]) {
    container.insertBefore(element, container.children[0]);
  } else {
    container.appendChild(element);
  }
  HBEditor._listeners.forEach(listener => listener(container));
});

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

//-----------  Phone Data  -----------#

HBEditor.countryCodes = gon.countryCodes;


export default App;
