class RulesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_site

  def show
    rule = @site.rules.find(params[:id])

    render :json => rule
  end

  def create
    rule = @site.rules.new params.require(:rule).permit(:name, :priority, :match)

    if rule.save
      render :json => rule
    else
      render :json => rule.errors, :status => :unprocessable_entity
    end
  end

  def update
    rule = @site.rules.find(params[:id])

    conditions_attrs = [:id, :rule_id, :segment, :operand, :_destroy, { :value => [:start_date, :end_date] }, :value]
    rule_attrs = params.require(:rule)
                       .permit(:name, :priority, :match, :conditions_attributes => conditions_attrs)

    if rule.update_attributes rule_attrs.permit!
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
end
