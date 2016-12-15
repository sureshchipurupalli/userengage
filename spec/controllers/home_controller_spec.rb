require 'spec_helper'

describe HomeController do
  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in @user
  end
  #
  # context 'when authenticated' do
  #
  #   describe "GET 'index'" do
  #     # Instance variable assignments
  #     it 'assigns appropriate instance variables without any parameters' do
  #       xhr :get, :index
  #     end
  #   end
  # end
end