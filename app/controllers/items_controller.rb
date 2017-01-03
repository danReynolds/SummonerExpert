class ItemsController < ApplicationController
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

  def load_item
    @item = Rails.cache.read(items: item_params[:item])
  end
end
