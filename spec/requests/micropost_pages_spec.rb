require 'spec_helper'

describe "Micropost Pages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  describe "micropost creation" do

    before { visit root_path }

    context "with invalid information" do

      it "does not create a new post" do
        expect { click_button "Post" }.to_not change(Micropost, :count)
      end

      it "displays an error" do
        click_button "Post"
        page.should have_content('error')
      end

    end

    context "with valid information" do

      before { fill_in 'micropost_content', with: 'Lorem ipsum' }

      it "creates a micropost" do
        expect { click_button "Post" }.to change(Micropost, :count).by(1)
      end

    end
  end

  describe "micropost destruction" do
    before { user.microposts.create(content: 'foo') }

    context "when micropost is from current user" do
      before { visit root_path }

      it "allows deletion" do
        expect { click_link "delete" }.to change(Micropost, :count).by(-1)
      end
    end
  end

end
