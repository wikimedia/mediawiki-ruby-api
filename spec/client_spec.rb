require 'spec_helper'

describe MediawikiApi::Client do
  subject { MediawikiApi::Client.new(api_url) }

  describe "#log_in" do
    body_base = { cookieprefix: "prefix", sessionid: "123" }

    it "logs in when API returns Success" do
      stub_request(:post, api_url).
        with(body: { format: "json", action: "login", lgname: "Test", lgpassword: "qwe123" }).
        to_return(body: { login: body_base.merge({ result: "Success" }) }.to_json )

      subject.log_in "Test", "qwe123"
      subject.logged_in.should be true
    end

    context "when API returns NeedToken" do
      before do
        headers = { "Set-Cookie" => "prefixSession=789; path=/; domain=localhost; HttpOnly" }

        stub_request(:post, api_url).
          with(body: { format: "json", action: "login", lgname: "Test", lgpassword: "qwe123" }).
          to_return(
            body: { login: body_base.merge({ result: "NeedToken", token: "456" }) }.to_json,
            headers: { "Set-Cookie" => "prefixSession=789; path=/; domain=localhost; HttpOnly" }
          )

        @success_req = stub_request(:post, api_url).
          with(body: { format: "json", action: "login", lgname: "Test", lgpassword: "qwe123", lgtoken: "456" }).
          with(headers: { "Cookie" => "prefixSession=789" }).
          to_return(body: { login: body_base.merge({ result: "Success" }) }.to_json )
      end

      it "logs in" do
        subject.log_in "Test", "qwe123"
        subject.logged_in.should be true
      end

      it "sends second request with token and cookies" do
        subject.log_in "Test", "qwe123"
        @success_req.should have_been_requested
      end
    end

    context "when API returns neither Success nor NeedToken" do
      before do
        stub_request(:post, api_url).
          with(body: { format: "json", action: "login", lgname: "Test", lgpassword: "qwe123" }).
          to_return(body: { login: body_base.merge({ result: "EmptyPass" }) }.to_json )
      end

      it "does not log in" do
        expect { subject.log_in "Test", "qwe123" }.to raise_error
        subject.logged_in.should be false
      end

      it "raises error with proper message" do
        expect { subject.log_in "Test", "qwe123" }.to raise_error MediawikiApi::LoginError, "EmptyPass"
      end
    end
  end

  describe "#create_page" do
    before do
      stub_request(:get, api_url).
        with(query: { format: "json", action: "tokens", type: "edit" }).
        to_return(body: { tokens: { edittoken: "t123" } }.to_json )
      @edit_req = stub_request(:post, api_url).
        with(body: { format: "json", action: "edit", title: "Test", text: "test123", token: "t123" })
    end

    it "creates a page using an edit token" do
      subject.create_page("Test", "test123")
      @edit_req.should have_been_requested
    end

    context "when API returns Success" do
      before do
        @edit_req.to_return(body: { result: "Success" }.to_json )
      end

      it "returns a MediawikiApi::Page"
    end
  end

  describe "#delete_page" do
    before do
      stub_request(:get, api_url).
        with(query: { format: "json", action: "tokens", type: "delete" }).
        to_return(body: { tokens: { deletetoken: "t123" } }.to_json )
      @delete_req = stub_request(:post, api_url).
        with(body: { format: "json", action: "delete", title: "Test", reason: "deleting", token: "t123" })
    end

    it "deletes a page using a delete token" do
      subject.delete_page("Test", "deleting")
      @delete_req.should have_been_requested
    end

    # evaluate results
  end
end
