[![Build Status](https://travis-ci.org/marshall-lee/sidekiq-bunch.svg?branch=master)](https://travis-ci.org/marshall-lee/sidekiq-bunch)

# sidekiq-bunch

Lightweight Sidekiq job bunches implemented with Redis set data structure.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-bunch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-bunch

## Usage

```ruby
bunch = Sidekiq::Bunch.new
bunch.hook_jobs do
  1000.times do
    MyWorker.perform_async
  end
end

bunch.size # => 1000
bunch.empty? # => false
bunch.wait_for_empty # ...
bunch.empty? # => true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marshall-lee/sidekiq-bunch.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
