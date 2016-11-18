import Ember from 'ember';

export default Ember.Controller.extend({
  needs: "targeting",

  actions: {

    openRuleModal(ruleData) {
      return this.get('controllers.targeting').send('openRuleModal', ruleData);
    }
  }
});
