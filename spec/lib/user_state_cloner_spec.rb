require 'spec_helper'

describe UserStateCloner, '#save' do
  let(:json) { {"user"=>{"id"=>321624, "email"=>"graham@whatifwhynotfestival.com", "created_at"=>"2016-03-13T17:59:53.000Z", "updated_at"=>"2016-04-14T16:54:44.000Z", "first_name"=>"Graham", "last_name"=>"Clarke", "status"=>"active", "deleted_at"=>nil, "invite_token"=>nil, "invite_token_expire_at"=>nil, "wordpress_user_id"=>nil}, "sites"=>[{"id"=>286334, "created_at"=>"2016-03-13T17:59:54.000Z", "updated_at"=>"2016-04-23T04:37:15.000Z", "url"=>"http://whynotadventurefilmfestival.com", "opted_in_to_email_digest"=>true, "script_installed_at"=>"2016-04-11T19:03:36.000Z", "script_generated_at"=>"2016-04-23T04:37:18.000Z", "script_attempted_to_generate_at"=>"2016-04-23T04:37:15.000Z", "read_key"=>"cb68ca10-ccda-42e8-9aae-dd49db140a85", "write_key"=>"8ef7ae95-e7c3-431b-b340-55442887d425", "timezone"=>nil, "deleted_at"=>nil, "script_uninstalled_at"=>"2016-04-23T04:37:15.000Z", "install_type"=>nil, "invoice_information"=>nil}], "site_memberships"=>[{"id"=>285309, "user_id"=>321624, "site_id"=>286334, "role"=>"owner", "created_at"=>"2016-03-13T17:59:54.000Z", "updated_at"=>"2016-03-13T17:59:54.000Z", "deleted_at"=>nil}], "rules"=>[{"id"=>320510, "site_id"=>286334, "name"=>"Everyone", "priority"=>nil, "match"=>"all", "editable"=>false, "conditions"=>[]}], "site_elements"=>[{"id"=>253168, "created_at"=>"2016-03-13T18:09:21.000Z", "updated_at"=>"2016-03-30T06:33:27.000Z", "element_subtype"=>"email", "target_segment"=>nil, "closable"=>false, "show_border"=>false, "background_color"=>"e1a418", "border_color"=>"ffffff", "button_color"=>"ffffff", "font"=>"'Open Sans',sans-serif", "link_color"=>"a5644c", "link_style"=>"button", "link_text"=>"Sign me up!", "headline"=>"Join our mailing list to stay up to date with #WNAFF16", "size"=>"large", "target"=>nil, "text_color"=>"ffffff", "texture"=>"none", "paused"=>true, "rule_id"=>320510, "settings"=>{"collect_names"=>1, "after_email_submit_action"=>0, "url"=>"http://whynotadventurefilmfestival.com", "url_to_like"=>"http://whynotadventurefilmfestival.com"}, "show_branding"=>true, "contact_list_id"=>141063, "display_when"=>"immediately", "thank_you_text"=>nil, "pushes_page_down"=>true, "remains_at_top"=>true, "open_in_new_window"=>false, "animated"=>true, "wiggle_button"=>false, "wordpress_bar_id"=>nil, "caption"=>"", "placement"=>nil, "deleted_at"=>nil, "view_condition"=>"immediately", "email_placeholder"=>"Your email goes here", "name_placeholder"=>"Your name (first name will do)", "image_upload_id"=>nil, "image_placement"=>"bottom", "active_image_id"=>13029, "question"=>nil, "answer1"=>nil, "answer2"=>nil, "answer1response"=>nil, "answer2response"=>nil, "answer1link_text"=>nil, "answer2link_text"=>nil, "answer1caption"=>nil, "answer2caption"=>nil, "use_question"=>false, "phone_number"=>nil, "phone_country_code"=>"US", "show_after_convert"=>false}, {"id"=>259251, "created_at"=>"2016-03-30T06:28:31.000Z", "updated_at"=>"2016-03-30T06:28:31.000Z", "element_subtype"=>"email", "target_segment"=>nil, "closable"=>false, "show_border"=>false, "background_color"=>"a4644c", "border_color"=>"ffffff", "button_color"=>"ffffff", "font"=>"'Open Sans',sans-serif", "link_color"=>"a4644c", "link_style"=>"button", "link_text"=>"Join us on the journey. ", "headline"=>"WNAFF16 kicks off at the end of September 2016. Join our newsletter to stay up to date.", "size"=>"regular", "target"=>nil, "text_color"=>"ffffff", "texture"=>"none", "paused"=>false, "rule_id"=>320510, "settings"=>{"after_email_submit_action"=>0, "collect_names"=>1, "url"=>"http://whynotadventurefilmfestival.com", "url_to_like"=>"http://whynotadventurefilmfestival.com"}, "show_branding"=>true, "contact_list_id"=>143640, "display_when"=>"immediately", "thank_you_text"=>nil, "pushes_page_down"=>true, "remains_at_top"=>true, "open_in_new_window"=>false, "animated"=>true, "wiggle_button"=>false, "wordpress_bar_id"=>nil, "caption"=>nil, "placement"=>"bar-top", "deleted_at"=>nil, "view_condition"=>"exit-intent", "email_placeholder"=>"Your email goes here", "name_placeholder"=>"Your first name will do", "image_upload_id"=>nil, "image_placement"=>"bottom", "active_image_id"=>nil, "question"=>nil, "answer1"=>nil, "answer2"=>nil, "answer1response"=>nil, "answer2response"=>nil, "answer1link_text"=>nil, "answer2link_text"=>nil, "answer1caption"=>nil, "answer2caption"=>nil, "use_question"=>false, "phone_number"=>nil, "phone_country_code"=>"US", "show_after_convert"=>false}], "payment_methods"=>[{"id"=>1, "user_id"=>1, "created_at"=>"2016-04-28T21:06:18.000Z", "updated_at"=>"2016-04-28T21:06:18.000Z", "deleted_at"=>nil}]}.to_json }

  it 'creates the user' do
    cloner = UserStateCloner.new(json)

    expect {
      cloner.save
    }.to change{User.exists?(321624)}.from(false).to(true)
  end

  it 'resets the user password' do
    cloner = UserStateCloner.new(json)
    cloner.save

    user = User.find(321624)

    expect(user.valid_password?('password')).to be_true
  end

  it 'creates the sites' do
    cloner = UserStateCloner.new(json)

    expect {
      cloner.save
    }.to change{Site.exists?(286334)}.from(false).to(true)
  end

  it 'creates the site memberships' do
    UserStateCloner.new(json).save

    user = User.find(321624)
    site = Site.find(286334)

    expect(user.sites).to include(site)
  end

  it 'creates the rules' do
    expect {
      UserStateCloner.new(json).save
    }.to change{Rule.exists?(320510)}.from(false).to(true)
  end

  it 'creates the site elements' do
    UserStateCloner.new(json).save

    expect{SiteElement.exists?(253168)}.to be_true
    expect{SiteElement.exists?(259251)}.to be_true
  end

  it 'creates the payment methods' do
    UserStateCloner.new(json).save

    expect{PaymentMethod.exists?(1)}.to be_true
  end
end
