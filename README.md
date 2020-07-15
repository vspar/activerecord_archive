# activerecord_archive
A simple archiving extension for ActiveRecord. Archive old records to improve database performance. Restore old records from archive tables.

## Installation
Simply add the following line to your Gemfile:
```
gem 'activerecord_archive'
```
## Tested Platforms
Tested on the following platforms:
* Ruby 2.2.10 + Rails 2.3.18 - works fine but is a monkey patch to ActiveRecord::Base
* Ruby 2.5.3 + Rails 4.2.10 - uses ActiveSupport::Concern
* Ruby 2.7.1 + Rails 6.0.3.2 - uses ActiveSupport::Concern

