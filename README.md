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

Assuming you have MediaWiki installed via [MediaWiki-Vagrant](https://www.mediawiki.org/wiki/MediaWiki-Vagrant).

```ruby
require "mediawiki_api"

client = MediawikiApi::Client.new "http://127.0.0.1:8080/w/api.php"
client.log_in "username", "password" # default Vagrant username and password are "Admin", "vagrant"
client.create_account "username", "password"
client.create_page "title", "content"
client.get_wikitext "title"
client.protect_page "title", "reason", "protections" #  protections are optional, default is "edit=sysop|move=sysop"
client.delete_page "title", "reason"
client.upload_image "filename", "path", "comment", "ignorewarnings"
```

## Links

MediaWiki API gem at: [Gerrit](https://gerrit.wikimedia.org/r/#/admin/projects/mediawiki/ruby/api), [GitHub](https://github.com/wikimedia/mediawiki-ruby-api), [RubyGems](https://rubygems.org/gems/mediawiki_api), [Code Climate](https://codeclimate.com/github/wikimedia/mediawiki-ruby-api).


## Contributing

1. Fork it ( http://github.com/<my-github-username>/mediawiki_api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Add some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Release notes

### 0.1.4 2014-07-18

- Added MediawikiApi::Client#protect_page.
- Updated documentation.

### 0.1.3 2014-06-28

- Added MediawikiApi::Client#upload_image.

### 0.1.2 2014-04-11

- Added MediawikiApi::Client#get_wikitext.

### 0.1.1 2014-04-01

- Updated documentation.

### 0.1.0 2014-03-13

- Complete refactoring.
- Removed MediawikiApi#create_article, #create_user and #delete_article.
- Added MediawikiApi::Client#new, #log_in, #create_page, #delete_page, #create_account.
- Added unit tests.

### 0.0.2 2014-02-11

- Added MediawikiApi#delete_article.

### 0.0.1 2014-02-07

- Added MediawikiApi#create_article and #create_user.
