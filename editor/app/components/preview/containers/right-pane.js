import Ember from 'ember';

export default Ember.Component.extend({

  bus: Ember.inject.service(),

  classNames: ['right-pane'],
  classNameBindings: ['componentIsDefined:visible'],

  elementId: 'editor-right-pane',

  componentIsDefined: (function () {
    return !!this.get('componentName');
  }).property('componentName'),

  componentName: null,
  componentOptions: null,

  context: Ember.computed(function () {
    return this;
  }),

  init() {
    this._super(...arguments);
    this.get('bus').subscribe('hellobar.core.rightPane.show', params => {
        return this.setProperties({
          componentName: params.componentName,
          componentOptions: params.componentOptions
        });
      }
    );
    this.get('bus').subscribe('hellobar.core.rightPane.hide', (/* params */) => {
        return this.setProperties({
          componentName: null,
          componentOptions: null
        });
      }
    );
  },

  onComponentNameChange: function () {
    // TODO refactor this jQuery usage after upgrading to Ember 2
    if (this.get('componentIsDefined')) {
      $('#editor-right-pane').show();
      return $('#hellobar-preview-container').css('overflow-y', 'visible');
    } else {
      $('#editor-right-pane').hide();
      return $('#hellobar-preview-container').css('overflow-y', 'hidden');
    }
  }.observes('componentName')


});
