# MediaWiki API

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
client.create_account("username", "password")
client.log_in("username", "password")
client.create_page("title", "content")
client.delete_page("title", "reason")
client.protect_page("title", "reason", "edit=sysop|move=sysop")
```

## Links

MediaWiki API gem at: [Gerrit](https://gerrit.wikimedia.org/r/#/admin/projects/mediawiki/ruby/api), [GitHub](https://github.com/wikimedia/mediawiki-ruby-api), [RubyGems](https://rubygems.org/gems/mediawiki_api), [Code Climate](https://codeclimate.com/github/wikimedia/mediawiki-ruby-api).


## Contributing

1. Fork it ( http://github.com/<my-github-username>/mediawiki_api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Add some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
