class ConditionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site, :load_rule
  before_action :verify_capability, only: %i[create update]

  def show
    condition = @rule.conditions.find(params[:id])
    render json: condition
  end

  def create
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
        return render(json: rule)
      end
    end
    render json: rule.errors, status: :unprocessable_entity
  end

  def destroy
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
          .permit(:id, :segment, :operand, :_destroy, { value: [] }, :value)
  end

  def verify_capability
    return if @site&.capabilities&.custom_targeted_bars?
    render json: { error: 'forbidden' }, status: :forbidden
  end
end
