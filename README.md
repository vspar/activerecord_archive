# activerecord_archive
A simple archiving extension for ActiveRecord. Archive old records to improve database performance. Restore old records from archive tables.

## Installation
Download the folder and install the gem as follows:
```
gem install activerecord_archive
```
Simply add the following line to your Gemfile:
```
gem 'activerecord_archive'
```
## Tested Platforms
Tested on the following platforms with **MySQL only**:
* Ruby 2.2.10 + Rails 2.3.18 - works fine but is a monkey patch to ActiveRecord::Base
* Ruby 2.5.3 + Rails 4.2.10 - uses ActiveSupport::Concern
* Ruby 2.7.1 + Rails 6.0.3.2 - uses ActiveSupport::Concern
## Usage
The gem adds class methods to ActiveRecord so archiving and restoring can be done with a single command:
```
Order.archive('id <= 10')
Order.restore('id <= 10')
```
In the above example, orders will be added to the table **ar_archive_orders**. If the archiving was successful the archived records will be **deleted** from the **orders** table.

If you wish you can specify your own archive table prefix but remember not to exceed the maximum table name length for prefix + table name (at the time of writing 64 characters in MySQL):
```
Order.archive('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)', prefix: 'my_archived_')
Order.restore('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)', prefix: 'my_archived_')
```
## Other Database Engines
To the best of my knowledge the gem uses ANSI standard SQL so it should work with Postgres or similar but please note that the gem is only tested on MySQL.

