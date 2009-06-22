require 'activerecord'
require 'report_me/report'

module ReportMe
  class ReportFactory
  
    def self.create(&block)
      rme = ReportMe::ReportFactory.new
      rme.instance_eval(&block)
      rme.run
      rme
    end
  
    def initialize
      @reports = []
    end
  
    def periods(today = DateTime.now)

      periods = []

      [:today, :day, :week, :calendar_week, :month, :calendar_month].each do |period|
      
        von, bis = case period
          when :today
            [today, today]
          when :day
            [today - 1.day, today - 1.day]
          when :week
            [today - 1.day - 1.week, today - 1.day]
          when :calendar_week
            n = today - 1.day
            [n - n.cwday + 1, n - n.cwday + 7]
          when :month
            [today - 1.day - 1.month, today - 1.day]
          when :calendar_month
            n = today - 1.month
            [n.beginning_of_month, n.end_of_month]
        end
      
        periods << {:name => period, :von => von, :bis => bis}

      end
    
      periods
    end
  
    def report_information_table_name
      "report_informations"
    end
  
    def report_information_table_name_exist?
      ActiveRecord::Base.connection.select_value("show tables like '#{report_information_table_name}'") != nil
    end

    def report_exists?(name, von, bis)
      ActiveRecord::Base.connection.select_value("select 1 from #{report_information_table_name} where report = '#{name}' and von = '#{von}' and bis = '#{bis}'") != nil
    end
  
  
    def run
    
      debug = true
    
      unless report_information_table_name_exist?
        ddl = <<-SQL
          create
            table report_informations
            (
              report varchar(255) not null,
              von datetime not null,
              bis datetime not null,
              created_at datetime not null,
              primary key (report)
            )
            ENGINE=InnoDB default CHARSET=utf8;
        SQL
        ActiveRecord::Base.connection.execute(ddl)
      end
    
      if debug
        # just for testing
        ActiveRecord::Base.connection.execute("truncate #{report_information_table_name};")
      end
    
      periods.each do |period|
      
        @reports.each do |r|
        
          von = period[:von].strftime("%Y-%m-%d 00:00:00")
          bis = period[:bis].strftime("%Y-%m-%d 23:59:59")

          table_name = r.table_name(period[:name])

          if debug
            # drop and create table while in testing mode
            ActiveRecord::Base.connection.execute("drop table if exists #{table_name};")
          end

          table_exist   = r.table_exist?(period[:name])
          sql           = r.sql(von, bis)
          report_exist  = report_exists?(table_name, von, bis)
        
          puts "report: #{r.name}_#{period[:name]} :: #{report_exist}"
        
        
          unless table_exist
            ActiveRecord::Base.connection.execute("create table #{table_name} ENGINE=InnoDB default CHARSET=utf8 as #{sql} limit 0;")
          end
        
          puts sql
        
          if !report_exist || period[:name] == :today
            ActiveRecord::Base.transaction do
              exec("insert into #{report_information_table_name} values ('#{table_name}', '#{von}', '#{bis}', now());") unless report_exist

              if period[:name] == :today
                exec("truncate #{table_name};")
              end
            
              exec("insert into #{table_name} #{sql};")
            end
          end

        
        end
      end
    end
  
    def exec(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
  
    def report(name, &block)
      r = ReportMe::Report.new(name)
      r.instance_eval(&block)
    
      @reports << r
    end
  
  end
end