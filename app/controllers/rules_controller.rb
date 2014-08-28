class RulesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site

  def show
    rule = @site.rules.find(params[:id])

    render :json => rule
  end

  def create
    rule = @site.rules.new rule_params.permit!

    if rule.save
      render :json => rule
    else
      render :json => rule.errors, :status => :unprocessable_entity
    end
  end

  def update
    rule = @site.rules.find(params[:id])

    if rule.update_attributes rule_params.permit!
      render :json => rule
    else
      render :json => rule.errors, :status => :unprocessable_entity
    end
  end

  def destroy
    rule = @site.rules.find(params[:id])

    if rule.destroy
      render :json => rule
    else
      render :json => rule.errors, :status => :unprocessable_entity
    end
  end

  private

  def load_site
    @site = current_user.sites.find(params[:site_id])
  rescue ActiveRecord::RecordNotFound
    if request.get? or request.delete?
      render :json => { error: "not_found" }, :status => :not_found
    else
      render :json => { error: "forbidden" }, :status => :forbidden
    end
  end

  def rule_params
    params.require(:rule)
          .permit(:name, :priority, :match, :conditions_attributes => conditions_attrs)
  end

  def conditions_attrs
    [:id, :rule_id, :segment, :operand, :_destroy, { :value => [:start_date, :end_date] }, :value]
  end
end
