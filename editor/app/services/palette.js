import Ember from 'ember';

/**
 * @class Palette
 * Encapsulates color set used in editor
 */
export default Ember.Service.extend({

  /**
   * TODO description
   */
  focusedColor: null,

  /**
   * TODO
   */
  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff'],

  /**
   * TODO
   */
  siteColors: null

});
