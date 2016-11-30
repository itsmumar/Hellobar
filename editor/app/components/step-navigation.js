import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['step-navigation'],

  layoutName: ( () => 'components/step-navigation1').property(),

  //-----------  Routing  -----------#

  routes: ['settings', 'style', 'design', 'targeting'],

  routeLinks: (function () {
    return $.map(this.get('routes'), (route, i) => {
      return {route, past: (i + 1 < this.get('current'))};
    });
  }).property('current'),

  //-----------  Save Actions  -----------#

  actions: {

    saveSiteElement() {
      return this.sendAction('action');
    }
  }
});
