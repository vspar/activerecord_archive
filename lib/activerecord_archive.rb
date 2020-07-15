if Rails::VERSION::MAJOR >= 3
  require 'active_support/concern'

  module ActiveRecordArchive
    extend ActiveSupport::Concern

    class_methods do
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
        options[:prefix] = 'ar_archive_' unless options[:prefix]
        options[:prefix] = 'ar_archive_' if options[:prefix].blank?

        if self.respond_to?(:table_name)
          tabname = self.table_name # >= Rails 3.x.x
        else
          raise 'MissingTableName', "Unable to determine table name for class #{self.to_s}"
        end        

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

        ActiveRecord::Base.connection.execute("
          INSERT INTO #{options[:prefix]}#{tabname}
            SELECT * FROM #{tabname} WHERE #{conditions}
        ")

        ActiveRecord::Base.connection.execute("
          DELETE FROM #{tabname}
          WHERE EXISTS(
            SELECT #{options[:prefix]}#{tabname}.id
            FROM #{options[:prefix]}#{tabname}
            WHERE #{options[:prefix]}#{tabname}.id = #{tabname}.id)
        ")
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
        options[:prefix] = 'ar_archive_' unless options[:prefix]
        options[:prefix] = 'ar_archive_' if options[:prefix].blank?

        if self.respond_to?(:table_name)
          tabname = self.table_name # >= Rails 3.x.x
        elsif self.class.respond_to?(:table_name)
          tabname = self.class.table_name # Rails 2.x.x
        else
          raise 'MissingTableName', "Unable to determine table name for class #{self.to_s}"
        end        

        # do a simple query first in case to cause an exception if there is an error in conditions
        ActiveRecord::Base.connection.execute("
          SELECT COUNT(*)
          FROM #{options[:prefix]}#{tabname}
          WHERE #{conditions}
        ")

        ActiveRecord::Base.connection.execute("
          INSERT INTO #{tabname}
            SELECT * FROM #{options[:prefix]}#{tabname} WHERE #{conditions}
        ")

        ActiveRecord::Base.connection.execute("
          DELETE FROM #{options[:prefix]}#{tabname}
          WHERE EXISTS(
            SELECT #{tabname}.id
            FROM #{tabname}
            WHERE #{tabname}.id = #{options[:prefix]}#{tabname}.id)
        ")
      end
    end
  end

  # include the extension 
  ActiveRecord::Base.send(:include, ActiveRecordArchive)
else
  class ActiveRecord::Base # :nodoc:
    def self.archive(conditions, options = {})
      options[:prefix] = 'ar_archive_' unless options[:prefix]
      options[:prefix] = 'ar_archive_' if options[:prefix].blank?

      if self.class.respond_to?(:table_name)
        tabname = self.class.table_name # Rails 2.x.x
      else
        raise 'MissingTableName', "Unable to determine table name for class #{self.to_s}"
      end        

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

      ActiveRecord::Base.connection.execute("
        INSERT INTO #{options[:prefix]}#{tabname}
          SELECT * FROM #{tabname} WHERE #{conditions}
      ")

      ActiveRecord::Base.connection.execute("
        DELETE FROM #{tabname}
        WHERE EXISTS(
          SELECT #{options[:prefix]}#{tabname}.id
          FROM #{options[:prefix]}#{tabname}
          WHERE #{options[:prefix]}#{tabname}.id = #{tabname}.id)
      ")
    end

    def self.restore(conditions, options = {})
      options[:prefix] = 'ar_archive_' unless options[:prefix]
      options[:prefix] = 'ar_archive_' if options[:prefix].blank?

      if self.respond_to?(:table_name)
        tabname = self.table_name # >= Rails 3.x.x
      elsif self.class.respond_to?(:table_name)
        tabname = self.class.table_name # Rails 2.x.x
      else
        raise 'MissingTableName', "Unable to determine table name for class #{self.to_s}"
      end        

      # do a simple query first in case to cause an exception if there is an error in conditions
      ActiveRecord::Base.connection.execute("
        SELECT COUNT(*)
        FROM #{options[:prefix]}#{tabname}
        WHERE #{conditions}
      ")

      ActiveRecord::Base.connection.execute("
        INSERT INTO #{tabname}
          SELECT * FROM #{options[:prefix]}#{tabname} WHERE #{conditions}
      ")

      ActiveRecord::Base.connection.execute("
        DELETE FROM #{options[:prefix]}#{tabname}
        WHERE EXISTS(
          SELECT #{tabname}.id
          FROM #{tabname}
          WHERE #{tabname}.id = #{options[:prefix]}#{tabname}.id)
      ")
    end
  end
end
