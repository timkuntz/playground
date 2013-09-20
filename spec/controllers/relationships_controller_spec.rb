require 'spec_helper'

describe RelationshipsController do

  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }

  before { sign_in user, no_capybara: true }

  describe "create with ajax" do

    it "increments the Relationship count" do
      expect {
        xhr :post, :create, relationship: { followed_id: other_user.id }
      }.to change(Relationship, :count).by(1)
    end

    it "responds with success" do
        xhr :post, :create, relationship: { followed_id: other_user.id }
        response.should be_success
    end
  end

  describe "destroy with ajax" do

    before { user.follow!(other_user) }
    let(:relationship) { user.relationships.find_by followed_id: other_user }

    it "descrements the Relationship count" do
      expect {
        xhr :delete, :destroy, id: relationship.id
      }.to change(Relationship, :count).by(-1)
    end

    it "responds with success" do
        xhr :delete, :destroy, id: relationship.id
        response.should be_success
    end
  end

end
