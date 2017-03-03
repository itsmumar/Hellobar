require 'spec_helper'
require 'synchronizer'

class Synchronizable
  include Synchronizer
end

describe Synchronizer do
  subject { Synchronizable.new }

  it 'should raise an error in #sync_all!' do
    expect { subject.sync_all! }.to raise_error(NoMethodError, /You must require a specific synchronizer/)
  end

  it 'should raise an error in #sync_one!' do
    expect { subject.sync_one!({}, 'name') }.to raise_error(NoMethodError, /You must require a specific/)
  end
end
