class Api::V1::ProductsController < ApplicationController
  before_action :authenticate_with_token!, only: [:create, :update, :destroy]
  respond_to :json

  # Shows product catalog
  def index
    respond_with Product.all
  end

  # Gets a specified product's details
  def show
    respond_with Product.find(params[:id])
  end

  # Creates product
  def create
    product = current_user.products.build(product_params)
    if product.save
      render json: product, status: 201, location: [:api, product]
    else
      render json: { errors: product.errors }, status: 422
    end
  end

  # Updates product
  def update
    product = current_user.products.find(params[:id])
    if product.update(product_params)
      render json: product, status:200, location: [:api, product]
    else
      render json: { errors: product.errors }, status: 422
    end
  end

  # Deletes product
  def destroy
    product = current_user.products.find(params[:id])
    product.destroy
    head 204
  end

  private
    # Permits specific params
    def product_params
      params.require(:product).permit(:title, :price, :published)
    end
end