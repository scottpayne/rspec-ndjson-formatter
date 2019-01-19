# RSpec ndjson Formatter

A formatter to output rspec examples in ndjson format.

Each top level group will be on it's own line, and all the child groups and examples
nested within it.

The driver for this gem is to work with test tools on large test suites, so we can run
rspec in `--dry-run` mode to stream all the information we need for describing the test
suites. I wrote it to work with the [Test Explorer VSCode Extension](https://github.com/hbenl/vscode-test-explorer), maybe it will come in useful for you too.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec-ndjson-formatter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec-ndjson-formatter

## Usage

Just use it like any other rspec formatter:

```
rspec -f NdjsonFormatter --dry-run
```

then pipe the output to whatever you want.

Ideally the output is flushed on each line to facilitate streaming, so just keep gobbling lines and parsing JSON until there are no more.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scottpayne/rspec-ndjson-formatter.

## License

The gem is available as open source under the terms of the [GPL V3.0 license](https://opensource.org/licenses/MIT).
