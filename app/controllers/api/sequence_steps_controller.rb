class Api::SequenceStepsController < Api::ApplicationController
  before_action :find_step, except: %i[index create]

  def index
    render json: sequence.steps.to_a, each_serializer: SequenceStepSerializer
  end

  def show
    render json: @sequence_step
  end

  def create
    @sequence_step = sequence.steps.build(sequence_step_params)
    @sequence_step.save!

    render json: @sequence_step
  end

  def update
    @sequence_step.update!(sequence_step_params)

    render json: @sequence_step
  end

  def destroy
    @sequence_step.destroy

    render json: { message: 'Sequence has been successfully deleted.' }
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def sequence
    @sequence_step ||= site.sequences.find(params[:sequence_id])
  end

  def find_step
    @sequence_step = sequence.steps.find(params[:id])
  end

  def sequence_step_params
    params.require(:sequence_step).permit(:delay, :executable_type, :executable_id)
  end
end
