HelloBar.SettingsEmailsController = Ember.Controller.extend({

  collectionOptions: [
    {value: 0, label: 'Just email addresses'},
    {value: 1, label: 'Names and email addresses'}
  ],

  newContactListOption: [{id: 0, name: "New contact list..."}],
  contactListOptions: Ember.computed.uniq('model.site.contact_lists', 'newContactListOption'),

  afterSubmitOptions: [
    {value: 0, label: 'Show default message'},
    {value: 1, label: 'Show a custom message'},
    {value: 2, label: 'Redirect the visitor to a url'}
  ],

  showDefaultMessage: (function() {
    let action_index = this.get("model.settings.after_email_submit_action");
    return action_index === 0;
  }).property("model.settings.after_email_submit_action"),

  disableThankYouText: Ember.computed.not('model.site.capabilities.custom_thank_you_text'),
  disableRedirect: Ember.computed.not('model.site.capabilities.after_submit_redirect'),

  setDefaultListID: (function() {
    this.set('model.orig_contact_list_id', this.get('model.contact_list_id'));

    if (!this.get('model.contact_list_id')) {
      let firstList = this.get('model.site.contact_lists')[0];
      let listId = firstList ? firstList.id : null;

      return this.set('model.contact_list_id', listId);
    }
  }).observes('model.site.contact_lists'),

  popNewContactListModal: (function() {
    if ((this.get("model.site.contact_lists").length === 0 || this.get("model.contact_list_id") === 0) && $(".contact-list-modal:visible").length === 0) {
      let options = {
        siteID: window.siteID,
        saveURL: `/sites/${siteID}/contact_lists.json`,
        saveMethod: "POST",
        editorModel: this.get("model"),
        success: (data, modal) => {
          let lists = this.get("model.site.contact_lists").slice(0);
          lists.push({id: data.id, name: data.name});
          this.set("model.site.contact_lists", lists);
          setTimeout((() => {
            return this.set("model.contact_list_id", data.id);
          }
          ), 100);
          return modal.$modal.remove();
        },
        close: modal => {
          return this.set("model.contact_list_id", null);
        }
      };

      if (trackEditorFlow) { InternalTracking.track_current_person("Editor Flow", {step: "Contact List Settings", goal: this.get("model.element_subtype")}); }
      return new ContactListModal(options).open();
    }
  }).observes("model.contact_list_id"),

  showEditContactListLink: (function() {
    let id = this.get("model.contact_list_id");
    return id && id !== 0;
  }).property("model.contact_list_id"),

  showRedirectUrlInput: (function() {
    return this.get("model.settings.after_email_submit_action") === 2;
  }).property("model.settings.after_email_submit_action"),

  actions: {

    popEditContactListModal(id) {
      let canDelete = (id !== this.get("model.orig_contact_list_id"));

      let options = {
        id,
        siteID,
        loadURL: `/sites/${siteID}/contact_lists/${id}.json`,
        saveURL: `/sites/${siteID}/contact_lists/${id}.json`,
        saveMethod: "PUT",
        editorModel: this.get("model"),
        canDelete,
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
      };

      return new ContactListModal(options).open();
    },

    openUpgradeModal(capabilityType) {
      let controller = this;

      if (capabilityType === "redirect") {
        var upgradeText = 'redirect to a custom url';
      } else {
        var upgradeText = 'customize your thank you text';
      }

      return new UpgradeAccountModal({
        site: controller.get('model.site'),
        upgradeBenefit: upgradeText,
        successCallback() {
          return controller.set('model.site.capabilities', this.site.capabilities);
        }
      }).open();
    }
  }
});
