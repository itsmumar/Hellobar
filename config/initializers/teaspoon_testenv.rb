# module HelloBar
#   module TeaspoonSessions
#     class << self
#       def included base
#         base.send :before_filter, append: true do
#           if current_user
#             @site = current_user.sites.first
#             @site_element = @site.site_elements.first
#           else
#             raise 'Only create test users in test mode.' unless Rails.env.test?
#             @user = User.find_by_email('test@test.com') || test_user
#             sign_in @user

#             unless @site = current_user.sites.first
#               @site = Site.create(url: "www.test.com")
#             end

#             unless @site_element = @site.site_elements.first
#               rule = Rule.new
#               @site_element = SiteElement.new(element_subtype: 'email')
#               rule.site_elements << @site_element
#               @site.rules << rule
#             end
#           end
#         end

#         base.send :after_filter do
#           sign_out :user
#         end
#       end

#       def test_user
#         User.create!(email: 'test@test.com', password: 'asdfasdf', password_confirmation: 'asdfasdf')
#       end
#     end
#   end
# end

# Teaspoon::SuiteController.send :include, HelloBar::TeaspoonSessions
