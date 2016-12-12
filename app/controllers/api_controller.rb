class ApiController < ApplicationController
  def index
    binding.pry
    render json: { test: true }
  end
end
