import Ember from 'ember';

export default Ember.Route.extend({

  // Auto-redirects the index/home route to the first step
  redirect() {
    if (((typeof HB_DATA !== 'undefined') && HB_DATA.skipInterstitial) || localStorage['stashedEditorModel']) {
      // skip interstitial if it's explisitly set in global variable or if editor model was already stored in localStorage
      return this.replaceWith('goals');
    } else {
      return this.replaceWith('interstitial');
    }
  }
});
