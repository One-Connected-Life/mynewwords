require "rails_helper"

RSpec.describe "Authentication", type: :request do
  it "redirects unauthenticated visitors to sign in" do
    get root_path
    expect(response).to redirect_to(new_session_path)
  end

  it "signs up a new user and routes to onboarding" do
    post registration_path, params: {
      user: { name: "Ana", email_address: "ana@example.com", password: "password", password_confirmation: "password" }
    }
    expect(User.find_by(email_address: "ana@example.com")).to be_present
    expect(response).to redirect_to(onboarding_path)
  end

  it "signs in an existing user" do
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: "password" }
    expect(response).to redirect_to(root_path)
  end

  it "forces an un-onboarded user to onboarding before drilling" do
    user = create(:user, target_language: nil)
    post session_path, params: { email_address: user.email_address, password: "password" }
    get root_path
    expect(response).to redirect_to(onboarding_path)
  end
end
