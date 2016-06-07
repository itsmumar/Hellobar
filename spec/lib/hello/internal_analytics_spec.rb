require "spec_helper"

class ModuleTestingClass
end

describe Hello::InternalAnalytics do
  fixtures :all

  before do
    @object = ModuleTestingClass.new
    @object.extend(Hello::InternalAnalytics)

    @test_index = Hello::InternalAnalytics.class_variable_get("@@expected_index")
    Hello::InternalAnalytics.register_test("Example Test", %w{experiment control}, @test_index)
    Hello::InternalAnalytics.register_test("Weighted Test", %w{experiment control}, @test_index + 1, [10, 90])
    Hello::InternalAnalytics.register_test("Time Constraint Test", %w{experiment control}, @test_index + 2, [], '2016-05-11'.to_datetime)

    @cookies = ActionDispatch::Cookies::CookieJar.new("key_generator")
    @user = users(:joey)
  end

  describe "get_ab_variation" do
    it "creates an internal prop if a user is available" do
      @object.get_ab_variation("Example Test", @user)
      # InternalProp.where(:target_id => @user.id, :target_type => "user", :name => "Example Test").count.should == 1
    end

    it "tracks a visitor prop if no user is available, but cookies are" do
      @cookies[:vid] = "visitor_id"
      @object.stub(:cookies).and_return(@cookies)

      Analytics.should_receive(:track).with(:visitor, "visitor_id", "Example Test", anything)

      @object.get_ab_variation("Example Test")
    end

    it "uses current_user if available and no explicit user is passed" do
      @object.stub(:current_user).and_return(@user)

      Analytics.should_receive(:track).with(:user, @user.id, "Example Test", anything)
      @object.get_ab_variation("Example Test")
    end

    it "records the value index in cookie if cookies are availble" do
      @cookies[:vid] = "visitor_id"
      @object.stub(:cookies).and_return(@cookies)

      value = @object.get_ab_variation("Example Test")
      value_index = @object.get_ab_test("Example Test")[:values].index(value)

      @object.cookies[@object.ab_test_cookie_name][@test_index].should == value_index.to_s
    end
  end

  describe "get_ab_variation_index_without_setting" do
    it "gets the index from cookies if no user is available" do
      @object.stub(:cookies).and_return({@object.ab_test_cookie_name => "1".rjust(@test_index + 1, "x")})
      @object.get_ab_variation_index_without_setting("Example Test").should == [1, :existing]
    end

    it "uses current_user if available and no explicit user is passed" do
      allow(@object).to receive(:current_user).and_return(@user)
      allow(@object).to receive(:get_ab_test_value_index_from_id).with(anything, @user.id).and_return(123)
      expect(@object.get_ab_variation_index_without_setting("Example Test")).to eq([123, :new])
    end

    it "returns current visitor ID if there is no user and no cookies" do
      @object.get_ab_variation_index_without_setting("Example Test").should == [0, :new]
    end
  end

  describe "get_ab_test_value_index_from_id" do
    it "receives an array of values" do
      ab_test = @object.get_ab_test("Weighted Test")
      expect(ab_test[:values].is_a?(Array)).to eq(true)
    end

    it "uses weights to determine index when available" do
      ab_test = @object.get_ab_test("Weighted Test")
      # person id 4 evaluates to rand_value 6, so it should return the first test value
      # person id 1 evaluates to rand_value 16, so it should return the second test value
      expect(@object.get_ab_test_value_index_from_id(ab_test, 4)).to eq(0)
      expect(@object.get_ab_test_value_index_from_id(ab_test, 1)).to eq(1)
    end
  end

  describe "ab_test_passes_time_constraints?" do
    it "passes if no time constraint is given" do
      expect(@object.ab_test_passes_time_constraints?("Example Test")).to eq(true)
    end

    it "does not pass if user_start_date time constraint is after the user was created" do
      @user.update_attributes(created_at: @object.get_ab_test("Time Constraint Test")[:user_start_date] - 10.days)
      ab_test = @object.get_ab_test("Time Constraint Test")
      allow_any_instance_of(ModuleTestingClass).to receive(:current_user).and_return(@user)
      expect(@object.ab_test_passes_time_constraints?("Time Constraint Test")).to eq(false)
    end
  end

end
