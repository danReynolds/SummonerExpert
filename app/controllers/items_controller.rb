class ItemsController < ApplicationController
  include RiotApi
  before_action :load_item

  def show
    cost_analysis = @item.cost_analysis
    ignored_stats = cost_analysis[:ignored_stats].keys.map { |stat| "- #{stat}" }
    efficiency = cost_analysis[:efficiency].to_f * 100

    ignored_stats_message = ''
    unless ignored_stats.empty?
      ignored_stats_message = (
        "Ignored Stats: \n#{ignored_stats.join("\n")}\n"
      )
    end

    cost_analysis_message = (
      "Cost: #{cost_analysis[:cost].to_i}\n" \
      "Worth: #{cost_analysis[:worth].to_i}\n" \
      "Efficiency: #{efficiency.round(2)}%\n#{ignored_stats_message}" \
    )
    efficiency_message = (
      "This item #{efficiency > 100 ? 'is' : 'is not'} gold " \
      "efficient."
    )

    render json: {
      speech: (
        "Here are the stats for #{@item.name}:\n#{@item.description}\n\n" \
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
    {
      speech: 'What item are you looking for?',
      data: {
        google: {
          expect_user_response: true # Used to keep mic open when a response is needed
        }
      }
    }
  end

  def load_item
    @item = Item.new(name: item_params[:item])

    unless @item.valid?
      render json: { speech: @item.error_message }
      return false
    end
  end
end
