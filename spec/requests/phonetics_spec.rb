require "rails_helper"

RSpec.describe "Phonetics — IPA guide", type: :request do
  it "is accessible to authenticated users" do
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: "password" }

    get ipa_guide_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("IPA")
    expect(response.body).to include("schwa")  # sanity: at least one symbol rendered
  end

  it "requires authentication" do
    get ipa_guide_path
    expect(response).to redirect_to(new_session_path)
  end
end
