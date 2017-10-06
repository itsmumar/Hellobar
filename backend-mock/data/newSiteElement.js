module.exports = {
  "id": null,
  "site": {
    "id": 3,
    "url": "http://hellobar.sergey-shakhov.com",
    "contact_lists": [{"id": 3, "name": "My Contacts", "provider": "Hello Bar"}],
    "capabilities": {
      "remove_branding": false,
      "custom_targeted_bars": false,
      "at_site_element_limit": false,
      "custom_thank_you_text": false,
      "after_submit_redirect": false
    },
    "display_name": "hellobar.sergey-shakhov.com",
    "current_subscription": {
      "schedule": "monthly",
      "type": "free",
      "yearly_amount": "0",
      "monthly_amount": "0",
      "trial": false,
      "payment_method_details_id": null,
      "payment_method_number": null,
      "payment_valid": true
    },
    "script_installed": true,
    "site_elements_count": 2,
    "view_billing": true,
    "timezone": null
    }, {
      "id": 8,
      "site_id": 3,
      "name": "Mobile Visitors",
      "match": "all",
      "description": "Device is mobile",
      "editable": false,
      "conditions": [{
        "id": 5,
        "rule_id": 8,
        "segment": "DeviceCondition",
        "operand": "is",
        "value": "mobile"
      }]
    }, {
      "id": 9,
      "site_id": 3,
      "name": "Homepage Visitors",
      "match": "all",
      "description": "URL Path is /",
      "editable": false,
      "conditions": [{
        "id": 6,
        "rule_id": 9,
        "segment": "UrlPathCondition",
        "operand": "is",
        "value": ["/"]
      }]
    }]
  },
  "rule_id": 7,
  "rule": {
    "id": 7,
    "site_id": 3,
    "name": "Everyone",
    "match": "all",
    "description": "Show this to everyone",
    "editable": false,
    "conditions": []
  },
  "contact_list_id": null,
  "errors": {},
  "full_error_messages": [],
  "type": "Bar",
  "element_subtype": null,
  "settings": {"url": "http://hellobar.sergey-shakhov.com", "url_to_like": "http://hellobar.sergey-shakhov.com"},
  "view_condition": "immediately",
  "phone_number": null,
  "phone_country_code": "US",
  "blocks": [],
  "headline": null,
  "caption": null,
  "link_text": "Click Here",
  "font_id": "open_sans",
  "thank_you_text": null,
  "email_placeholder": "Your email",
  "name_placeholder": "Your name",
  "preset_rule_name": "Everyone",
  "background_color": "eb593c",
  "border_color": "ffffff",
  "button_color": "000000",
  "link_color": "ffffff",
  "text_color": "ffffff",
  "closable": false,
  "show_branding": true,
  "pushes_page_down": true,
  "remains_at_top": true,
  "animated": true,
  "wiggle_button": false,
  "theme_id": "classic",
  "image_url": null,
  "image_placement": "bottom",
  "active_image_id": null,
  "image_file_name": null,
  "use_default_image": true,
  "question": null,
  "answer1": null,
  "answer2": null,
  "answer1response": null,
  "answer2response": null,
  "answer1caption": null,
  "answer2caption": null,
  "answer1link_text": null,
  "answer2link_text": null,
  "use_question": false,
  "question_placeholder": "First time here?",
  "answer1_placeholder": "Yes",
  "answer2_placeholder": "No",
  "answer1response_placeholder": "Welcome! Let?s get started...",
  "answer2response_placeholder": "Welcome back! Check out our new sale.",
  "answer1link_text_placeholder": "Take the tour",
  "answer2link_text_placeholder": "Shop now",
  "updated_at": null,
  "link_style": "button",
  "size": "large",
  "site_preview_image": "/proxy/https/api.url2png.com/v6/P52EBC321291EF/7765925f00baf2a12be38e58d21a7d8c/png/?url=http%3A%2F%2Fhellobar.sergey-shakhov.com\u0026custom_css_url=http%3A%2F%2Fstaging.hellobar.com%2Fstylesheets%2Fhide_bar.css\u0026ttl=604800",
  "site_preview_image_mobile": "/proxy/https/api.url2png.com/v6/P52EBC321291EF/cd3e884f1676f50035dae2d449b69328/png/?url=http%3A%2F%2Fhellobar.sergey-shakhov.com\u0026viewport=320x568\u0026custom_css_url=http%3A%2F%2Fstaging.hellobar.com%2Fstylesheets%2Fhide_bar.css\u0026ttl=604800",
  "open_in_new_window": false,
  "placement": null,
  "default_email_thank_you_text": "Thank you for signing up! If you'd like this sort of bar on your site..."
};
