require 'rails_helper'

RSpec.describe Api::V1::ProductsController, type: :controller do

  describe "GET #show" do
    before(:each) do
      @product = FactoryGirl.create :product
      get :show, id: @product.id
    end

    it "returns the information about a reporter on a hash" do
      product_response = json_response[:product]
      expect(product_response[:title]).to eql @product.title
    end

    it { should respond_with 200 }

    it "has a user as an embeded object" do
      product_response = json_response[:product]
      expect(product_response[:user][:email]).to eql(@product.user.email)
    end
  end

  describe "GET #index" do
    before(:each) do
      4.times { FactoryGirl.create :product }
      get :index
    end

    context "when product_ids parameter si not set" do
      before(:each) do
        get :index
      end

      it "returns 4 records from the database" do
        products_response = json_response
        expect(products_response[:products].size).to eql(4)
      end

      it "returns the user object within each product" do
        products_response = json_response[:products]
        products_response.each do |product_response|
          expect(product_response[:user]).to be_present
        end
      end

      it { should respond_with 200 }

    end
  end

  context "when product_ids parameter is set" do
    before(:each) do
      @user = FactoryGirl.create :user
      3.times { FactoryGirl.create :product, user: @user }
      get :index, product_ids: @user.product_ids
    end

    it "returns only the products belonging to the user" do
      products_response = json_response[:products]
      products_response.each do |product_response|
        expect(product_response[:user][:email]).to eql @user.email
      end
    end
  end

  describe "POST #create" do
    context "when is successfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        @product_attributes = FactoryGirl.attributes_for :product
        api_authorization_header user.auth_token
        post :create, { user_id: user.id, product: @product_attributes }
      end

      it "renders the json representation for the product record just created" do
        product_response = json_response[:product]
        expect(product_response[:title]).to eql @product_attributes[:title]
      end

      it { should respond_with 201 }
    end

    context "when is not created" do
      before(:each) do
        user = FactoryGirl.create :user
        @invalid_product_attributes = { title: "Smart TV", price: "Twelve dollars" }
        api_authorization_header user.auth_token
        post :create, { user_id: user.id, product: @invalid_product_attributes }
      end

      it "renders an errors json" do
        product_response = json_response
        expect(product_response).to have_key(:errors)
      end

      it "renders the json errors on whye the user could not be created" do
        product_response = json_response
        expect(product_response[:errors][:price]).to include "is not a number"
      end

      it { should respond_with 422 }
    end
  end

  describe "PUT/PATCH #update" do
    before(:each) do
      @user = FactoryGirl.create :user
      @product = FactoryGirl.create :product, user: @user
      api_authorization_header @user.auth_token
    end

    context "when is successfully updated" do
      before(:each) do
        patch :update, { user_id: @user.id, id: @product.id,
                         product: { title: "An expensive TV" } }
      end

      it "renders the json representation for the updated user" do
        product_response = json_response[:product]
        expect(product_response[:title]).to eql "An expensive TV"
      end

      it { should respond_with 200 }
    end

    context "when is not updated" do
      before(:each) do
        patch :update, { user_id: @user.id, id: @product.id,
                         product: { price: "two hundred" } }
      end

      it "renders an errors json" do
        product_response = json_response
        expect(product_response).to have_key(:errors)
      end

      it "renders the json errors on whye the user could not be created" do
        product_response = json_response
        expect(product_response[:errors][:price]).to include "is not a number"
      end

      it { should respond_with 422 }
    end
  end

  describe "DELETE #destroy" do
    before(:each) do
      @user = FactoryGirl.create :user
      @product = FactoryGirl.create :product, user: @user
      api_authorization_header(@user.auth_token)
      delete :destroy,  { user_id: @user.id, id: @product.id }
    end

    it { should respond_with 204 }
  end

end