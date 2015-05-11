require 'spec_helper'

describe MediawikiApi::ApiError do
  it 'should create a generic ApiError when initialized with no data' do
    mock_error = MediawikiApi::ApiError.new
    expect(mock_error).to be_a(MediawikiApi::ApiError)
  end
end
