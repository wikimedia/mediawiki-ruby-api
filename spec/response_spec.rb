require 'spec_helper'

describe MediawikiApi::Response do
  let(:response) { MediawikiApi::Response.new(faraday_response, envelope) }

  let(:faraday_response) { double('Faraday::Response', body: body) }
  let(:body) { '{}' }
  let(:response_object) { JSON.parse(body) }
  let(:envelope) { [] }

  describe '#data' do
    subject { response.data }

    context 'with a JSON object response body' do
      let(:body) { '{ "query": { "result": "success" } }' }

      context 'and no expected envelope' do
        let(:envelope) { [] }

        it { is_expected.to eq(response_object) }
      end

      context 'and a single-level envelope' do
        let(:envelope) { ['query'] }
        let(:nested_object) { response_object['query'] }

        it { is_expected.to eq(nested_object) }
      end

      context 'and a multi-level envelope' do
        let(:envelope) { ['query', 'result'] }
        let(:nested_object) { response_object['query']['result'] }

        it { is_expected.to eq(nested_object) }
      end

      context "and a multi-level envelope that doesn't completely match" do
        let(:envelope) { ['query', 'something'] }
        let(:partially_nested_object) { response_object['query'] }

        it { is_expected.to eq(partially_nested_object) }
      end
    end

    context 'with a JSON array response body' do
      let(:body) { '[ "something" ]' }

      context 'with any expected envelope' do
        let(:envelope) { ['what', 'ever'] }

        it { is_expected.to eq(response_object) }
      end
    end
  end

  describe '#warnings' do
    subject { response.warnings }

    context 'where the response contains no warnings' do
      let(:body) { '{ "query": { "result": "success" } }' }

      it { is_expected.to be_empty }
    end

    context 'where the response contains warnings' do
      let(:body) { '{ "warnings": { "main": { "*": "sorta bad message" } } }' }

      it { is_expected.to_not be_empty }
      it { is_expected.to include('sorta bad message') }
    end
  end

  describe '#warnings?' do
    subject { response.warnings? }

    before { allow(response).to receive(:warnings) { warnings } }

    context 'where there are warnings' do
      let(:warnings) { ['warning'] }

      it { is_expected.to be(true) }
    end

    context 'where there are no warnings' do
      let(:warnings) { [] }

      it { is_expected.to be(false) }
    end
  end
end
