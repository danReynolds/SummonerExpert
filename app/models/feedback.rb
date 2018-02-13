class Feedback < ActiveRecord::Base
  FEEDBACK_TYPES = {
    BUG: :BUG,
    FEATURE: :FEATURE,
  }
end
