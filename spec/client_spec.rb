require 'spec_helper'
require 'webmock/rspec'
require 'support/request_helpers'

describe MediawikiApi::Client do
  include MediawikiApi::RequestHelpers

  let(:client) { MediawikiApi::Client.new(api_url) }

  subject { client }

  body_base = { cookieprefix: 'prefix', sessionid: '123' }

  describe '#action' do
    subject { client.action(action, params) }

    let(:action) { 'something' }
    let(:token_type) { 'csrf' }
    let(:params) { {} }

    let(:response) do
      { status: response_status, headers: response_headers, body: response_body.to_json }
    end

    let(:response_status) { 200 }
    let(:response_headers) { nil }
    let(:response_body) { { 'something' => {} } }

    let(:token_warning) { nil }

    before do
      @token_request = stub_token_request(token_type, token_warning)
      @request = stub_api_request(:post, action: action, token: mock_token).to_return(response)
    end

    it { is_expected.to be_a(MediawikiApi::Response) }

    it 'makes requests for both the right token and API action' do
      subject
      expect(@token_request).to have_been_made
      expect(@request).to have_been_made
    end

    context 'without a required token' do
      let(:params) { { token_type: false } }

      before do
        @request_with_token = @request
        @request_without_token = stub_api_request(:post, action: action).to_return(response)
      end

      it 'does not request a token' do
        subject
        expect(@token_request).to_not have_been_made
      end

      it 'makes the action request without a token' do
        subject
        expect(@request_without_token).to have_been_made
        expect(@request_with_token).to_not have_been_made
      end
    end

    context 'given parameters' do
      let(:params) { { foo: 'value' } }

      before do
        @request_with_parameters = stub_action_request(action, foo: 'value').to_return(response)
      end

      it 'includes them' do
        subject
        expect(@request_with_parameters).to have_been_made
      end
    end

    context 'parameter compilation' do
      context 'negated parameters' do
        let(:params) { { foo: false } }

        before do
          @request_with_parameter = stub_action_request(action, foo: false).to_return(response)
          @request_without_parameter = stub_action_request(action).to_return(response)
        end

        it 'omits the parameter' do
          subject
          expect(@request_with_parameter).to_not have_been_made
          expect(@request_without_parameter).to have_been_made
        end
      end

      context 'array parameters' do
        let(:params) { { foo: %w(one two) } }

        before do
          @request = stub_action_request(action, foo: 'one|two').to_return(response)
        end

        it 'pipe delimits values' do
          subject
          expect(@request).to have_been_made
        end
      end
    end

    context 'when the response status is in the 400 range' do
      let(:response_status) { 403 }

      it 'raises an HttpError' do
        expect { subject }.to raise_error(MediawikiApi::HttpError,
                                          'unexpected HTTP response (403)')
      end
    end

    context 'when the response status is in the 500 range' do
      let(:response_status) { 502 }

      it 'raises an HttpError' do
        expect { subject }.to raise_error(MediawikiApi::HttpError,
                                          'unexpected HTTP response (502)')
      end
    end

    context 'when the response is an error' do
      let(:response_headers) { { 'MediaWiki-API-Error' => 'code' } }
      let(:response_body) { { error: { info: 'detailed message', code: 'code' } } }

      it 'raises an ApiError' do
        expect { subject }.to raise_error(MediawikiApi::ApiError, 'detailed message (code)')
      end
    end

    context 'given a bad token type' do
      let(:params) { { token_type: token_type } }
      let(:token_type) { 'badtoken' }
      let(:token_warning) { "Unrecognized value for parameter 'type': badtoken" }

      it 'raises a TokenError' do
        expect { subject }.to raise_error(MediawikiApi::TokenError, token_warning)
      end
    end

    context 'when the token response includes only other types of warnings (see bug 70066)' do
      let(:token_warning) do
        'action=tokens has been deprecated. Please use action=query&meta=tokens instead.'
      end

      it 'raises no exception' do
        expect { subject }.to_not raise_error
      end
    end

    context 'when the token is invalid' do
      let(:response_headers) { { 'MediaWiki-API-Error' => 'badtoken' } }
      let(:response_body) { { error: { code: 'badtoken', info: 'Invalid token' } } }

      before do
        # Stub a second request without the error
        @request.then.to_return(status: 200)
      end

      it 'rescues the initial exception' do
        expect { subject }.to_not raise_error
      end

      it 'automatically retries the request' do
        subject
        expect(@token_request).to have_been_made.twice
        expect(@request).to have_been_made.twice
      end
    end
  end

  describe '#cookies' do
    subject { client.cookies }

    it { is_expected.to be_a(HTTP::CookieJar) }

    context 'when a new cookie is added' do
      before do
        client.cookies.add(HTTP::Cookie.new('cookie_name', '1', domain: 'localhost', path: '/'))
      end

      it 'includes the cookie in subsequent requests' do
        stub_token_request('csrf')
        request = stub_action_request('foo').with(headers: { 'Cookie' => 'cookie_name=1' })

        client.action(:foo)

        expect(request).to have_been_requested
      end
    end
  end

  describe '#log_in' do
    it 'logs in when API returns Success' do
      stub_request(:post, api_url).
        with(body: { format: 'json', action: 'login', lgname: 'Test', lgpassword: 'qwe123' }).
        to_return(body: { login: body_base.merge(result: 'Success') }.to_json)

      subject.log_in 'Test', 'qwe123'
      expect(subject.logged_in).to be true
    end

    context 'when API returns NeedToken' do
      context 'and a token was not given' do
        before do
          stub_login_request('Test', 'qwe123').
            to_return(
              body: { login: body_base.merge(result: 'NeedToken', token: '456') }.to_json,
              headers: { 'Set-Cookie' => 'prefixSession=789; path=/; domain=localhost; HttpOnly' }
            )

          @success_req = stub_login_request('Test', 'qwe123', '456').
            with(headers: { 'Cookie' => 'prefixSession=789' }).
            to_return(body: { login: body_base.merge(result: 'Success') }.to_json)
        end

        it 'logs in' do
          response = subject.log_in('Test', 'qwe123')

          expect(response).to include('result' => 'Success')
          expect(subject.logged_in).to be true
        end

        it 'sends second request with token and cookies' do
          subject.log_in('Test', 'qwe123')

          expect(@success_req).to have_been_requested
        end
      end

      context 'but a token was already provided' do
        subject { client.log_in('Test', 'qwe123', '123') }

        it 'should raise a LoginError' do
          stub_login_request('Test', 'qwe123', '123').
            to_return(body: { login: body_base.merge(result: 'NeedToken', token: '456') }.to_json)

          expect { subject }.to raise_error(MediawikiApi::LoginError)
        end
      end
    end

    context 'when API returns neither Success nor NeedToken' do
      before do
        stub_login_request('Test', 'qwe123').
          to_return(body: { login: body_base.merge(result: 'EmptyPass') }.to_json)
      end

      it 'does not log in' do
        expect { subject.log_in 'Test', 'qwe123' }.to raise_error(MediawikiApi::LoginError)
        expect(subject.logged_in).to be false
      end

      it 'raises error with proper message' do
        expect { subject.log_in 'Test', 'qwe123' }.to raise_error(MediawikiApi::LoginError,
                                                                  'EmptyPass')
      end
    end
  end

  describe '#create_page' do
    subject { client.create_page(title, text) }

    let(:title) { 'Test' }
    let(:text) { 'test123' }
    let(:response) { {} }

    before do
      stub_token_request('csrf')
      @edit_request = stub_action_request(:edit, title: title, text: text).
        to_return(body: response.to_json)
    end

    it 'makes the right request' do
      subject
      expect(@edit_request).to have_been_requested
    end
  end

  describe '#delete_page' do
    before do
      stub_request(:get, api_url).
        with(query: { format: 'json', action: 'query', meta: 'tokens', type: 'csrf' }).
        to_return(body: { query: { tokens: { csrftoken: 't123' } } }.to_json)
      @delete_req = stub_request(:post, api_url).
        with(body: { format: 'json', action: 'delete',
                     title: 'Test', reason: 'deleting', token: 't123' })
    end

    it 'deletes a page using a delete token' do
      subject.delete_page('Test', 'deleting')
      expect(@delete_req).to have_been_requested
    end

    # evaluate results
  end

  describe '#edit' do
    subject { client.edit(params) }

    let(:params) { {} }
    let(:response) { { edit: {} } }

    before do
      stub_token_request('csrf')
      @edit_request = stub_action_request(:edit).to_return(body: response.to_json)
    end

    it 'makes the request' do
      subject
      expect(@edit_request).to have_been_requested
    end

    context 'upon an edit failure' do
      let(:response) { { edit: { result: 'Failure' } } }

      it 'raises an EditError' do
        expect { subject }.to raise_error(MediawikiApi::EditError)
      end
    end
  end

  describe '#get_wikitext' do
    before do
      @get_req = stub_request(:get, index_url).with(query: { action: 'raw', title: 'Test' })
    end

    it 'fetches a page' do
      subject.get_wikitext('Test')
      expect(@get_req).to have_been_requested
    end
  end

  describe '#create_account' do
    it 'creates an account when API returns Success' do
      stub_request(:post, api_url).
        with(body: { format: 'json', action: 'createaccount', name: 'Test', password: 'qwe123' }).
        to_return(body: { createaccount: body_base.merge(result: 'Success') }.to_json)

      expect(subject.create_account('Test', 'qwe123')).to include('result' => 'Success')
    end

    context 'when API returns NeedToken' do
      before do
        stub_request(:post, api_url).
          with(body: { format: 'json', action: 'createaccount',
                       name: 'Test', password: 'qwe123' }).
          to_return(
            body: { createaccount: body_base.merge(result: 'NeedToken', token: '456') }.to_json,
            headers: { 'Set-Cookie' => 'prefixSession=789; path=/; domain=localhost; HttpOnly' }
          )

        @success_req = stub_request(:post, api_url).
          with(body: { format: 'json', action: 'createaccount',
                       name: 'Test', password: 'qwe123', token: '456' }).
          with(headers: { 'Cookie' => 'prefixSession=789' }).
          to_return(body: { createaccount: body_base.merge(result: 'Success') }.to_json)
      end

      it 'creates an account' do
        expect(subject.create_account('Test', 'qwe123')).to include('result' => 'Success')
      end

      it 'sends second request with token and cookies' do
        subject.create_account 'Test', 'qwe123'
        expect(@success_req).to have_been_requested
      end
    end

    # docs don't specify other results, but who knows
    # http://www.mediawiki.org/wiki/API:Account_creation
    context 'when API returns neither Success nor NeedToken' do
      before do
        stub_request(:post, api_url).
          with(body: { format: 'json', action: 'createaccount',
                       name: 'Test', password: 'qwe123' }).
          to_return(body: { createaccount: body_base.merge(result: 'WhoKnows') }.to_json)
      end

      it 'raises error with proper message' do
        expect { subject.create_account 'Test', 'qwe123' }.to raise_error(
          MediawikiApi::CreateAccountError,
          'WhoKnows'
        )
      end
    end
  end

  describe '#watch_page' do
    before do
      stub_request(:get, api_url).
        with(query: { format: 'json', action: 'query', meta: 'tokens', type: 'watch' }).
        to_return(body: { query: { tokens: { watchtoken: 't123' } } }.to_json)
      @watch_req = stub_request(:post, api_url).
        with(body: { format: 'json', token: 't123', action: 'watch', titles: 'Test' })
    end

    it 'sends a valid watch request' do
      subject.watch_page('Test')
      expect(@watch_req).to have_been_requested
    end
  end

  describe '#unwatch_page' do
    before do
      stub_request(:get, api_url).
        with(query: { format: 'json', action: 'query', meta: 'tokens', type: 'watch' }).
        to_return(body: { query: { tokens: { watchtoken: 't123' } } }.to_json)
      @watch_req = stub_request(:post, api_url).
        with(body: { format: 'json', token: 't123', action: 'watch',
                     titles: 'Test', unwatch: 'true' })
    end

    it 'sends a valid unwatch request' do
      subject.unwatch_page('Test')
      expect(@watch_req).to have_been_requested
    end
  end
end
