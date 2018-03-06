class Api::SequencesStepsController < Api::ApplicationController
  before_action :find_step, except: %i[index create]

  def index
    render json: sequence.sequence_steps.to_a, each_serializer: SequenceStepSerializer
  end

  def show
    render json: @sequence_step
  end

  def create
    @sequence_step = sequence.sequence_steps.build(sequence_step_params)
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
    @sequence_step = site.sequence_steps.find(params[:id])
  end

  def sequence_step_params
    params.require(:sequence).permit(:delay, :executable_type, :executable_id)
  end
end
