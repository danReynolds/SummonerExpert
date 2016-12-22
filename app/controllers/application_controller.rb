class ApplicationController < ActionController::API
  def status
    render json: { success: true }, status: :ok
  end
end
