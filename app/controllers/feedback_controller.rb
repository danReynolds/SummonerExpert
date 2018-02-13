class FeedbackController < ApplicationController
  def feature
    Feedback.create(
      message: feedback_params[:resolvedQuery],
      feedback_type: Feedback::FEEDBACK_TYPES[:FEATURE]
    )

    render status: :ok
  end

  def bug
    Feedback.create(
      message: feedback_params[:resolvedQuery],
      feedback_type: Feedback::FEEDBACK_TYPES[:BUG]
    )
    render status: :ok
  end

  private

  def feedback_params
    params.require(:result).permit(:resolvedQuery)
  end
end
