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
      @object.stub(:current_user).and_return(@user)
      @object.get_ab_variation_index_without_setting("Example Test").should == [0, :new]
    end

    it "returns current visitor ID if there is no user and no cookies" do
      @object.get_ab_variation_index_without_setting("Example Test").should == [0, :new]
    end
  end
end