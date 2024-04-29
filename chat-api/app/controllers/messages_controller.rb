class MessagesController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :set_application
  before_action :set_chat
  before_action :set_message, only: [:show, :destroy]

  def index
    @messages = @chat.messages
    if @messages
      render json: @messages.map { |msg| { number: msg.number, body: msg.body } }, status: :ok
    else
      render json: { error: 'No messages found' }, status: :not_found
    end
  end

  def show
    if @message
      render json: { number: @message.number, body: @message.body }, status: :ok
    else
      render json: { error: 'Message not found' }, status: :not_found
    end
  end

  def create
    @message = @chat.messages.build(message_params)

    if @message.save
      render json: { body: @message.body }, status: :created
    else
      render json: @message.errors, status: :bad_request
    end
  end

  def update
    if @message.update(message_params)
      render json: { number: @message.number, body: @message.body }, status: :ok
    else
      render json: @message.errors, status: :bad_request
    end
  end

  def search
    chat = @application.chats.find_by(number: params[:chat_number])
    if chat
      @messages = Message.search(params[:query], where: { chat_id: chat.id }, misspellings: {below: 2})
      render json: @messages.map { |msg| { number: msg.number, body: msg.body } }, status: :ok
    else
      render json: { error: 'Chat not found' }, status: :not_found
    end
  end

  def destroy
    if @message.destroy
      render json: { message: 'Message was successfully destroyed.' }, status: :ok
    else
      render json: { error: 'Message could not be destroyed.' }, status: :bad_request
    end
  end

  private

  def set_application
    @application = Application.find_by(token: params[:application_token])
    render json: { error: 'Application not found' }, status: :not_found unless @application
  end

  def set_chat
    @chat = @application.chats.find_by(number: params[:chat_number])
    render json: { error: 'Chat not found' }, status: :not_found unless @chat
  end

  def set_message
    @message = @chat.messages.find_by(number: params[:number])
    render json: {error: 'Message not found'}, status: :not_found unless @message
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
