class Admin::PartnersController < AdminController
  respond_to :html

  def index
    @partners = Partner.all
    respond_with(@partners)
  end

  def new
    @partner = Partner.new
    respond_with(@partner)
  end

  def create
    @partner = Partner.new
    respond_with(@partner.update(partner_params), location: admin_partners_path)
  end

  def edit
    @partner = Partner.find(params[:id])
    respond_with(@partner)
  end

  def update
    @partner = Partner.find(params[:id])
    respond_with(@partner.update(partner_params), location: admin_partners_path)
  end

  def destroy
    @partner = Partner.find(params[:id])
    respond_with(@partner.destroy, location: admin_partners_path)
  end

  private

  def partner_params
    params.require(:partner).permit(:name, :email, :url)
  end
end
