require 'rails_helper'

RSpec.describe Api::V1::ProductsController, type: :controller do
  describe "GET #show" do
    let(:product){ FactoryGirl.create :product }
    before(:each) do
      get :show, id: product.id
    end

    it "returns the information about the product on a hash" do
      product_response = json_response[:product]
      expect(product_response[:title]).to eql product.title
    end

    it "has the user as an embedded object" do
      product_response = json_response[:product]
      expect(product_response[:user][:email]).to eql product.user.email
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      4.times { FactoryGirl.create :product }
      get :index
    end

    context "when is not receiving any product_ids parameter" do
      it "returns 4 records from the database" do
        products_response = json_response[:products]
        expect(products_response.length).to eq(4)
      end

      it "returns the user object in each product" do
        products_response = json_response[:products]
        products_response.each do |product_response|
          expect(product_response[:user]).to be_present
        end
      end

      # pagination info
      it { expect(json_response).to have_key(:meta) }
      it { expect(json_response[:meta]).to have_key(:pagination) }
      it { expect(json_response[:meta][:pagination]).to have_key(:per_page) }
      it { expect(json_response[:meta][:pagination]).to have_key(:total_pages) }
      it { expect(json_response[:meta][:pagination]).to have_key(:total_objects) }

      it { should respond_with 200 }
    end

    context "when product_ids parameter is sent" do
      let(:user){ FactoryGirl.create :user }
      before(:each) do
        3.times { FactoryGirl.create :product, user: user }
        get :index, product_ids: user.product_ids
      end

      it "returns just the products that belong to the user" do
        products_response = json_response[:products]
        products_response.each do |product_response|
          expect(product_response[:user][:email]).to eql user.email
        end
      end
    end
  end

  describe "POST #create" do
    context "when is successfully created" do
      let(:user){ FactoryGirl.create :user }
      let(:product_attributes){ FactoryGirl.attributes_for :product }
      before(:each) do
        api_authorization_header user.auth_token
        post :create, { user_id: user.id, product: product_attributes }
      end

      it "renders the json representation for the product record just created" do
        product_response = json_response[:product]
        expect(product_response[:title]).to eql product_attributes[:title]
      end

      it { should respond_with 201 }
    end

    context "when is not created" do
      let(:user){ FactoryGirl.create :user }
      let(:invalid_product_attributes){ {title: "Smart TV", price: "Hundred dollars"}}
      before(:each) do
        api_authorization_header user.auth_token
        post :create, { user_id: user.id, product: invalid_product_attributes }
      end

      it "renders an errors json" do
        product_response = json_response
        expect(product_response).to have_key(:errors)
      end

      it "renders the json errors on why the user could not be created" do
        product_response = json_response
        expect(product_response[:errors][:price]).to include "is not a number"
      end

      it { should respond_with 422 }
    end
  end

  describe "PUT/PATCH #update" do
    let(:user){ FactoryGirl.create :user }
    let(:product){ FactoryGirl.create :product, user: user }
    before(:each) do
      api_authorization_header user.auth_token
    end

    context "when is successfully updated" do
      before(:each) do
        patch :update, { user_id: user.id, id: product.id, product: { title: "An expensive TV" } }
      end

      it "renders the json representation for the updated product" do
        product_response = json_response[:product]
        expect(product_response[:title]).to eql "An expensive TV"
      end

      it { should respond_with 200 }
    end

    context "when is not updated" do
      before(:each) do
        patch :update, { user_id: user.id, id: product.id, product: { price: "one hundred"} }
      end

      it "renders an errors json" do
        product_response = json_response
        expect(product_response).to have_key(:errors)
      end

      it "renders the json errors on why the product could not be created" do
        product_response = json_response
        expect(product_response[:errors][:price]).to include "is not a number"
      end

      it { should respond_with 422 }
    end
  end

  describe "DELETE #destroy" do
    let(:user){ FactoryGirl.create :user }
    let(:product){ FactoryGirl.create :product, user: user }
    before(:each) do
      api_authorization_header user.auth_token
      delete :destroy, { user_id: user.id, id: product.id }
    end

    it { should respond_with 204 }
  end
end
