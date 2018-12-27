class Api::SenderAddressesController < Api::ApplicationController
  before_action :set_site
  before_action :find_sender_address, except: %i[create index]

  def create
    address = @site.build_sender_address(address_params)
    address.save!

    render json: address
  end

  def index
    render json: @site.sender_address
  end

  def update
    @sender_address.update!(address_params)
    render json: @sender_address
  end

  private

  def set_site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def find_sender_address
    @sender_address = @site.sender_address
  end

  def address_params
    params.require(:sender_address).permit(:address_one, :address_two, :city, :state, :postal_code, :country)
  end
end
