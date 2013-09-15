require 'spec_helper'
require 'requests/shared_examples'

describe "User Pages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  let(:base_title) { "Playground Breakable Toy" }

  describe "signup page" do
    before { visit signup_path }

    let(:heading) { 'Sign up' }
    let(:page_title) { "#{base_title} | Sign up" }
    it_should_behave_like "all static pages"

    context "when creating an account" do

      let(:submit) { "Create my account" }

      context "and submitting valid information" do
        before do
          fill_in "Name", with: "Example User"
          fill_in "Email", with: "example@user.com"
          fill_in "Password", with: "foobar"
          fill_in "Confirmation", with: "foobar"
        end

        it "creates a user" do
          expect { click_button submit}.to change(User, :count).by(1)
        end

        it "displays a welcome message" do
          click_button submit
          page.should have_selector('.alert-success', text: 'Welcome to the Playground!')
        end

        it "signs the user in" do
          click_button submit
          page.should have_link('Sign out')
        end
      end

      context "and submitting invalid information" do
        it "does not create a user" do
          expect { click_button submit}.not_to change(User, :count)
        end
        it "displays errors" do
          click_button submit
          page.should have_selector('#error_explanation', text: 'Email is invalid')
        end
        it "provides meaningful erorrs" do
          click_button submit
          page.should_not have_selector('#error_explanation', text: 'Password digest')
        end
      end
    end
  end

  describe "profile page" do
    let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
    let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }

    before { visit user_path(user) }

    let(:heading) { user.name }
    let(:page_title) { "#{base_title} | #{user.name}" }

    it_should_behave_like "all static pages"

    describe "microposts" do
      it {should have_content(m1.content) }
      it {should have_content(m2.content) }
      it {should have_content(user.microposts.count) }
    end
  end

  describe 'index' do

    before do
      sign_in FactoryGirl.create(:user)
      visit users_path
    end

    it { should have_title('All users') }
    it { should have_header('All users') }

    describe "pagination" do

      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all) { User.delete_all }

      it { should have_selector('div.pagination') }

      it 'lists each user' do
        User.paginate(page: 1).each do |user|
          page.should have_selector('li', text: user.name)
        end
      end
    end
  end

  describe 'new' do
    context 'when user is signed-in' do
      before do
        sign_in FactoryGirl.create(:user), no_capybara: true
        get new_user_path
      end
      specify { response.should redirect_to(root_url) }
    end
  end

  describe 'create' do
    context 'when user is signed-in' do
      before do
        sign_in FactoryGirl.create(:user), no_capybara: true
        post users_path
      end
      specify { response.should redirect_to(root_url) }
    end
  end

  describe 'deletion' do

    context "as non-admin user" do
      before do
        sign_in user
        visit users_path
      end
      it { should_not have_link('delete') }
    end

    context "as an admin user" do
      let(:admin) { FactoryGirl.create(:admin) }
      before do
        FactoryGirl.create(:user)
        sign_in admin
        visit users_path
      end

      it { should have_link('delete', href: user_path(User.first)) }

      it "should delete a user" do
        expect { click_link 'delete' }.to change(User, :count).by(-1)
      end

      it { should_not have_link('delete', href: user_path(admin)) }
    end
  end

  describe "edit" do
    before do
      sign_in(user)
      visit edit_user_path(user)
    end

    describe "page" do
      it { should have_header('Update your profile') }
      it { should have_title('Edit user') }
      it { should have_link('change', href: 'http://gravatar.com/emails') }
    end

    context 'with invalid information' do
      before { click_button 'Save changes' }
      it { should have_content('error') }
    end

    context 'with valid information' do
      let(:new_name) { "New Name" }
      let(:new_email) { "new@example.com" }

      before do
        fill_in "Name", with: new_name
        fill_in "Email", with: new_email
        fill_in "Password", with: user.password
        fill_in "Confirmation", with: user.password
        click_button "Save changes"
      end

      it { should have_title(new_name) }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Sign out', href: signout_path) }

      specify { user.reload.name.should == new_name }
      specify { user.reload.email.should == new_email }
    end
  end

  describe "following/followers" do
    let(:other_user) { FactoryGirl.create(:user) }
    before do
      user.follow! other_user
      sign_in user
    end

    describe "followed users" do
      before { visit following_user_path(user) }

      it { should have_title('Following') }
      it { should have_selector('h3', text: 'Following') }
      it { should have_link(other_user.name, href: user_path(other_user)) }
    end

    describe "followers" do
      before { visit followers_user_path(other_user) }

      it { should have_title('Followers') }
      it { should have_selector('h3', text: 'Followers') }
      it { should have_link(user.name, href: user_path(user)) }
    end
  end

  describe "follow/unfollow buttons" do

    let(:other_user) { FactoryGirl.create(:user) }
    before { sign_in user }

    context "when following a user" do
      before { visit user_path(other_user) }

      it "should increment the followed user count" do
        expect {
          click_button "Follow"
        }.to change(user.followed_users, :count).by(1)
      end

      it "should increment the other user's followers" do
        expect {
          click_button "Follow"
        }.to change(other_user.followers, :count).by(1)
      end

      it "should change the button to 'Unfollow'" do
        click_button "Follow"
        page.should have_xpath("//input[@value='Unfollow']")
      end
    end

    context "when unfollowing a user" do
      before do
        user.follow!(other_user)
        visit user_path(other_user)
      end

      it "should decrement the followed user count" do
        expect {
          click_button "Unfollow"
        }.to change(user.followed_users, :count).by(-1)
      end

      it "should decrement the other user's followers" do
        expect {
          click_button "Unfollow"
        }.to change(other_user.followers, :count).by(-1)
      end

      it "should change the button to 'Unfollow'" do
        click_button "Unfollow"
        page.should have_xpath("//input[@value='Follow']")
      end
    end

  end

end
