require 'spec_helper'
describe Users::OmniauthCallbacksController do
  it 'should use Users::OmniauthCallbacksController' do
    controller.should be_an_instance_of(Users::OmniauthCallbacksController)
  end
end
