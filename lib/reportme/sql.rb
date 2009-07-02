module Reportme
  module Sql

    def self.included(klass)
      klass.extend ClassMethods
    end
 
    module ClassMethods

      def table_exist?(table_name)
        ActiveRecord::Base.connection.select_value("show tables like '#{table_name}'") != nil
      end

      def columns(table_name)
        sql = <<-SQL
        select
          column_name
        from
          information_schema.columns
        where
          table_schema = '#{schema_name}'
          and table_name = '#{table_name}'
        ;
        SQL
        select_values(sql)
      end

      def select_values(sql)
        puts "// ------------------------"
        puts "select_values: #{sql}"
        puts "------------------------ //"
        ActiveRecord::Base.connection.select_values(sql)
      end

      def select_rows(sql)
        puts "// ------------------------"
        puts "select_rows: #{sql}"
        puts "------------------------ //"
        ActiveRecord::Base.connection.select_rows(sql)
      end

      def select_all(sql)
        puts "// ------------------------"
        puts "select_all: #{sql}"
        puts "------------------------ //"
        ActiveRecord::Base.connection.select_all(sql)
      end

      def select_one(sql)
        puts "// ------------------------"
        puts "select_one: #{sql}"
        puts "------------------------ //"
        ActiveRecord::Base.connection.select_one(sql)
      end

      def exec(sql)
        puts "// ------------------------"
        puts "exec: #{sql}"
        puts "------------------------ //"
        ActiveRecord::Base.connection.execute(sql)
      end

      def select_value(sql)
        puts "// ------------------------"
        puts "select_value: #{sql}"
        puts "------------------------ //"
        ActiveRecord::Base.connection.select_value(sql)
      end
   
    end

    def exec(sql)
      self.class.exec(sql)
    end

    def select_value(sql)
      self.class.select_value(sql)
    end

    def select_one(sql)
      self.class.select_one(sql)
    end

    def select_all(sql)
      self.class.select_all(sql)
    end

    def select_rows(sql)
      self.class.select_rows(sql)
    end

    def select_values(sql)
      self.class.select_values(sql)
    end

    def columns(table_name)
      self.class.columns(table_name)
    end
    
    def table_exist?(table_name)
      self.class.table_exist?(table_name)
    end
    
  end

end