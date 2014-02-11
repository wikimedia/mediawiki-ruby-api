# MediawikiApi

TODO: Write a gem description

An easy way to work with MediaWiki API from Ruby. Uses REST Client Ruby gem to communicate with MediaWiki API.

## Installation

Add this line to your application's Gemfile:

    gem 'mediawiki_api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mediawiki_api

## Usage

TODO: Write usage instructions here

    $ export API_URL=http://en.wikipedia.beta.wmflabs.org/w/api.php

    $ irb

    > require "mediawiki_api"
    => true

    > include MediawikiApi
    => Object

    > create_article "username", "password", "title", "content"
    => nil

    > delete_article "username", "password", "title"
    => nil

    > create_user "username", "password"
    eddfa276bcaabbaec3f813de78f052e3
    => nil

## Contributing

1. Fork it ( http://github.com/<my-github-username>/mediawiki_api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
