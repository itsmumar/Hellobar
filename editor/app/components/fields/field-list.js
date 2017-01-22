import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['field-list'],

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
    this._initializeFields();
  },

  _initializeFields() {
    if (_.isEmpty(this.get('model.settings.fields_to_collect'))) {
      const defaultFields = [
        {
          "id": "some-long-id-1",
          "type": "builtin-email",
          "is_enabled": true
        },
        {
          "id": "some-long-id-2",
          "type": "builtin-phone",
          "is_enabled": false
        },
        {
          "id": "some-long-id-3",
          "type": "builtin-name",
          "is_enabled": false
        }
      ];
      this.set('model.settings.fields_to_collect', defaultFields);
    }
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

  onElementTypeChange: function () {
    if (this.get('isBarType')) {
      const fields = Ember.copy(this.get('model.settings.fields_to_collect'));
      _.each(fields, (field) => {
        if (field && field.type && field.type.indexOf('builtin-') !== 0) {
          field.is_enabled = false;
        }
      });
      this.set('model.settings.fields_to_collect', fields);
    }
  }.observes('model.type'),

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
        return this.set('newFieldToCollect', {
          id: _.uniqueId('field_') + '_' + Date.now(),
          type: 'text',
          label: '',
          is_enabled: true
        });
      }
    },

    onNewFieldToCollectEnterPressed() {
      if (!this.newFieldToCollect.label) {
        return;
      }
      const newFields = this.get('model.settings.fields_to_collect').concat([this.newFieldToCollect]);
      this.set('model.settings.fields_to_collect', newFields);
      this.set('newFieldToCollect', null);
    },

    onNewFieldToCollectEscapePressed() {
      this.set('newFieldToCollect', null);
    }

  }

});
