require 'spec_helper'
require 'requests/shared_examples'

describe "Static pages" do

  subject { page }

  let(:base_title) { "Playground Breakable Toy" }

  describe "Home page" do
    before { visit root_path }
    let(:heading) { 'Playground' }
    let(:page_title) { base_title }

    it_should_behave_like "all static pages"

    context 'for signed-in users' do
      let(:user) { FactoryGirl.create(:user) }
      before do
        user.microposts.create(content: 'A current user post')
        user.microposts.create(content: 'Another current uesr post')
        sign_in user
        visit root_path
      end

      it "renders the user's microposts" do
        user.feed.each do |post|
          page.should have_selector("li##{post.id}", text: post.content)
        end
      end

      it "renders the micropost count" do
        page.should have_content("2 microposts")

        click_link 'delete', match: :first
        page.should have_content("1 micropost")
        page.should have_no_content("1 microposts")

        click_link 'delete', match: :first
        page.should have_content("0 microposts")
      end

      describe "pagination of the microposts" do
        before do
          28.times { user.microposts.create(content: "dup") }
          user.microposts.create(content: "Last post displays first")
          visit root_path
        end

        context "for first page" do
          it { should have_selector('li.previous_page.disabled') }
          it { should have_selector('li.next_page') }
          it { should have_content('Last post displays first') }
          it { should_not have_content('A current user post') }
        end

        context "for last page" do
          before { click_link 'Next' }

          it { should have_selector('li.previous_page') }
          it { should have_selector('li.next_page.disabled') }
          it { should_not have_content('Last post displays first') }
          it { should have_content('A current user post') }
        end
      end

      describe "follower/following count" do
        let(:other_user) { FactoryGirl.create(:user) }
        before do
          other_user.follow! user
          visit root_path
        end

        it { should have_link("0 following", href: following_user_path(user)) }
        it { should have_link("1 followers", href: followers_user_path(user)) }
      end

    end
  end

  describe "Help page" do
    before { visit help_path }
    let(:heading) { 'Help' }
    let(:page_title) { "#{base_title} | Help" }

    it_should_behave_like "all static pages"
  end

  describe "About page" do
    before { visit about_path }
    let(:heading) { 'About' }
    let(:page_title) { "#{base_title} | About" }

    it_should_behave_like "all static pages"
  end

  describe "Contact page" do
    before { visit contact_path }
    let(:heading) { 'Contact Us' }
    let(:page_title) { "#{base_title} | Contact" }

    it_should_behave_like "all static pages"
  end

  it "layout has the correct links" do
    visit root_path
    ["About", "Help", "Contact"].each do |link|
      click_link link
      page.should have_header(link)
    end

    click_link "Home"
    click_link "Sign up now!"
    page.should have_header('Sign up')

    click_link "Playground"
    page.should have_header('Welcome to the Playground')

  end
end
