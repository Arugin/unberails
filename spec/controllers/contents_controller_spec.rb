require 'spec_helper'

describe ContentsController do
  def valid_session
    {}
  end

  before(:each) do
    @user = FactoryGirl.create(:user, gender: @male)
  end

  describe "GET #index" do
    it "responds successfully with an HTTP 200 status code" do
      get :index
      expect(response).to be_success
      expect(response.status).to eq(200)
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end

    it "should not show not approved content" do
      content = FactoryGirl.create(:content_base_content, author: @user)
      get :index, {}

      assigns(:contents).should eq []
    end

    it "should show approved content" do
      content = FactoryGirl.create(:content_base_content, author: @user, approved_to_news: true, reviewed: true)
      get :index, {}

      assigns(:contents).should eq [content]
    end
  end
end
