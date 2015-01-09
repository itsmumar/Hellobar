require "spec_helper"

class ModuleTestingClass
end

describe Hello::ABTesting do
  fixtures :all

  before do
    @object = ModuleTestingClass.new
    @object.extend(Hello::ABTesting)

    @test_index = Hello::ABTesting.class_variable_get("@@expected_index")
    Hello::ABTesting.register_test("Example Test", %w{experiment control}, @test_index)

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

      Hello::Tracking.should_receive(:track_prop).with("visitor", "visitor_id", "Example Test", anything)

      @object.get_ab_variation("Example Test")
    end

    it "uses current_user if available and no explicit user is passed" do
      @object.stub(:current_user).and_return(@user)

      @object.get_ab_variation("Example Test")

      # InternalProp.where(:target_id => @user.id, :target_type => "user", :name => "Example Test").count.should == 1
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
    it "gets the index from the internal props table if a user is available" do
      # InternalProp.create(:target_id => @user.id, :target_type => "user", :name => "Example Test", :value => "control")
      @object.get_ab_variation_index_without_setting("Example Test", @user).should == 1
    end

    it "gets the index from cookies if no user is available" do
      @object.stub(:cookies).and_return({@object.ab_test_cookie_name => "1".rjust(@test_index + 1, "x")})
      @object.get_ab_variation_index_without_setting("Example Test").should == 1
    end

    it "uses current_user if available and no explicit user is passed" do
      @object.stub(:current_user).and_return(@user)
      # InternalProp.create(:target_id => @user.id, :target_type => "user", :name => "Example Test", :value => "control")

      @object.get_ab_variation_index_without_setting("Example Test").should == 1
    end

    it "returns nil if there is no user and no cookies" do
      @object.get_ab_variation_index_without_setting("Example Test").should == nil
    end
  end
end
