import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  inlineEditing: Ember.inject.service(),
  applicationController: Ember.inject.controller('application'),

  init() {
    this.get('inlineEditing').addFieldChangeListener(() => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    });
  },

  currentThemeIsGeneric: Ember.computed.alias('applicationController.currentThemeIsGeneric'),

  selectedContactList: function() {
    const contactListId = this.get('model.contact_list_id');
    const contactLists = this.get('model.site.contact_lists');
    return _.find(contactLists, (contactList) => contactList.id === contactListId);
  }.property('model.contact_list_id', 'model.site.contact_lists'),


//-----------  Actions  -----------#

  actions: {

    setContactList(listId) {
      return this.set('model.contact_list_id', listId);
    },

    openEmailListPopup(listId = 0) {
      const { siteID } = window;

      if (listId) {
        // Edit Existing Contact List
        return new ContactListModal({
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
            return modal.close();
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
            return modal.close();
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
            lists.push({id: data.id, name: data.name});
            this.set('model.site.contact_lists', lists);
            setTimeout(( () => {
                return this.set('model.contact_list_id', data.id);
              }
            ), 100);
            return modal.$modal.remove();
          },

          close: modal => this.set('model.contact_list_id', null)
        }).open();
      }
    }
  }
});
