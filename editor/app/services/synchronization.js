import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  /**
   * Execute given action when given condition is passed successfully.
   * @param condition {function}
   * @param action {function}
   * @param options {object}
   */
  waitAndDo(condition, action, options) {
    const defaultOptions = {
      conditionPollTimeout: 100
    };
    options = _.defaults({}, options, defaultOptions);
    function tryDoAction() {
      if (condition()) {
        action();
      } else {
        setTimeout(tryDoAction, options.conditionPollTimeout);
      }
    }

    tryDoAction();
  }

});

