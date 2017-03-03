class RulesController < ApplicationController
  include RulesHelper

  before_action :authenticate_user!
  before_action :load_site
  before_action :verify_capability, only: [:create, :update]

  def show
    rule = @site.rules.find(params[:id])

    render json: rule
  end

  def create
    rule = @site.rules.new rule_params.permit!

    if rule.save
      render json: rule
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

  def update
    rule = @site.rules.find(params[:id])

    if rule.editable? && rule.update_attributes(rule_params.permit!)
      render json: rule
    else
      render json: format_errors(rule.errors), status: :unprocessable_entity
    end
  end

  def destroy
    rule = @site.rules.find(params[:id])

    if @site.rules.count == 1
      render nothing: true, status: :unprocessable_entity
    elsif rule.editable? && rule.destroy
      render nothing: true, status: :ok
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

  private

  def load_site
    super
  rescue ActiveRecord::RecordNotFound
    if request.get? or request.delete?
      head :not_found
    else
      head :forbidden
    end
  end

  def rule_params
    params.require(:rule).permit(:name, :priority, :match, conditions_attributes: conditions_attrs)
  end

  def conditions_attrs
    [:id, :rule_id, :segment, :operand, :custom_segment, :data_type, :_destroy, { value: [] }, :value]
  end

  def verify_capability
    unless @site && @site.capabilities.custom_targeted_bars?
      render json: { error: 'forbidden' }, status: :forbidden
    end
  end
end
