import Ember from 'ember';
import _ from 'lodash/lodash';

/**
 * @class ModelLogic
 */
export default Ember.Service.extend({

  bus: Ember.inject.service(),

  /**
   * @property {object}
   */
  model: null,

  init() {
    this._trackFieldChanges();
  },

  _trackFieldChanges() {
    this.get('bus').subscribe('hellobar.core.fields.changed', (params) => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    });
  },

  setModel(model) {
    this.set('model', model);
  },

  onElementTypeChange: function () {
    if (this.get('model.type') === 'Bar') {
      const fields = Ember.copy(this.get('model.settings.fields_to_collect'));
      _.each(fields, (field) => {
        if (field && field.type && field.type.indexOf('builtin-') !== 0) {
          field.is_enabled = false;
        }
      });
      this.set('model.settings.fields_to_collect', fields);
    }
  }.observes('model.type')

  // TODO REFACTOR adopt (this is from style controller) (what is isEditing?)
  /*onElementTypeChanged: (function () {
    let elementType = this.get('model.type');
    if (elementType == 'Custom' || this.get('isEditing')) {
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    } else {
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'preview/containers/theming/theme-tile-grid',
        componentOptions: { elementType }
      });
    }
    this.get('inlineEditing').initializeInlineEditing(elementType);
  }).observes('model.type'),*/

});
