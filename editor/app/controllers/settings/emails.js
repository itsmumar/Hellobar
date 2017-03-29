import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  inlineEditing: Ember.inject.service(),
  bus: Ember.inject.service(),
  applicationController: Ember.inject.controller('application'),

  init() {
    this.get('bus').subscribe('hellobar.core.fields.changed', (params) => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    });
  },

  currentThemeIsGeneric: Ember.computed.alias('applicationController.currentThemeIsGeneric'),

  selectedContactList: function() {
    const contactListId = this.get('model.contact_list_id');
    const contactLists = this.get('model.site.contact_lists');
    return _.find(contactLists, (contactList) => contactList.id === contactListId);
  }.property('model.contact_list_id', 'model.site.contact_lists'),

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
  }.observes('model.type'),

//-----------  Actions  -----------#

  actions: {

    setContactList(listId) {
      this.set('model.contact_list_id', listId);
    },

    openEmailListPopup(listId = 0) {
      const { siteID } = window;

      if (listId) {
        // Edit Existing Contact List
        new ContactListModal({
          id: listId,
          siteID,
          loadURL: `/sites/${siteID}/contact_lists/${listId}.json`,
          saveURL: `/sites/${siteID}/contact_lists/${listId}.json`,
          saveMethod: 'PUT',
          editorModel: this.get('model'),
          canDelete: (listId !== this.get('model.orig_contact_list_id')),

          success: (data, modal) => {
            const iterable = this.get('model.site.contact_lists');
            for (let i = 0; i < iterable.length; i++) {
              let list = iterable[i];
              if (list.id === data.id) {
                Ember.set(list, 'name', data.name);
                break;
              }
            }
            modal.close();
          },

          destroyed: (data, modal) => {
            const lists = this.get('model.site.contact_lists');
            for (let i = 0; i < lists.length; i++) {
              let list = lists[i];
              if (list.id === data.id) {
                lists.removeObject(list);
                break;
              }
            }
            modal.close();
          }
        }).open();

      } else {
        // New Contact List
        if (trackEditorFlow) {
          InternalTracking.track_current_person('Editor Flow', {
            step: 'Contact List Settings',
            goal: this.get('model.element_subtype')
          });
        }

        new ContactListModal({
          siteID,
          saveURL: `/sites/${siteID}/contact_lists.json`,
          saveMethod: 'POST',
          editorModel: this.get('model'),

          success: (data, modal) => {
            let lists = this.get('model.site.contact_lists').slice(0);
            lists.push({id: data.id, name: data.name, provider_name: data.provider_name});
            this.set('model.site.contact_lists', lists);
            setTimeout(( () => {
                this.set('model.contact_list_id', data.id);
              }
            ), 100);
            modal.$modal.remove();
          },

          close: modal => this.set('model.contact_list_id', null)
        }).open();
      }
    }
  }
});
