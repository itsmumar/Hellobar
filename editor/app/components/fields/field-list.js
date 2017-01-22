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
          let fields = Ember.copy(this.get('model.settings.fields_to_collect'));
          let elementsToMove = fields.splice(evt.oldIndex, 1);
          fields.splice(evt.newIndex, 0, elementsToMove[0]);
          this.set('model.settings.fields_to_collect', fields);
          return setTimeout(()=> {
            return $sortableGroupElement.find('.item-block[draggable="false"]').remove();
          }, 0);
        }
      });
    }
    this._initializeFields();
  },

  _initializeFields() {
    let fields = this.get('model.settings.fields_to_collect');
    if (_.isEmpty(fields)) {
      fields = [
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
      this.set('model.settings.fields_to_collect', fields);
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

  onElementTypeChange: (function () {
    if (this.get('isBarType')) {
      let fields = Ember.copy(this.get('model.settings.fields_to_collect'));
      fields && fields.forEach(function (field) {
        if (field && field.type && field.type.indexOf('builtin-') !== 0) {
          return field.is_enabled = false;
        }
      });
      return this.set('model.settings.fields_to_collect', fields);
    }
  }).observes('model.type'),

  preparedFieldDescriptors: (function () {
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
  }).property('model.settings.fields_to_collect', 'model.type', 'isBarType'),

  isBarType: (function () {
    return this.get('model.type') === 'Bar';
  }).property('model.type'),

  addFieldCssClasses: (function() {
    return 'item-block add' + (this.get('isBarType') ? ' denied' : '');
  }).property('isBarType'),

  actions: {
    toggleFieldToCollect(field) {
      if (field.type === 'builtin-email') {
        return;
      }
      let fields = this.get('model.settings.fields_to_collect');
      let fieldToChange = _.find(fields, f => f.id === field.id);
      fieldToChange.is_enabled = !fieldToChange.is_enabled;
      this.set('model.settings.fields_to_collect', Ember.copy(fields));
      return null;
    },

    removeFieldToCollect(field) {
      let fields = this.get('model.settings.fields_to_collect');
      let newFields = _.reject(fields, f => f.id === field.id);
      return this.set('model.settings.fields_to_collect', newFields);
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
      let newFields = this.get('model.settings.fields_to_collect').concat([this.newFieldToCollect]);
      this.set('model.settings.fields_to_collect', newFields);
      return this.set('newFieldToCollect', null);
    },


    onNewFieldToCollectEscapePressed() {
      return this.set('newFieldToCollect', null);
    },

  }

});
