require 'spec_helper'
require 'requests/shared_examples'

describe 'Feature Rollout' do

  let (:percentage) { 10 }

  def create_user_in_beta
    user = User.all.find {|user| $rollout.active?(:beta, user) }
    if user.nil?
      true until $rollout.active?(:beta, user = create(:user))
    end
    user
  end

  def create_user_not_in_beta
    user = User.all.find {|user| ! $rollout.active?(:beta, user) }
    if user.nil?
      true until !$rollout.active?(:beta, user = create(:user))
    end
    user
  end

  it 'adds beta feature for 10% of users' do
    $rollout.activate_percentage(:beta, percentage)
    user_in_beta = create_user_in_beta

    sign_in user_in_beta
    visit '/'
    page.should have_xpath("//li", text: "beta")

    $rollout.deactivate(:beta)
    visit '/'
    page.should_not have_xpath("//li", text: "beta")
  end

  it 'the other 90% do not have beta access' do
    $rollout.activate_percentage(:beta, percentage)
    user_not_in_beta = create_user_not_in_beta

    sign_in user_not_in_beta
    visit '/'
    page.should_not have_xpath("//li", text: "beta")
  end

  it 'adds admins to beta access' do
    $rollout.activate_group(:beta, :admin)
    admin = create_user_not_in_beta
    admin.toggle! :admin

    sign_in admin
    visit '/'
    page.should have_xpath("//li", text: "beta")
  end

  context "has a UI" do

    it "which exists for admins" do
      user = create(:user)
      user.toggle! :admin
      sign_in user

      visit '/admin/rollout'
      page.status_code.should == 200
    end

    it "but not for non-admins" do
      user = create(:user)
      sign_in user

      expect {
        visit '/admin/rollout'
      }.to raise_error(ActionController::RoutingError)
    end

  end

end
