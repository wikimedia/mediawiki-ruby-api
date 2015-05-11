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
end
