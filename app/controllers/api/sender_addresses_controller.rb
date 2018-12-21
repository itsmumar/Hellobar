class Api::SenderAddressesController < Api::ApplicationController
  before_action :find_address, except: %i[create index]

  before_action :verify_owner_site_id

  def create
    address = SenderAddress.new(address_params.merge(site_id: params[:site_id]))
    address.save!

    render json: address
  end

  def index
    site = current_user.sites.find(params[:site_id])

    render json: site.sender_address
  end

  def update
    @address.update!(address_params)
    render json: @address
  end

  private

  def verify_owner_site_id
    if current_user.sites.map(&:id).include?(params[:site_id].to_i)
      return true
    else
      return render json: {} #handle with 401.
    end
  end

  def find_address
    @address = SenderAddress.find(params[:id])
  end

  def address_params
    params.require(:sender_address).permit(:address_one, :address_two, :city, :state, :postal_code, :country)
  end
end
