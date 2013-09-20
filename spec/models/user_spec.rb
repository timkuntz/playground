require 'spec_helper'

describe User do

  let(:user) { User.new(name: "Example User", email: "user@example.com",
                        password: "secret", password_confirmation: "secret") }
  subject { user }

  it { should respond_to(:name) }
  it { should respond_to(:email) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:admin) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:microposts) }
  it { should respond_to(:feed) }
  it { should respond_to(:relationships) }
  it { should respond_to(:followed_users) }
  it { should respond_to(:reverse_relationships) }
  it { should respond_to(:followers) }
  it { should respond_to(:following?) }
  it { should respond_to(:follow!) }

  it { should be_valid }

  it "requires a name" do
    user.name = ""
    user.should_not be_valid
  end

  it "requires an email" do
    user.email = ""
    user.should_not be_valid
  end

  it "requires a password" do
    user.password = user.password_confirmation = ""
    user.should_not be_valid
  end

  it "requires a password confirmation" do
    user.password_confirmation = nil
    user.should_not be_valid
  end

  it "password and password_confirmation should match" do
    user.password = "mismatch"
    user.should_not be_valid
  end

  it "requires a password >= 6 characters" do
    user.password = user.password_confirmation = "a" * 5
    user.should_not be_valid
  end

  it "name is between <= 50 characters" do
    user.name = 'a' * 50
    user.should be_valid

    user.name = 'a' * 51
    user.should_not be_valid
  end

  it "is invalid when email format is bad" do
    addresses = %w(user@foo,com user.foo.com user@foo. user@foo_bar.com user@foo+bar.com)
    addresses.each do |address|
      user.email = address
      user.should_not be_valid
    end
  end

  it "is valid when email format is good" do
    addresses = %w(user@foo.com A_user@foo.com user.foo@bar.com user_foo@bar.com)
    addresses.each do |address|
      user.email = address
      user.should be_valid
    end
  end

  it "downcases email when before saving" do
    user.email = "Mr_Foo@bar.com"
    user.save

    user.reload.email.should == "mr_foo@bar.com"
  end

  context "when email address already taken" do
    it "is invalid" do
      prior_user = user.dup
      prior_user.email.upcase!
      prior_user.save

      user.should_not be_valid
    end
  end

  describe "admin" do
    context "is true" do
      before do
        user.save!
        user.toggle!(:admin)
      end

      it { should be_admin }
    end
  end

  describe "#authenticate" do
    before { user.save }
    let(:found_user) { User.find_by email: user.email }

    it "returns the user when password is correct" do
      user.should == found_user.authenticate("secret")
    end

    it "returns false when the password is incorrect" do
      found_user.authenticate("mismatch").should be_false
    end
  end

  describe "#remember_token" do
    before { user.save }
    its(:remember_token) { should_not be_blank }
  end

  describe "relationships" do
    let(:other_user) { FactoryGirl.create(:user) }
    let(:follower) { FactoryGirl.create(:user) }
    before { user.save }

    it "following relationships are destroyed with the user" do
      user.follow! other_user
      Relationship.find_by(followed_id: other_user).should_not be_nil

      user.destroy
      Relationship.find_by(followed_id: other_user).should be_nil
    end

    it "follower relationships are destroyed with the user" do
      follower.follow! user
      Relationship.find_by(follower_id: follower).should_not be_nil

      user.destroy
      Relationship.find_by(follower_id: follower).should be_nil
    end
  end

  describe "microposts" do
    before { user.save }
    let!(:old_post) { FactoryGirl.create(:micropost, user: user, created_at: 1.day.ago) }
    let!(:new_post) { FactoryGirl.create(:micropost, user: user, created_at: 1.hour.ago) }

    it "are ordered" do
      user.microposts.should == [new_post, old_post]
    end

    context "when user is destroyed" do
      it "are also destroyed" do
        user.destroy
        [new_post, old_post].each do |micropost|
          Micropost.find_by(id: micropost.id).should be_nil
        end
      end
    end

    describe 'feed' do
      let(:unfollowed_post) do
        FactoryGirl.create(:user).microposts.create(content: 'Unfollowed post')
      end
      let(:followed_user) { FactoryGirl.create(:user) }

      before do
        user.follow!(followed_user)
        3.times { followed_user.microposts.create!(content: 'Lorem ipsum...') }
      end

      its(:feed) { should include(new_post) }
      its(:feed) { should include(old_post) }
      its(:feed) { should_not include(unfollowed_post) }
      its(:feed) do
        followed_user.microposts.each {|post| should include(post) }
      end
    end

    describe "following" do
      let(:followed_user) { FactoryGirl.create(:user) }
      before do
        user.save
        user.follow! followed_user
      end
      it { should be_following(followed_user) }
      its(:followed_users) { should include(followed_user) }

      describe "followed user" do
        subject { followed_user }
        its(:followers) { should include(user) }
      end

      describe "and unfollowing" do
        before { user.unfollow!(followed_user) }

        it { should_not be_following(followed_user) }
        its(:followed_users) { should_not include(followed_user) }
      end
    end

  end
end

