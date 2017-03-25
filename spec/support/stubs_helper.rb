module StubsHelper
  def stub_current_admin(admin)
    allow(controller).to receive(:current_admin).and_return(admin)
  end

  def stub_current_user(user)
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)

    user
  end

  def stub_out_ab_variations(*variations)
    variation_matcher = Regexp.new(variations.join('|'))

    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation)
            .with(variation_matcher)
            .and_return(yield)

    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation)
            .with(variation_matcher, anything)
            .and_return(yield)

    allow_any_instance_of(ApplicationController)
      .to receive(:ab_variation_or_nil)
            .with(variation_matcher)
            .and_return(yield)
  end
end
