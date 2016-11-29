import Ember from 'ember';
import ENV from 'editor/config/environment';

const apiBaseConfiguration = {
  'development': 'http://localhost:3001',
  '*': ''
};

const getApiBase = () => (ENV.environment && apiBaseConfiguration[ENV.environment]) ?
  apiBaseConfiguration[ENV.environment] :
  apiBaseConfiguration['*'];

const apiBase = getApiBase();

export default Ember.Service.extend({
  newSiteElement() {
    // TODO get rid of global variable siteID?
    return Ember.$.getJSON(`${apiBase}/sites/${window.siteID}/site_elements/new.json`);
  },

  siteElement(id) {
    return Ember.$.getJSON(`${apiBase}/sites/${window.siteID}/site_elements/${id}.json`);
  }
});
