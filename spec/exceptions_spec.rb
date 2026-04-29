require 'spec_helper'

module MediawikiApi
  describe ApiError do
    def mock_error_response(data = {})
      instance_double(Response, data: data)
    end

    describe '#code' do
      it 'returns the code from `error/code` in the response' do
        error = ApiError.new(mock_error_response('code' => '123'))

        expect(error.code).to eq('123')
      end

      it 'defaults to "000" when a code is not present in the response' do
        error = ApiError.new(mock_error_response)

        expect(error.code).to eq('000')
      end

      it 'defaults to "000" when a response is not provided' do
        error = ApiError.new

        expect(error.code).to eq('000')
      end
    end

    describe '#info' do
      it 'returns the info from `error/info` in the response' do
        error = ApiError.new(mock_error_response('info' => 'some error'))

        expect(error.info).to eq('some error')
      end

      it 'defaults to "unknown API error" when info is not present in the response' do
        error = ApiError.new(mock_error_response)

        expect(error.info).to eq('unknown API error')
      end

      it 'defaults to "unknown API error" when a response is not provided' do
        error = ApiError.new

        expect(error.info).to eq('unknown API error')
      end
    end
  end

  describe HttpError do
    def mock_response(status, headers = {})
      instance_double('Faraday::Response', status: status, headers: headers)
    end

    describe '#status' do
      it 'returns the status from a response object' do
        error = HttpError.new(mock_response(429))

        expect(error.status).to eq(429)
      end

      it 'returns the status when initialized with a bare integer (back-compat)' do
        error = HttpError.new(503)

        expect(error.status).to eq(503)
      end
    end

    describe '#response' do
      it 'exposes the underlying response when one is provided' do
        response = mock_response(429, 'Retry-After' => '30')
        error = HttpError.new(response)

        expect(error.response).to be(response)
        expect(error.response.headers['Retry-After']).to eq('30')
      end

      it 'is nil when initialized with a bare integer' do
        error = HttpError.new(503)

        expect(error.response).to be_nil
      end
    end

    describe '#to_s' do
      it 'formats the message with the status code' do
        expect(HttpError.new(mock_response(429)).to_s).
          to eq('unexpected HTTP response (429)')
        expect(HttpError.new(503).to_s).
          to eq('unexpected HTTP response (503)')
      end
    end
  end
end
