require 'spec_helper'

describe "Authentication" do

  subject { page }

  describe "signin page" do

    before { visit signin_path }

    it { should have_header('Sign in') }
    it { should have_title('Sign in') }

    context "with invalid information" do

      before { click_button "Sign in" }

      it { should have_header('Sign in') }
      it { should have_error_message('Invalid') }

      it { should_not have_link('Profile') }
      it { should_not have_link('Settings') }
      it { should_not have_link('Sign out') }
      it { should have_link('Sign in', href: signin_path) }

      context "after visiting another page" do
        before { click_link 'Home' }
        it { should_not have_selector('div.alert.alert-error') }
      end
    end

    context "with valid information" do

      let(:user) { FactoryGirl.create :user }
      before { sign_in user }

      it { should have_title(user.name) }
      it { should have_link('Users', href: users_path) }
      it { should have_link('Profile', href: user_path(user)) }
      it { should have_link('Settings', href: edit_user_path(user)) }
      it { should have_link('Sign out', href: signout_path) }
      it { should_not have_link('Sign in', href: signin_path) }

      context "followed by a signout" do
        before { click_link "Sign out" }
        it { should have_link("Sign in") }
      end

    end
  end

  describe "authorization" do

    context "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }

      describe "visiting edit page" do
        before { visit edit_user_path(user) }
        it { should have_title('Sign in') }
      end

      describe "submitting to the update action" do
        before { put user_path(user) }
        specify { response.should redirect_to(signin_path) }
      end

      describe "redirects to protected page after sign-in" do
        before do
          visit edit_user_path(user)
          fill_in 'Email', with: user.email
          fill_in 'Password', with: user.password
          click_button 'Sign in'
        end

        it { should have_title('Edit user') }

        it "signing out and back in doesn't maintain redirect" do
          delete signout_path
          visit signin_path
          fill_in 'Email', with: user.email
          fill_in 'Password', with: user.password
          click_button 'Sign in'
          page.should have_title(user.name)
        end
      end

      describe "viewing all users page" do
        before { visit users_path }
        it { should have_title('Sign in') }
      end

      describe "microposts" do

        describe "creation" do
          before { post microposts_path }
          specify { response.should redirect_to(signin_path) }
        end

        describe "destruction" do
          before { delete micropost_path(FactoryGirl.create(:micropost)) }
          specify { response.should redirect_to(signin_path) }
        end

      end

      describe "visiting following users page" do
        before { visit following_user_path(user) }
        it { should have_title('Sign in') }
      end

      describe "visiting followers page" do
        before { visit followers_user_path(user) }
        it { should have_title('Sign in') }
      end

      context "Relationships controller" do
        describe "submitting to the create action" do
          before { post relationships_path }
          specify { response.should redirect_to(signin_path) }
        end

        describe "submitting to the deleting action" do
          before { delete relationship_path(1) }
          specify { response.should redirect_to(signin_path) }
        end
      end
    end

    context "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: 'wrong@user.com') }

      before { sign_in user, no_capybara: true }

      describe "visiting edit page" do
        before { visit edit_user_path(wrong_user) }
        it { should_not have_title('Edit user') }
      end

      describe "submitting to the update action" do
        before { put user_path(wrong_user) }
        specify { response.should redirect_to(root_path) }
      end
    end

    context "as admin user" do
      let(:admin) { FactoryGirl.create(:admin) }
      before { sign_in admin, no_capybara: true }
      describe "DELETE request to Users#destroy for self" do
        it "does nothing" do
          expect {
            delete user_path(admin)
          }.to_not change(User, :count)
        end
      end
    end

    context "as non-admin user" do
      let(:non_admin) { FactoryGirl.create(:user) }

      before { sign_in non_admin, no_capybara: true }

      describe "DELETE request to Users#destroy action" do
        context "for another user" do
          it "does not delete the user" do
            another_user = FactoryGirl.create(:user)
            expect {
              delete user_path(another_user)
            }.to_not change(User, :count)
          end
          it "redirects to root path" do
            another_user = FactoryGirl.create(:user)
            delete user_path(another_user)
            response.should redirect_to(root_path)
          end
        end
      end

    end

  end

end
