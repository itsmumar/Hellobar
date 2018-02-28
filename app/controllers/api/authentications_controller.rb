class Api::AuthenticationsController < ApplicationController
  def show
    if current_user && current_site
      render json: current_user,
             serializer: CurrentUserSerializer,
             context: serializer_context
    else
      head 403
    end
  end

  private

  def token
    JsonWebToken.encode(user_id: current_user.id)
  end

  def serializer_context
    {
      list_totals: list_totals,
      site_id: current_site.id,
      token: token
    }
  end

  def list_totals
    @subscriber_totals ||= begin
      current_user.sites.each_with_object({}) do |site, memo|
        memo.merge!(FetchContactListTotals.new(site).call)
      end
    end
  end
end
