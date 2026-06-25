require "rails_helper"

# app_build_tag parses the native shell's UA token "OCL-App/H<build>" into a
# small lockup tag ("H8"). Contract is shared with polyglot-ios
# (WebViewConfiguration.swift) — see the helper comment.
RSpec.describe ApplicationHelper, type: :helper do
  describe "#app_build_tag" do
    def with_ua(ua)
      allow(helper.request).to receive(:user_agent).and_return(ua)
    end

    it "extracts the Hotwire shell variant + build from the UA token" do
      with_ua("Mozilla/5.0 Hotwire Native iOS; Turbo Native iOS; OCL-App/H8")
      expect(helper.app_build_tag).to eq("H8")
    end

    it "supports the native variant letter (N) when it ever reports" do
      with_ua("Mozilla/5.0 OCL-App/N12")
      expect(helper.app_build_tag).to eq("N12")
    end

    it "returns nil for a plain browser (no token)" do
      with_ua("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/605.1")
      expect(helper.app_build_tag).to be_nil
    end

    it "returns nil when the UA is blank" do
      with_ua(nil)
      expect(helper.app_build_tag).to be_nil
    end
  end
end
