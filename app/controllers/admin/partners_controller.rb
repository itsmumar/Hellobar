class Admin::PartnersController < AdminController
  respond_to :html
  responders :flash

  def index
    @partners = Partner.all
    respond_with(@partners)
  end

  def new
    @partner = Partner.new
    respond_with(@partner)
  end

  def create
    @partner = Partner.new(partner_params)
    @partner.save
    respond_with(@partner, location: admin_partners_path)
  end

  def edit
    @partner = Partner.find(params[:id])
    respond_with(@partner)
  end

  def update
    @partner = Partner.find(params[:id])
    @partner.update(partner_params)
    respond_with(@partner, location: admin_partners_path)
  end

  def destroy
    @partner = Partner.find(params[:id])
    @partner.destroy
    respond_with(@partner, location: admin_partners_path)
  end

  private

  def partner_params
    params.require(:partner).permit(:first_name, :last_name, :email, :url, :website_url, :affiliate_identifier, :partner_plan_id)
  end
end
