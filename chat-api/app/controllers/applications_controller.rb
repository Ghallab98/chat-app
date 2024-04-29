class ApplicationsController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :set_app, only: [:show, :update, :destroy]

  def index
    @applications = Application.all
    if @applications
      render json: @applications.map { |application| { token: application.token, name: application.name } }, status: :ok
    else
      render json: { error: 'No applications found' }, status: :not_found
    end
  end

  def show
    if @application
      render json: @application.as_json(only: %i[token name chats_count], include: { chats: { only: %i[number] } }), status: :ok
    else
      render json: { error: 'Application not found' }, status: :not_found
    end
  end

  def create
    @application = Application.new(application_params)
    if @application.save
      render json: { token: @application.token, name: @application.name }, status: :created
    else
      render json: @application.errors, status: :bad_request
    end
  end

  def update
    if @application.update(application_params)
      render json: { token: @application.token, name: @application.name }, status: :ok
    else
      render json: @application.errors, status: :bad_request
    end
  end

  def destroy
    if @application.destroy
      render json: { message: 'Application was successfully destroyed.' }, status: :ok
    else
      render json: { error: 'Application could not be destroyed.' }, status: :bad_request
    end
  end

  private

  def set_application
    @application = Application.find_by(token: params[:token])
    render json: { error: 'Application not found' }, status: :not_found unless @application
  end

  def application_params
    params.require(:application).permit(:name)
  end
end
