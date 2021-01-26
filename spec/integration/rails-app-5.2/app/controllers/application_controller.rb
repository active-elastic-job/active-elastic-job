class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  def health_check
    render json: {status: 200}, status: :ok
  end
end
