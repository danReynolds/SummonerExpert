class ItemsController < ApplicationController
  include RiotApi
  before_action :load_item

  def show
    cost_analysis = @item[:cost_analysis]
    ignored_stats = cost_analysis[:ignored_stats].keys.join("\n")
    efficiency = cost_analysis[:efficiency]

    cost_analysis_message = (
      "Cost: #{cost_analysis[:cost]}\n" \
      "Worth: #{cost_analysis[:worth]}\n" \
      "Efficiency: #{efficiency}\n" \
      "Ignored Stats: \n#{ignored_stats}\n"
    )
    efficiency_message = "This item #{efficiency.to_f.positive? ? 'is' : 'is not'} gold efficient."

    render json: {
      speech: (
        "Here are the stats for #{@item[:name]}:\n #{@item[:description]} \n\n" \
        "Here is the cost analysis: \n#{cost_analysis_message} \n" \
        "#{efficiency_message}"
      )
    }
  end

  private

  def item_params
    params.require(:result).require(:parameters).permit(:item)
  end

  def item_not_found_response(name)
    { speech: "I could not find an item called '#{name}'." }
  end

  def no_item_specified_response
    { speech: 'What item are you looking for?' }
  end

  def load_item
    item_query = item_params[:item].strip
    if item_query.blank?
      render json: no_item_specified_response
      return false
    end

    unless @item = RiotApi.get_item(item_query)
      render json: item_not_found_response(item_query)
      return false
    end
  end
end
