import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['step-navigation'],

  //-----------  Routing  -----------#

  routes: ['goals', 'styles', 'design', 'targeting'],

  routeLinks: (function () {
    return _.map(this.get('routes'), (route, i) => {
      return {route, past: (i + 1 < this.get('current'))};
    });
  }).property('current'),

  //-----------  Save Actions  -----------#

  actions: {

    saveSiteElement() {
      this.sendAction('action');
    }
  }
});
