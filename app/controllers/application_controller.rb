class ApplicationController < ActionController::API
  def status
    render json: { success: true }, status: :ok
  end

  def letsencrypt
    render text: 'D_yF14gneIiGzMult-n_VaGxi8BvPpNsrhtK_eFBZwc.s20dhHv_2FQ191o8TybEHfK4j_N_p5wnIqM5QNARYus'
  end
end
