module ArchiveMethods # :nodoc:
  def do_archive(conditions, options = {})
    options[:prefix] = 'ar_archive_' unless options[:prefix]
    options[:prefix] = 'ar_archive_' if options[:prefix].blank?

    if self.respond_to?(:table_name)
      tabname = self.table_name
    else
      raise 'MissingTableName'
    end

    raise 'PrefixAndTableNameTooLong - maximum is 64 characters' if "#{options[:prefix]}#{tabname}".size > 64
    raise 'PrimaryKey id expected but not found' unless self.primary_key == 'id'

    # do a simple query first in case to cause an exception if there is an error in conditions
    ActiveRecord::Base.connection.execute("
      SELECT COUNT(*)
      FROM #{tabname}
      WHERE #{conditions}
    ")

    ActiveRecord::Base.connection.execute("
      CREATE TABLE IF NOT EXISTS #{options[:prefix]}#{tabname}
        LIKE #{tabname}
    ")

    # use replace into in case of duplicate inserts
    ActiveRecord::Base.connection.execute("
      REPLACE INTO #{options[:prefix]}#{tabname}
        SELECT * FROM #{tabname} WHERE #{conditions}
    ")

    # delete only records in parent table where ids match those in archive table
    ActiveRecord::Base.connection.execute("
      DELETE FROM #{tabname}
      WHERE EXISTS(
        SELECT #{options[:prefix]}#{tabname}.id
        FROM #{options[:prefix]}#{tabname}
        WHERE #{options[:prefix]}#{tabname}.id = #{tabname}.id)
    ")
  end

  def do_restore(conditions, options = {})
    options[:prefix] = 'ar_archive_' unless options[:prefix]
    options[:prefix] = 'ar_archive_' if options[:prefix].blank?

    if self.respond_to?(:table_name)
      tabname = self.table_name
    else
      raise 'MissingTableName'
    end

    raise 'PrefixAndTableNameTooLong - maximum is 64 characters' if "#{options[:prefix]}#{tabname}".size > 64
    raise 'PrimaryKey id expected but not found' unless self.primary_key == 'id'

    # do a simple query first in case to cause an exception if there is an error in conditions
    ActiveRecord::Base.connection.execute("
      SELECT COUNT(*)
      FROM #{options[:prefix]}#{tabname}
      WHERE #{conditions}
    ")

    # use replace into in case of duplicate inserts
    ActiveRecord::Base.connection.execute("
      REPLACE INTO #{tabname}
        SELECT * FROM #{options[:prefix]}#{tabname} WHERE #{conditions}
    ")

    # delete only records in archive table where ids match those in parent table
    ActiveRecord::Base.connection.execute("
      DELETE FROM #{options[:prefix]}#{tabname}
      WHERE EXISTS(
        SELECT #{tabname}.id
        FROM #{tabname}
        WHERE #{tabname}.id = #{options[:prefix]}#{tabname}.id)
    ")
  end
end

if Rails::VERSION::MAJOR >= 3
  require 'active_support/concern'

  module ActiveRecordArchive
    extend ActiveSupport::Concern

    class_methods do
      include ArchiveMethods

      # Archive database records
      #
      # Caveats: where foreign keys are involved, child records must be archived first
      #
      # Examples:
      #   >> Model.archive('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)')
      #   >> Model.archive('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)', prefix: 'arch_')
      #
      # Arguments:
      #   conditions: (String)
      #   options:
      #     prefix: (String) - default "ar_archive_"
      def archive(conditions, options = {})
        do_archive(conditions, options)
      end

      # Restore database records
      #
      # Caveats: if you used a custom prefix to archive, make sure you use the same prefix to restore
      #
      # Examples:
      #   >> Model.archive('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)')
      #   >> Model.archive('created_at < DATE_SUB(NOW(), INTERVAL 6 MONTH)', prefix: 'arch_')
      #
      # Arguments:
      #   conditions: (String)
      #   options:
      #     prefix: (String) - default "ar_archive_"
      def restore(conditions, options = {})
        do_restore(conditions, options)
      end
    end
  end

  # include the extension
  ActiveRecord::Base.send(:include, ActiveRecordArchive)
else
  # Rails 2
  class ActiveRecord::Base # :nodoc:
    extend ArchiveMethods

    def self.archive(conditions, options = {})
      do_archive(conditions, options)
    end

    def self.restore(conditions, options = {})
      do_restore(conditions, options)
    end
  end
end
