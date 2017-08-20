class ApplicationController < ActionController::API
  def status
    render json: { success: true }, status: :ok
  end

  def reset
    render json: {
      speech: ApiResponse.get_response({ application: :reset }),
      resetContexts: true
    }
  end

  def patch
    args = { patch: Rails.cache.read(:patch) }
    render json: {
      speech: ApiResponse.get_response({ application: :patch }, args)
    }
  end
end
