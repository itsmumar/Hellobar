class Api::SenderAddressesController < Api::ApplicationController
  before_action :find_address, except: %i[create]

  def create
    address = SenderAddress.new(address_params)
    address.save!

    render json: address
  end

  def show
    render json: @address
  end

  def update
    @address.update!(email_params)
    render json: @email
  end

  private

  def find_address
    @address = SenderAddress.find(params[:id])
  end

  def address_params
    params.require(:address).permit :site_id, :address_one, :address_two, :city, :state, :postal_code, :country
  end
end
