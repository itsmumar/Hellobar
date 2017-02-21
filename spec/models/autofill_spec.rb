require 'spec_helper'

describe Autofill do

  it { should validate_presence_of :site }
  it { should validate_presence_of :name }
  it { should validate_presence_of :listen_selector }
  it { should validate_presence_of :populate_selector }

end
