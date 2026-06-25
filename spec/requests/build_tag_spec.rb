require "rails_helper"

# Visible build tag in the brand lockup (e.g. "Polyglot H8"). The native shell
# advertises "OCL-App/H<build>" in its User-Agent; the layout renders that tag
# so Mihai always knows which build he's on. Plain browsers send no token and
# see no tag. Contract shared with polyglot-ios WebViewConfiguration.swift.
RSpec.describe "Brand-lockup build tag", type: :request do
  let(:user) { create(:user, target_language: "nl", source_language: "en") }

  before do
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  it "renders the build tag when the native shell's UA token is present" do
    get root_path, headers: {
      "HTTP_USER_AGENT" => "Mozilla/5.0 Hotwire Native iOS; Turbo Native iOS; OCL-App/H8"
    }
    expect(response.body).to include(">H8<")
  end

  it "renders no build tag for a plain browser (no token)" do
    get root_path, headers: {
      "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/605.1"
    }
    expect(response.body).not_to match(/Native build [HN]\d/)
  end
end
