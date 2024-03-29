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
Order.archive('id <= 10', prefix: 'my_archived_')
Order.restore('id <= 10', prefix: 'my_archived_')
```
You should bear in mind that you may not wish to restore all records, in which case you should adjust the criteria:
```
Order.archive('id <= 20', prefix: 'my_archived_')
Order.restore('id BETWEEN 10 AND 20', prefix: 'my_archived_')
```
If your table has a self-referencing foreign key, you can specify it with the **recursive_foreign_key** option but please be aware that there is a possibility of orphaned child records being created unless this feature is used carefully:
```
Order.archive('id <= 20', prefix: 'my_archived_', recursive_foreign_key: 'parent_order_id')
Order.restore('id BETWEEN 10 AND 20', prefix: 'my_archived_', recursive_foreign_key: 'parent_order_id')
```
You may also use other criteria to archive and restore, however, watch out for criteria which change over time, e.g.:
```
Order.archive('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)')
Order.restore('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)')
```
In the above example the restored records set will likely be different from the archived records set. This is because the reference point for archiving and restoring is time-dependent. 
## Other Database Engines
To the best of my knowledge the gem uses ANSI standard SQL so it should work with Postgres or similar but please note that the gem is only tested on MySQL.
## Table Relationships
It is important to be aware that the gem only performs a simple copy therefore it does not account for parent/child table relationships or foreign keys.

If the tables you wish to archive contain foreign keys it is recommended to archive the child records first using the foreign key of the parent table (e.g. order_id, if you are archiving order\_items), then archive the parent table using the primary key (id).

If you are using the **recursive_foreign_key** option there is no guarantee against orphaned child records being created, although this will probably generate a referential integrity error.
