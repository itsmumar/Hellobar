import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({
  renderTemplate() {
    return this.render({
      into: "interstitial"
    }); // render sub-interstitial templates into main "interstitial" template
  },

  setupController(controller, model) {
    this._track_selected_goal();
    this._super(controller, model);
    controller.setDefaults();
  },

  _track_selected_goal() {
    return $.ajax({
      method: "POST",
      url: `/sites/${siteID}/track_selected_goal`
    });
  }
});
