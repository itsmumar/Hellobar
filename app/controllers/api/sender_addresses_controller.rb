class Api::SenderAddressesController < Api::ApplicationController
  before_action :find_address, except: %i[create index]

  def create
    address = SenderAddress.new(address_params)
    address.save!

    render json: address
  end

  def index
    site = Site.find(params[:site_id])

    render json: site.sender_address
  end

  def update
    @address.update!(address_params)
    render json: @address
  end

  private

  def find_address
    @address = SenderAddress.find(params[:id])
  end

  def address_params
    params.require(:sender_address).permit :site_id, :address_one, :address_two, :city, :state, :postal_code, :country
  end
end
