import Ember from 'ember';

export default Ember.Controller.extend({

  showEmailVolume: false,

  monthlyPageviews: ( function () {
    return this.get("model.site.monthly_pageviews") || 0;
  }).property(),

  formattedMonthlyPageviews: ( function () {
    return this.get("monthlyPageviews").toLocaleString();
  }).property(),

  hasEnoughSubscribers: ( function () {
    return this.get("monthlyPageviews") > 1000;
  }).property(),

  calculatedSubscribers: ( function () {
    return Math.round(this.get("monthlyPageviews") * 0.005);
  }).property(),

  formattedCalculatedSubscribers: ( function () {
    return this.get("calculatedSubscribers").toLocaleString();
  }).property(),

  createDefaultContactList() {
    if (this.get("model.site.contact_lists").length === 0 || this.get("model.contact_list_id") === 0) {
      if (this.get("model.site.contact_lists").length > 0) {
        return this.set("model.contact_list_id", this.get("model.site.contact_lists")[0].id);
      } else {
        return $.ajax(`/sites/${this.get("model.site.id")}/contact_lists.json`, {
            type: "POST",
            data: {contact_list: {name: "My Contacts", provider: 0, provider_name: 'Hello Bar', double_optin: 0}},
            success: data => {
              this.set("model.site.contact_lists", [data]);
              return this.set("model.contact_list_id", data.id);
            },
            error: response => {
            }
          }
        );
      }
    }
  },
  // Failed to create default list.  Without a list set a user will see the ContactListModal

  setDefaults() {
    if (!this.get("model")) {
      return false;
    }

    this.set("model.headline", "Join our mailing list to stay up to date on our upcoming events");
    this.set("model.link_text", "Subscribe");
    this.set("model.element_subtype", "email");
    return this.createDefaultContactList();
  },

  inputIsInvalid: ( function () {
    return !!(
      Ember.isEmpty(this.get("model.headline")) ||
      Ember.isEmpty(this.get("model.link_text"))
    );
  }).property(
    "model.link_text",
    "model.headline"
  ),

  actions: {
    closeInterstitial() {
      return this.transitionToRoute("goals.email");
    }
  }
});
