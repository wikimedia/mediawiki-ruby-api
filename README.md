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
client.create_account "username", "password" # will not work on wikis that require CAPTCHA, like Wikipedia
client.create_page "title", "content"
client.get_wikitext "title"
client.protect_page "title", "reason", "protections" #  protections are optional, default is "edit=sysop|move=sysop"
client.delete_page "title", "reason"
client.upload_image "filename", "path", "comment", "ignorewarnings"
client.watch_page "title"
client.unwatch_page "title"
client.meta :siteinfo, siprop: "extensions"
client.prop :info, titles: "Some page"
client.query titles: ["Some page", "Some other page"]
```

## Advanced Usage

Any API action can be requested using `#action`. See the
[MediaWiki API documentation](http://www.mediawiki.org/wiki/API) for supported
actions and parameters.

By default, the client will attempt to get a csrf token before attempting the
action. For actions that do not require a token, you can specify
`token_type: false` to avoid requesting the unnecessary token before the real
request. For example:

```ruby
client.action :parse, page: 'Main Page', token_type: false
```

## Links

MediaWiki API gem at: [Gerrit](https://gerrit.wikimedia.org/r/#/admin/projects/mediawiki/ruby/api), [GitHub](https://github.com/wikimedia/mediawiki-ruby-api), [RubyGems](https://rubygems.org/gems/mediawiki_api), [Code Climate](https://codeclimate.com/github/wikimedia/mediawiki-ruby-api).


## Contributing

See https://www.mediawiki.org/wiki/Gerrit

## Release notes

### 0.7.1 2017-01-31
- Add `text` param to `MediawikiApi::Client#upload_image`

### 0.7.0 2016-08-03
- Automatically follow redirects for all API requests.

### 0.6.0 2016-05-25
- Update account creation code for AuthManager. This change updates the gem to test which API
  flavor is in use, then send requests accordingly.

### 0.5.0 2015-09-04
- Client cookies can now be read and modified via MediawikiApi::Client#cookies.
- Logging in will recurse upon a `NeedToken` API error only once to avoid
  infinite recursion in cases where authentication is repeatedly unsuccessful.

### 0.4.1 2015-06-17
- Allow for response-less ApiError exceptions to make mocking in tests easier

### 0.4.0 2015-06-16
- Use action=query&meta=tokens to fetch tokens, instead of deprecated action=tokens

### 0.3.1 2015-01-06
- Actions now automatically refresh token and re-submit action if first attempt returns 'badtoken'.

### 0.3.0 2014-10-14

- HTTP 400 and 500 responses now result in an HttpError exception.
- Edit failures now result in an EditError exception.

### 0.2.1 2014-08-26

- Fix error handling for token requests

### 0.2.0 2014-08-06

- Automatic response parsing.
- Handling of API error responses.
- Watch/unwatch support.
- Query support.
- Public MediawikiApi::Client#action method for advanced API use.

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

## {file:LICENSE.md}

© Copyright 2013-2017, Wikimedia Foundation & Contributors. Released under the terms of the GNU General Public License, version 2 or later.
