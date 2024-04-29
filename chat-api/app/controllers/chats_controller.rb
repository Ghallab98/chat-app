class ChatsController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :set_application
  before_action :set_chat, only: [:show, :destroy]

  def index
    @chats = @application.chats
    if @chats
      render json: @chats.map { |chat| { number: chat.number, messages_count: chat.messages_count } }, status: :ok
    else
      render json: { error: 'No chats found' }, status: :not_found
    end
  end

  def show
    render json: @chat.as_json(only: %i[number messages_count], include: { messages: { only: %i[number body] } }), status: :ok
    { number: @chat.number, messages_count: @chat.messages_count}
  end

  def create
    @chat = @application.chats.build
  
    if @chat.save
      render json: { number: @chat.number }, status: :created
    else
      render json: @chat.errors, status: :bad_request
    end
  end

  def update
    if @chat.update(chat_params)
      render json: { number: @chat.number }, status: :ok
    else
      render json: @chat.errors, status: :bad_request
    end
  end

  def destroy
    if @chat.destroy
      render json: { message: 'Chat was successfully destroyed.' }, status: :ok
    else
      render json: { error: 'Chat could not be destroyed.' }, status: :bad_request
    end
  end

  private

  def set_application
    @application = Application.find_by(token: params[:application_token])
    render json: { error: 'Application not found' }, status: :not_found unless @application
  end

  def set_chat
    @chat = @application.chats.find_by(number: params[:number])
    render json: { error: 'Chat not found' }, status: :not_found unless @chat
  end

  def chat_params
    params.require(:chat).permit()
  end
end