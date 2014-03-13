# MediawikiApi

A library for interacting with MediaWiki API from Ruby. Uses adapter-agnostic
Faraday gem to talk to the API.

## Installation

Add this line to your application's Gemfile:

    gem "mediawiki_api"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mediawiki_api

## Usage

```ruby
require "mediawiki_api"

client = MediawikiApi::Client.new("http://127.0.0.1/w/api.php")
client.log_in("username", "pass")
client.create_page("Test api", "lalala '''test'''")
client.delete_page("Test api", "reason for deleting")
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/mediawiki_api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Add some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
