module ControllerSpecHelper
  require 'support/ab_test_config'
  
  def expect_json_response_to_include(json)
    json_response = parse_json_response

    expect(json_response).to include(json)
  end

  def expect_json_to_have_error(attr, message)
    errors = parse_json_errors.try(:with_indifferent_access)

    expect(errors[attr]).to include(message)
  end

  def expect_json_to_have_base_error(message)
    errors = parse_json_errors

    expect(errors).to include(message)
  end

  def parse_json_errors
    json_response = parse_json_response
    json_response[:errors]
  end

  def parse_json_response
    JSON.parse(response.body).with_indifferent_access
  end
end
