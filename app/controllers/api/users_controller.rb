class Api::UsersController < Api::ApplicationController
  def current
    # CurrentUserSerializer is used for campaigns application.
    render json: current_user, serializer: CurrentUserSerializer, context: { list_totals: list_totals }
  end

  private

  def list_totals
    @subscriber_totals ||= begin
      current_user.sites.each_with_object({}) do |site, memo|
        memo.merge!(FetchContactListTotals.new(site).call)
      end
    end
  end
end
