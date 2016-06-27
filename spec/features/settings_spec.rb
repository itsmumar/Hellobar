require "integration_helper"

feature "Manage Settings", js: true do
  before do
    allow_any_instance_of(ApplicationController).
      to receive(:get_ab_variation).and_return('original')
    @user = login
    @site = @user.sites.first
    @rule = @site.create_default_rules
    allow_any_instance_of(Site).to receive(:lifetime_totals).and_return({"1" => [[1,0]]})
    payment_method = create(:payment_method, user: @user)
    @site.change_subscription(Subscription::Pro.new(schedule: "monthly"), payment_method)
    visit edit_site_path(@site)
  end
  after { devise_reset }

  context "add custom invoice address" do
    scenario "is available" do
      expect(page).to have_content("Add custom invoice address")
    end

    scenario "updates when input is given" do
      page.find("a.toggle-site-invoice-information").click
      fill_in "site_invoice_information", :with => "my cool address"
      click_button("Save & Update")
      visit edit_site_path(@site)
      expect(page).to have_content("my cool address")
    end
  end
end
