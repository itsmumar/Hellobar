class ModuleTestingClass
  def cookies
    @cookies ||= ActionDispatch::Cookies::CookieJar.new('key_generator')
  end

  def current_user
  end

  def request
    @request ||= ActionDispatch::Request.new({})
  end
end

describe Hello::InternalAnalytics do
  before(:each) do
    Hello::InternalAnalytics.tests = {}
    Hello::InternalAnalytics.instance_variable_set(:@expected_index, 0)
  end

  context 'class methods' do
    describe 'load_ab_tests' do
      it 'has tests present' do
        expect(Hello::InternalAnalytics.tests.size).to eq(0)
        Hello::InternalAnalytics.load_ab_tests
        expect(Hello::InternalAnalytics.tests.size).not_to eq(0)
      end
    end
  end

  context 'instance methods' do
    before do
      object.extend(Hello::InternalAnalytics)

      Hello::InternalAnalytics.register_test('Example Test', %w[experiment control], test_index)
      Hello::InternalAnalytics.register_test('Weighted Test', %w[experiment control], test_index + 1, [10, 90])
      Hello::InternalAnalytics.register_test('Time Constraint Test', %w[experiment control], test_index + 2, [], '2016-05-11'.to_datetime)
    end

    let(:test_index) { Hello::InternalAnalytics.instance_variable_get('@expected_index') }
    let(:object) { ModuleTestingClass.new }
    let(:user) { create(:user) }
    let(:cookies) { ActionDispatch::Cookies::CookieJar.new('key_generator') }

    describe 'ab_variation' do
      it 'creates an internal prop if a user is available' do
        object.ab_variation('Example Test', user)
      end

      it 'records the value index in cookie if cookies are availble' do
        cookies[:vid] = 'visitor_id'
        allow(object).to receive(:cookies) { cookies }

        value = object.ab_variation('Example Test')
        value_index = object.ab_test('Example Test')[:values].index(value)

        expect(object.cookies[object.ab_test_cookie_name][test_index]).to eql(value_index.to_s)
      end

      it 'raises an error if cookies, current_user, or user are not present' do
        allow(object).to receive(:current_user) { nil }
        allow(object.cookies).to receive(:present?).and_return(false)

        expect { object.ab_variation('Example Test') }.to raise_error('Cookies or user must be present for A/B test')
      end
    end

    describe 'ab_variation_index_without_setting' do
      it 'gets the index from cookies if no user is available' do
        allow(object).to receive(:cookies).and_return(object.ab_test_cookie_name => '1'.rjust(test_index + 1, 'x'))
        expect(object.ab_variation_index_without_setting('Example Test')).to eq([1, :existing])
      end

      it 'uses current_user if available and no explicit user is passed' do
        allow(object).to receive(:current_user) { user }
        allow(object).to receive(:ab_test_value_index_from_id).with(anything, user.id) { 123 }
        expect(object.ab_variation_index_without_setting('Example Test')).to eq([123, :new])
      end

      it 'returns current visitor ID if there is no user and no cookies' do
        allow(object).to receive(:user_id_from_cookie).and_return(0)
        expect(object.ab_variation_index_without_setting('Example Test')).to eq([0, :new])
      end
    end

    describe 'ab_test_value_index_from_id' do
      it 'uses weights to determine index when available' do
        ab_test = object.ab_test('Weighted Test')
        # person id 4 evaluates to rand_value 6, so it should return the first test value
        # person id 1 evaluates to rand_value 16, so it should return the second test value
        expect(object.ab_test_value_index_from_id(ab_test, 4)).to eq(0)
        expect(object.ab_test_value_index_from_id(ab_test, 1)).to eq(1)
      end
    end

    describe 'ab_test_passes_time_constraints?' do
      it 'passes if no time constraint is given' do
        expect(object.ab_test_passes_time_constraints?('Example Test')).to eq(true)
      end

      it 'does not pass if user_start_date time constraint is after the user was created' do
        user.update_attributes(created_at: object.ab_test('Time Constraint Test')[:user_start_date] - 10.days)
        object.ab_test('Time Constraint Test')
        allow_any_instance_of(ModuleTestingClass).to receive(:current_user) { user }
        expect(object.ab_test_passes_time_constraints?('Time Constraint Test')).to eq(false)
      end
    end
  end
end
