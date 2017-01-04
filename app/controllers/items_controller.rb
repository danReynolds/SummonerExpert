class ItemsController < ApplicationController
  include RiotApi
  before_action :load_item

  def show
    render json: {
      speech: "Here are the stats for #{@item[:name]}:\n #{@item[:description]}"
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
