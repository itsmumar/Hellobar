class ConditionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site, :load_rule
  before_action :verify_capability, only: [:create, :update]

  def show
    condition = @rule.conditions.find(params[:id])
    render json: condition
  end

  def create
    condition = @rule.conditions.new condition_params

    if rule.save
      render json: rule
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

  def update
    rule = @site.rules.find(params[:id])

    if rule.editable?
      rp = rule_params.permit!
      if rule.update_conditions(rp.delete('conditions_attributes')) && rule.update_attributes(rp)
        render json: rule and return
      end
    end
    render json: rule.errors, status: :unprocessable_entity
  end

  def destroy
    condition = @rule.rules.find(params[:id])

    if @site.rules.count == 1
      render nothing: true, status: :unprocessable_entity
    elsif rule.editable? && rule.destroy
      render nothing: true, status: :ok
    else
      render json: rule.errors, status: :unprocessable_entity
    end
  end

  private

  def condition_params
    params.require(:condition)
          .permit(:id, :segment, :operand, :custom_segment, :data_type, :_destroy, { value: [] }, :value)
  end

  def verify_capability
    unless @site && @site.capabilities.custom_targeted_bars?
      render json: { error: 'forbidden' }, status: :forbidden
    end
  end
end
