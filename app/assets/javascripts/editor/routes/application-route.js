HelloBar.ApplicationRoute = Ember.Route.extend({

  saveCount: 0,

  model() {
    if (localStorage["stashedEditorModel"]) {
      let model = JSON.parse(localStorage["stashedEditorModel"]);
      localStorage.removeItem("stashedEditorModel");
      return model;
    } else if (window.barID) {
      return Ember.$.getJSON(`/sites/${window.siteID}/site_elements/${window.barID}.json`);
    } else if (window.elementToCopyID) {
      return Ember.$.getJSON(`/sites/${window.siteID}/site_elements/${window.elementToCopyID}.json`);
    } else {
      return Ember.$.getJSON(`/sites/${window.siteID}/site_elements/new.json`);
    }
  },

  //-----------  Parse JSON Model  -----------#

  afterModel(resolvedModel) {
    if (localStorage["stashedContactList"]) {
      let contactList = JSON.parse(localStorage["stashedContactList"]);
      localStorage.removeItem("stashedContactList");

      let baseOptions = {
        id: contactList.id,
        siteID,
        editorModel: resolvedModel,
        contactList
      };

      if (contactList.id) {
        var options = {
          saveURL: `/sites/${siteID}/contact_lists/${contactList.id}.json`,
          saveMethod: "PUT",

          success: (data, modal) => {
            resolvedModel.site.contact_lists.forEach(function(list) {
              if (list.id === data.id) {
                return Ember.set(list, "name", data.name);
              }
            });

            return modal.close();
          }
        };
      } else {
        var options = {
          saveURL: `/sites/${siteID}/contact_lists.json`,
          saveMethod: "POST",

          success: (data, modal) => {
            let lists = resolvedModel.site.contact_lists.slice(0);
            lists.push({id: data.id, name: data.name});
            this.controller.set("model.site.contact_lists", lists);
            setTimeout((() => {
              return this.controller.set("model.contact_list_id", data.id);
            }
            ), 100);
            return modal.$modal.remove();
          },
          close: modal => {
            return this.controller.set("model.contact_list_id", null);
          }
        };
      }

      return new ContactListModal($.extend(baseOptions, options)).open();
    }
  },

  //-----------  Controller Setup  -----------#

  setupController(controller, model) {
    // Set sub-step forwarding on application load
    let settings = this.controllerFor('settings');
    if (/^social/.test(model.element_subtype)) {
      settings.routeForwarding = 'settings.social';
    } else {
      switch (model.element_subtype) {
        case 'call':
          settings.routeForwarding = 'settings.call';
          break;
        case 'email':
          settings.routeForwarding = 'settings.emails';
          break;
        case 'traffic':
          settings.routeForwarding = 'settings.click';
          break;
        case 'announcement':
          settings.routeForwarding = 'settings.announcement';
          break;
        default:
          settings.routeForwarding = false;
      }
    }

    let style = this.controllerFor('style');
    switch (model.type) {
      case 'Takeover':
        style.routeForwarding = 'style.takeover';
        break;
      case 'Slider':
        style.routeForwarding = 'style.slider';
        break;
      case 'Modal':
        style.routeForwarding = 'style.modal';
        break;
      default:
        style.routeForwarding = model.id ? 'style.bar' : false;
    }

    let targeting = this.controllerFor('targeting');
    if (model.id) {
      switch (model.preset_rule_name) {
        case 'Everyone':
          targeting.routeForwarding = 'targeting.everyone';
          break;
        case 'Mobile Visitors':
          targeting.routeForwarding = 'targeting.mobile';
          break;
        case 'Homepage Visitors':
          targeting.routeForwarding = 'targeting.homepage';
          break;
        case 'Saved':
          targeting.routeForwarding = 'targeting.saved';
          break;
        default:
          targeting.routeForwarding = false;
      }
    }

    return this._super(controller, model);
  },

  //-----------  Actions  -----------#

  // Actions bubble up the routers from most specific to least specific.
  // In order to catch all the actions (beacuse they happen in different
  // routes), the action catch was places in the top-most application route.

  actions: {

    saveSiteElement() {
      this.set("saveCount", this.get("saveCount") + 1);
      if (trackEditorFlow) { InternalTracking.track_current_person("Editor Flow", {step: "Save Bar", goal: this.currentModel.element_subtype, style: this.currentModel.type, save_attempts: this.get("saveCount")}); }

      if (window.barID) {
        var url = `/sites/${window.siteID}/site_elements/${window.barID}.json`;
        var method = "PUT";
      } else {
        var url = `/sites/${window.siteID}/site_elements.json`;
        var method = "POST";
      }

      return Ember.$.ajax({
        type: method,
        url,
        contentType: "application/json",
        data: JSON.stringify(this.currentModel),

        success: () => {
          if (trackEditorFlow) { InternalTracking.track_current_person("Editor Flow", {step: "Completed", goal: this.currentModel.element_subtype, style: this.currentModel.type, save_attempts: this.get("saveCount")}); }
          if (this.controller.get("model.site.num_site_elements") === 0) {
            return window.location = `/sites/${window.siteID}`;
          } else {
            return window.location = `/sites/${window.siteID}/site_elements`;
          }
        },

        error: data => {
          this.controller.toggleProperty('saveSubmitted');
          this.controller.set("model.errors", data.responseJSON.errors);
          return new EditorErrorsModal({errors: data.responseJSON.full_error_messages}).open();
        }
      });
    }
  }
});
