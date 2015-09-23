module ControllerSpecHelper
  def expect_json_response_to_include(json)
    json_response = parse_json_response

    expect(json_response).to include(json)
  end

  def expect_json_to_have_error(attr, message)
    json_response = parse_json_response
    errors = json_response[:errors].try(:with_indifferent_access)

    expect(errors[attr]).to include(message)
  end

  def parse_json_response
    JSON.parse(response.body).with_indifferent_access
  end
end
