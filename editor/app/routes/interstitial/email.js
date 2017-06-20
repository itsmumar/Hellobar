import Ember from 'ember';
import InterstitialNestedRouteMixin from '../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  createDefaultContactList(model) {
    if (Ember.get(model, 'site.contact_lists').length === 0 || Ember.get(model, 'contact_list_id') === 0) {
      if (Ember.get(model, 'site.contact_lists').length > 0) {
        return Ember.set(model, 'contact_list_id', Ember.get(model, 'site.contact_lists')[0].id);
      } else {
        return $.ajax(`/sites/${Ember.get(model, 'site.id')}/contact_lists.json`, {
            type: 'POST',
            data: {contact_list: {name: 'My Contacts', provider: 0, provider_name: 'Hello Bar', double_optin: 0}},
            success: data => {
              Ember.set(model, 'site.contact_lists', [data]);
              Ember.set(model, 'contact_list_id', data.id);
            },
            error: (/* response */) => {}
          }
        );
      }
    }
  },

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Join our mailing list to stay up to date on our upcoming events',
      'link_text': 'Subscribe',
      'element_subtype': 'email'
    });
    this.createDefaultContactList(model);
  }

});
