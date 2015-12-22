require 'spec_helper'

describe Referral do
  describe Referral.new do
    before do
      @referral = Referral.new
    end

    it "can produce an invite body" do
      @referral.invitation_body(name: "Alice").should match("Alice")
    end
  end
end
