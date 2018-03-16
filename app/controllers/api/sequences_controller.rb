class Api::SequencesController < Api::ApplicationController
  before_action :find_sequence, except: %i[index create]

  def index
    render json: site.sequences.to_a, each_serializer: SequenceSerializer
  end

  def show
    render json: @sequence
  end

  def create
    @sequence = site.sequences.build(sequence_params)
    @sequence.save!

    render json: @sequence
  end

  def update
    @sequence.update!(sequence_params)
    render json: @sequence
  end

  def destroy
    @sequence.destroy
    render json: { message: 'Sequence has been successfully deleted.' }
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def find_sequence
    @sequence = site.sequences.find(params[:id])
  end

  def sequence_params
    params.require(:sequence).permit(:name, :contact_list_id)
  end
end
