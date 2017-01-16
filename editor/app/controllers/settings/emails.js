import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  inlineEditing: Ember.inject.service(),
  applicationController: Ember.inject.controller('application'),

  init() {
    this.get('inlineEditing').addFieldChangeListener(() => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    });
    return Ember.run.schedule('afterRender', this, () => {
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
      }
    );
  },

// TODO remove this
  collectNames: Ember.computed.alias('model.settings.collect_names'),

  currentThemeIsGeneric: Ember.computed.alias('applicationController.currentThemeIsGeneric'),

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

// set 'afterSubmitChoice' property only after model is ready
  afterModel: (function () {
    let fields = this.get('model.settings.fields_to_collect');
    if (_.isEmpty(fields)) {
// TODO this is mock fields data. It should be replaced with real data from server
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
  }).observes('model'),

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
    return this.get('model.settings.fields_to_collect').map(field => ({
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


  selectedContactList: function() {
    const contactListId = this.get('model.contact_list_id');
    const contactLists = this.get('model.site.contact_lists');
    return _.find(contactLists, (contactList) => contactList.id === contactListId);
  }.property('model.contact_list_id', 'model.site.contact_lists'),


//-----------  Actions  -----------#

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

    collectEmail() {
      return this.set('collectNames', 0);
    },

    collectEmailsAndNames() {
      return this.set('collectNames', 1);
    },

    setContactList(listID) {
      return this.set('model.contact_list_id', listID);
    },

    openEmailListPopup(listID = 0) {
      let { siteID } = window;

      if (listID) {
// Edit Existing Contact List
        return new ContactListModal({
          id: listID,
          siteID,
          loadURL: `/sites/${siteID}/contact_lists/${listID}.json`,
          saveURL: `/sites/${siteID}/contact_lists/${listID}.json`,
          saveMethod: "PUT",
          editorModel: this.get("model"),
          canDelete: (listID !== this.get("model.orig_contact_list_id")),

          success: (data, modal) => {
            let iterable = this.get("model.site.contact_lists");
            for (let i = 0; i < iterable.length; i++) {
              let list = iterable[i];
              if (list.id === data.id) {
                Ember.set(list, "name", data.name);
                break;
              }
            }
            return modal.close();
          },

          destroyed: (data, modal) => {
            let lists = this.get("model.site.contact_lists");
            for (let i = 0; i < lists.length; i++) {
              let list = lists[i];
              if (list.id === data.id) {
                lists.removeObject(list);
                break;
              }
            }
            return modal.close();
          }
        }).open();

      } else {
// New Contact List
        if (trackEditorFlow) {
          InternalTracking.track_current_person("Editor Flow", {
            step: "Contact List Settings",
            goal: this.get("model.element_subtype")
          });
        }

        return new ContactListModal({
          siteID,
          saveURL: `/sites/${siteID}/contact_lists.json`,
          saveMethod: "POST",
          editorModel: this.get("model"),

          success: (data, modal) => {
            let lists = this.get("model.site.contact_lists").slice(0);
            lists.push({id: data.id, name: data.name});
            this.set("model.site.contact_lists", lists);
            setTimeout(( () => {
                return this.set("model.contact_list_id", data.id);
              }
            ), 100);
            return modal.$modal.remove();
          },

          close: modal => this.set("model.contact_list_id", null)
        }).open();
      }
    }
  }
});
