# The AB Testing module does a few things:
# - it keeps track of all the tests
# - it maintains a cookie to track which test the user has seen. This cookie is a string of 
# digits from 0-9. Each digit represents a single test and each value is the variation the
# person saw
# - it tags the user when a new test is seen so we can track it with the backend analytics
module Hello
  module ABTesting
    MAX_TESTS = 4000
    MAX_VALUES_PER_TEST = 10
    TESTS = {}

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
    register_test("Bar Creation: Simple", %w{original simpler}, 0)
    register_test("Homepage: Test 1", %w{home home2}, 1)
    register_test("Homepage: Test 2", %w{home2 home3}, 2)
    register_test("Homepage: Test 3", %w{home3 home4 home5}, 3)
    register_test("Homepage: Test 4", %w{home3 home3b home4 home4b}, 4)
    register_test("Homepage: Test 5", %w{home3b home6 home6b}, 5, [50, 25, 25])
    register_test("Bar Suggestion: Test 1 (Suggestion Type)", %w{control color content mobile}, 6, [50, 17, 17, 16])
    register_test("Homepage: Test 6", %w{home6 home7}, 7)
    register_test("Bar Suggestion: Test 2 (Multiple Suggestions)", %w{color_and_mobile color mobile}, 8, [50, 25, 25])
    register_test("Homepage: Test 7", %w{home6 home_a1 home_a2 home_a3 home_a4 home_b1 home_b2 home_b3 home_b4}, 9, [52, 6, 6, 6, 6, 6, 6, 6, 6])
    register_test("Bar Creation: Dont Worry", %w{original added_text}, 10)
    register_test("Homepage: Test 8", %w{home6 home_a1 home_a2 home_a3 home_a4 home_b1 home_b2 home_b3 home_b4}, 11, [52, 6, 6, 6, 6, 6, 6, 6, 6])
    register_test("Email Drip 1: No bars", %w{control experiment}, 12, [50, 50])
    register_test("Email Drip 2: Not installed", %w{control experiment}, 13, [50, 50])
    register_test("Email Drip 3: Only one bar", %w{control experiment}, 14, [50, 50])

    def ab_test_cookie_name
      'hb2ab'
    end

    def ab_test_cookie_domain
      Hellobar::Settings[:host] == "localhost" ? nil : Hellobar::Settings[:host]
    end

    def get_ab_test_value_index_from_cookie(cookie, index)
      return nil if cookie == nil
      value = cookie[index..index]
      if value and value =~ /\d+/
        return value.to_i
      end
      return nil
    end

    def get_ab_test_value_index_from_db(ab_test, user)
      prop = InternalProp.where(:target_type => "user", :target_id => user.id, :name => ab_test[:name]).first
      prop ? ab_test[:values].index(prop.value) : nil
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

    def visitor_id
      return nil unless defined?(cookies)

      unless cookies[:vid]
        cookies.permanent[:vid] = Digest::SHA1.hexdigest("visitor_#{Time.now.to_f}_#{request.remote_ip}_#{request.env['HTTP_USER_AGENT']}_#{rand(1000)}_id")
      end
      return cookies[:vid]
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

    def get_ab_variation_index_without_setting(test_name, user = nil)
      ab_test = get_ab_test(test_name)
      user ||= current_user if defined?(current_user)

      # Now we need to see if we have a value for the index
      if user
        return get_ab_test_value_index_from_db(ab_test, user)
      elsif defined?(cookies)
        return get_ab_test_value_index_from_cookie(cookies[ab_test_cookie_name], ab_test[:index])
      else
        return nil
      end
    end

    def get_ab_variation_without_setting(test_name)
      ab_test = get_ab_test(test_name)
      value_index = get_ab_variation_index_without_setting(test_name)
      return nil unless value_index
      value = ab_test[:values][value_index]
      return value
    end

    def get_ab_variation(test_name, user = nil)
      ab_test = get_ab_test(test_name)
      user ||= current_user if defined?(current_user)
      value_index = get_ab_variation_index_without_setting(test_name, user)
      value = nil

      if !value_index
        # Determine a new one and set it
        value_index = get_weighted_value_index(ab_test) || rand(ab_test[:values].length)

        if defined?(cookies)
          cookie_value = set_ab_test_value_index_from_cookie(cookies[ab_test_cookie_name], ab_test[:index], value_index)
          cookies.permanent[ab_test_cookie_name.to_sym] = cookie_value
        end

        # Get the value
        value = ab_test[:values][value_index]

        # Tag the user
        if user
          InternalProp.create(:target_type => "user", :target_id => user.id, :name => test_name, :value => value, :timestamp => Time.now.to_i)
        elsif visitor_id
          Hello::Tracking.track_prop('visitor', visitor_id, test_name, value)
        end
      else
        # Just get the value
        value = ab_test[:values][value_index]
      end

      return value
    end

    def get_weighted_value_index(ab_test)
      rand_value = rand(100)

      ab_test[:weights].each_with_index do |weight, i|
        return i if weight.include?(rand_value)
      end

      return nil
    end
  end
end
