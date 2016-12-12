class ConversationController < ApplicationController
  def create
    response.headers['Google-Assistant-API-Version'] = 'v1'

    body = JSON.parse(request.body.read)
    conversation_id = body.with_indifferent_access[:conversation][:conversation_id]
    Rails.logger.debug "received conversation object #{conversation_id}"

    response = { :conversation_token => conversation_id }

    input = body.with_indifferent_access[:inputs][0]
    intent = input[:intent]
    if intent == "assistant.intent.action.MAIN"
      response[:expect_user_response] = true
      response[:expected_inputs] = [{
        :input_prompt => {
          :initial_prompts => [
            { :text_to_speech => "Which summoner would you like to look up?" },
          ],
          :no_input_prompts => [
            { :text_to_speech => "I didn't hear a summoner name. Could you repeat that?" },
            { :text_to_speech => "Terminating Summoner Expert." },
          ],
        },
        :possible_intents => [{ :intent => "summoner.input" }],
      }]
      Rails.logger.debug "responded with #{response}"
      return render json: response
    end

    render json: {:got_error => true}
  end
end
