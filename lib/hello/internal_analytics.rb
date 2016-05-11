# The AB Testing module does a few things:
# - it keeps track of all the tests
# - it maintains a cookie to track which test the user has seen. This cookie is a string of
# digits from 0-9. Each digit represents a single test and each value is the variation the
# person saw
# - it tags the user when a new test is seen so we can track it with the backend analytics
module Hello
  module InternalAnalytics
    MAX_TESTS = 4000
    MAX_VALUES_PER_TEST = 10
    TESTS = {}
    VISITOR_ID_COOKIE = :vid
    VISITOR_ID_LENGTH = 40
    USER_ID_NOT_SET_YET = "x"
    AB_TEST_COOKIE = :hb3ab

    class << self
      @@expected_index = 0
      def register_test(name, values, index, weights=[])
        raise "Expected index: #{@@expected_index.inspect}, but got index: #{index.inspect}. You either changed the order of the tests, removed a test, added a test out of order, or did not set the index of a test correctly. Please fix and try again" unless index == @@expected_index
        raise "#{name.inspect} has #{values.length} values, but max is #{MAX_VALUES_PER_TEST}" if values.length > MAX_VALUES_PER_TEST
        sum = weights.inject(0){|result, w| result += w}
        if weights.length < values.length
          remainder = 100-sum
          num_weights_needed = values.length-weights.length
          # We inject n-1 weights this allows the last weight to round up or down as needed
          weights += [(remainder/num_weights_needed)]*(num_weights_needed-1)
          # Determine last weight and add it
          sum = weights.inject(0){|result, w| result += w}
          weights << 100-sum
          sum = weights.inject(0){|result, w| result += w}
        end
        raise "Weighting added up #{sum}, expected 100: #{weights.inspect} for test #{name.inspect}" unless sum == 100
        # Now create ranges out of the weights
        c = 0
        weights.collect! do |weight|
          start_range = c
          end_range = c+weight
          c = end_range
          (start_range...end_range)
        end

        @@expected_index += 1
        TESTS[name] = {:values=>values, :index=>index, :weights=>weights, :name=>name}
      end
    end

    # ==========================================
    # ==      REGISTER YOUR TESTS HERE        ==
    # ==========================================
    unless Rails.env.test?
      register_test("Use Cases Amount",                                           %w{more less}, 0)
      register_test("Account Creation Test 2015-01-21",                           %w{original orange_header no_orange_header}, 1)
      register_test("Editor Test 2015-02-23",                                     %w{original interstitial navigation}, 2)
      register_test("Google Auth 2015-03-10",                                     %w{original google_auth}, 3)
      register_test("Templated Editor 2015-07-07",                                %w{original templated}, 4)
      register_test("Video Welcome 2015-9-22",                                    %w{original video}, 5, [75, 25])
      register_test("Quickstart CTA 2015-10-06",                                  %w{original cta}, 6)
      register_test("Upgrade Plan Button 2016-01-05",                             %w{original power}, 7)
      register_test("Settings Upsell 2016-01-07",                                 %w{original upsell}, 8)
      register_test("Upgrade Modal Logos 2016-01-10",                             %w{original logos}, 9)
      register_test("Email Modal Interstitial 2016-02-23",                        %w{original modal}, 10)
      register_test("Email Modal Interstitial New Users Only 2016-03-04",         %w{original modal}, 11)
      register_test("Sign Up Button 2016-03-17",                                  %w{original sign_up_google sign_up get_started}, 12)
      register_test("Show Add Site on Edit Site 2016-03-18",                      %w{original variant}, 13)
      register_test("WordPress Plugin 2016-03-17",                                %w{original common}, 14)
      register_test("Use Cases Variation 2016-03-22",                             %w{original simple}, 15)
      register_test("Forced Email Path 2016-03-28",                               %w{original force}, 16)
      register_test("Show Add Site on Edit Site 2016-04-04",                      %w{original variant}, 17)
      register_test("Create A Bar Reminder New Users Only 2016-03-28",            %w{original campaign}, 18)
      register_test("Configure Your Bar Reminder New Users Only 2016-03-28",      %w{original campaign}, 19)
      register_test("Install The Plugin Drip Campaign New Users Only 2016-03-28", %w{original campaign}, 20)
      register_test("Upgrade Hello Bar Drip Campaign New Users Only 2016-03-28",  %w{original campaign}, 21)
      register_test("Use Cases Variation 2016-04-22",                             %w{original types}, 22)
      register_test("Onboarding Limitted To Three Goals 2016-05-11",              %w{original variant}, 23)
    end

    def ab_test_cookie_name
      AB_TEST_COOKIE
    end

    def ab_test_cookie_domain
      Hellobar::Settings[:host] == "localhost" ? nil : Hellobar::Settings[:host]
    end

    def get_ab_test_value_index_from_cookie(cookie, index)
      return if cookie == nil
      value = cookie[index..index]
      if value and value =~ /\d+/
        return value.to_i
      end
      nil
    end

    def get_ab_test_value_index_from_id(ab_test, id)
      rand_value = Digest::SHA1.hexdigest([ab_test[:name], id].join("|")).chars.inject(0){|s,o| s+o.ord}

      # See if the test is weighted
      ab_test[:weights].each_with_index do |weight, i|
        return i if weight.include?(rand_value % 100)
      end
      # Return the index
      return rand_value % ab_test[:values].length
    end

    def set_ab_test_value_index_from_cookie(cookie, index, value_index)
      raise "Value: #{value.inspect} is out of range" if value_index > MAX_VALUES_PER_TEST or value_index < 0
      # Make sure there is enough values
      cookie = "" unless cookie
      num_chars_needed = ((index+1)-cookie.length)
      cookie += "x"*num_chars_needed if num_chars_needed > 0
      # Set the value
      cookie[index] = value_index.to_s # Sets the char value to 0-9

      return cookie
    end


    def set_ab_variation(test_name, value)
      # First make sure we have registered this test
      raise "Could not find test: #{test_name.inspect}" unless ab_test = TESTS[test_name]
      # Now make sure the value is a valid value
      value_index = ab_test[:values].index(value)
      raise "Could not find value: #{value.inspect} in test #{test_name.inspect} => #{ab_test.inspect}" unless value_index
      cookie_value = set_ab_test_value_index_from_cookie(cookies[ab_test_cookie_name], ab_test[:index], value_index)
      cookies.permanent[ab_test_cookie_name.to_sym] = cookie_value
    end

    def get_ab_test(test_name)
      # First make sure we have registered this test
      raise "Could not find test: #{test_name.inspect}" unless ab_test = TESTS[test_name]
      return ab_test
    end

    def get_ab_variation_index_without_setting(test_name, user=nil)
      ab_test = get_ab_test(test_name)
      # Now we need to see if we have a value for the index
      if defined?(cookies)
        if index = get_ab_test_value_index_from_cookie(cookies[ab_test_cookie_name], ab_test[:index])
          return index, :existing
        end
      end
      person_type, person_id = current_person_type_and_id(user)
      value_index = get_ab_test_value_index_from_id(ab_test, person_id)
      return value_index, :new
    end

    def get_ab_variation_without_setting(test_name, user=nil)
      ab_test = get_ab_test(test_name)
      value_index, status = get_ab_variation_index_without_setting(test_name, user)
      return unless value_index
      value = ab_test[:values][value_index]
      return value
    end

    def get_ab_variation_or_nil(test_name, user = nil)
      return unless TESTS[test_name]
      get_ab_variation(test_name, user = nil)
    end

    def get_ab_variation(test_name, user = nil)
      ab_test = get_ab_test(test_name)
      value_index, status = get_ab_variation_index_without_setting(test_name, user)
      value = nil

      if status == :new
        if defined?(cookies)
          cookie_value = set_ab_test_value_index_from_cookie(cookies[ab_test_cookie_name], ab_test[:index], value_index)
          cookies.permanent[ab_test_cookie_name.to_sym] = cookie_value
        end

        # Get the value
        value = ab_test[:values][value_index]

        # Track it
        Analytics.track(*current_person_type_and_id(user), test_name, {value: value})
      else
        # Just get the value
        value = ab_test[:values][value_index]
      end

      return value
    end

    def visitor_id
      return unless defined?(cookies)

      unless cookies[VISITOR_ID_COOKIE]
        cookies.permanent[VISITOR_ID_COOKIE] = Digest::SHA1.hexdigest("visitor_#{Time.now.to_f}_#{request.remote_ip}_#{request.env['HTTP_USER_AGENT']}_#{rand(1000)}_id")+USER_ID_NOT_SET_YET # The x indicates this ID has not been persisted yet
        Analytics.track(*current_person_type_and_id, "First Visit", {ip: request.remote_ip})
      end
      # Return the first VISITOR_ID_LENGTH characters of the hash
      return cookies[VISITOR_ID_COOKIE][0...VISITOR_ID_LENGTH]
    end

    def get_user_id_from_cookie
      return unless defined?(cookies)
      visitor_id_cookie = cookies[VISITOR_ID_COOKIE]
      return unless visitor_id_cookie
      return unless visitor_id_cookie.length > VISITOR_ID_LENGTH
      return visitor_id_cookie[VISITOR_ID_LENGTH..-1]
    end

    def current_person_type_and_id(user=nil)
      user ||= current_user if defined?(current_user)
      if user
        # See if a we have an unassociated visitor ID
        if get_user_id_from_cookie == USER_ID_NOT_SET_YET
          # Associate it with the visitor
          Analytics.track(:visitor, visitor_id, :user_id, value: user.id)
          # Mark it as associated
          cookies.permanent[VISITOR_ID_COOKIE] = cookies[VISITOR_ID_COOKIE][0...VISITOR_ID_LENGTH] + user.id.to_s
        end
        return :user, user.id
      else
        # See if we can get a user id
        user_id = get_user_id_from_cookie
        if user_id and user_id != USER_ID_NOT_SET_YET
          return :user, user_id.to_i
        end
        # Return the visitor ID
        return :visitor, visitor_id
      end
    end

    def get_weighted_value_index(ab_test)
      rand_value = rand(100)

      ab_test[:weights].each_with_index do |weight, i|
        return i if weight.include?(rand_value)
      end

      nil
    end
  end
end
