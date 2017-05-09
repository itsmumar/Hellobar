import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['i-need-help'],

  activated: false,

  csrfToken: ( () => $('meta[name=csrf-token]').attr('content')).property(),

  siteID: Ember.computed.alias('model.site.id'),

  actions: {
    onToggle() {
      this.toggleProperty('activated');
    },

    onCancel() {
      this.set('activated', false);
    }
  }

});

