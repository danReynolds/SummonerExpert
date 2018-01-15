class ItemsController < ApplicationController
  include RiotApi
  include Utils
  before_action :load_item, :load_namespace

  def description
    costs = @item.costs
    args = {
      name: @item.name,
      description: @item.sanitizedDescription,
      total_cost: costs['total'],
      sell_cost: costs['sell']
    }

    render json: {
      speech: ApiResponse.get_response(*@namespace, args)
    }
  end

  def build
    item_build = @item.build
    args = {
      name: @item.name,
      item_names: item_build.en.conjunction(article: false)
    }

    if item_build.empty?
      return render json: { speech: ApiResponse.get_response(dig_set(:errors, *@namespace, :empty), args) }
    end

    render json: {
      speech: ApiResponse.get_response(*@namespace, args)
    }
  end

  private

  def load_item
    @item = Item.new(name: item_params[:name])

    unless @item.valid?
      render json: { speech: @item.error_message }
      return false
    end
  end

  def load_namespace
    @namespace = [controller_name.to_sym, action_name.to_sym]
  end

  def item_params
    params.require(:result).require(:parameters).permit(:name)
  end
end
