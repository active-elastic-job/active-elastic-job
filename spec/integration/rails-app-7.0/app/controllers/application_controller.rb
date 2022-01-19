class ApplicationController < ActionController::Base
  def health_check
    render json: {status: 200}, status: :ok
  end
end
