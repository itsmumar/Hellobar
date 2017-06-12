import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['field-list'],

  bus: Ember.inject.service(),

  /**
   * @property {object} Main element model
   */
  model: null,

  didInsertElement() {
    const $sortableGroupElement = Ember.$('.js-fields-to-collect');
    if ($sortableGroupElement.length > 0) {
      new Sortable($sortableGroupElement[0], {
        draggable: '.item-block',
        filter: '.denied',
        onEnd: evt => {
          const fields = Ember.copy(this.get('model.settings.fields_to_collect'));
          const elementsToMove = fields.splice(evt.oldIndex, 1);
          fields.splice(evt.newIndex, 0, elementsToMove[0]);
          this.set('model.settings.fields_to_collect', fields);
          setTimeout(()=> {
            return $sortableGroupElement.find('.item-block[draggable="false"]').remove();
          }, 0);
        }
      });
    }

    this._fieldChangeHandler = () => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    };
    this.get('bus').subscribe('hellobar.core.fields.changed', this._fieldChangeHandler);
  },

  willDestroyElement() {
    this._fieldChangeHandler && this.get('bus').unsubscribe('hellobar.core.fields.changed', this._fieldChangeHandler);
  },

  newFieldToCollect: null,

  builtinFieldDefinitions: {
    'builtin-name': {
      label: 'Name'
    },
    'builtin-email': {
      label: 'Email'
    },
    'builtin-phone': {
      label: 'Phone'
    }
  },

  preparedFieldDescriptors: function () {
    return _.map(this.get('model.settings.fields_to_collect'), field => ({
      field: {
        id: field.id,
        label: this.builtinFieldDefinitions[field.type] ? this.builtinFieldDefinitions[field.type].label : field.label,
        is_enabled: field.is_enabled,
        type: field.type
      },
      denied: this.get('isBarType') && field.type.indexOf('builtin-') !== 0,
      removable: field.type.indexOf('builtin-') !== 0
    }));
  }.property('model.settings.fields_to_collect', 'model.type', 'isBarType'),

  isBarType: Ember.computed.equal('model.type', 'Bar'),

  addFieldCssClasses: function() {
    return 'item-block add' + (this.get('isBarType') ? ' denied' : '');
  }.property('isBarType'),

  _cancelAddingFieldToCollect() {
    this.set('newFieldToCollect', null);
  },

  actions: {
    toggleFieldToCollect(field) {
      if (field.type === 'builtin-email') {
        return;
      }
      const fields = this.get('model.settings.fields_to_collect');
      const fieldToChange = _.find(fields, f => f.id === field.id);
      fieldToChange.is_enabled = !fieldToChange.is_enabled;
      this.set('model.settings.fields_to_collect', Ember.copy(fields));
    },

    removeFieldToCollect(field) {
      const fields = this.get('model.settings.fields_to_collect');
      const newFields = _.reject(fields, f => f.id === field.id);
      this.set('model.settings.fields_to_collect', newFields);
    },

    addFieldToCollect() {
      if (!this.get('isBarType')) {
        this.set('newFieldToCollect', {
          id: _.uniqueId('field_') + '_' + Date.now(),
          type: 'text',
          label: '',
          is_enabled: true
        });
        Ember.run.next(() => {
          const $newField = this.$('.js-new-field');
          ($newField && $newField.length > 0) && $newField[0].focus();
        });
      }
    },

    confirmAddingFieldToCollect() {
      if (!this.newFieldToCollect.label) {
        this._cancelAddingFieldToCollect();
        return;
      }
      const newFields = this.get('model.settings.fields_to_collect').concat([this.newFieldToCollect]);
      this.set('model.settings.fields_to_collect', newFields);
      this.set('newFieldToCollect', null);
    },

    cancelAddingFieldToCollect() {
      this._cancelAddingFieldToCollect();
    }

  }

});
