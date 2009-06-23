require 'reportme/report'

module Reportme
  class ReportFactory
  
    def self.create(since=Date.today, &block)
      rme = ReportFactory.new(since)
      rme.instance_eval(&block)
      rme.run
      rme
    end
  
    def initialize(since)
      raise "since cannot be in the future" if since.future?
      
      @reports = []
      @since = since.to_date
    end
  
    def periods(today = Date.today)

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
      select_value("show tables like '#{report_information_table_name}'") != nil
    end

    def report_exists?(name, von, bis)
      select_value("select 1 from #{report_information_table_name} where report = '#{name}' and von = '#{von}' and bis = '#{bis}'") != nil
    end
    
    def reset
      exec("drop table if exists #{report_information_table_name};")
      
      periods.each do |period|
        @reports.each do |r|
          exec("drop table if exists #{r.table_name(period[:name])};")
        end
      end
    end
  
    def run
    
      unless report_information_table_name_exist?
        ddl = <<-SQL
          create
            table report_informations
            (
              report varchar(255) not null,
              von datetime not null,
              bis datetime not null,
              created_at datetime not null,
              primary key (report, von, bis)
            )
            ENGINE=InnoDB default CHARSET=utf8;
        SQL
        exec(ddl)
      end
    
      while !@since.future?
        
        periods(@since).each do |period|
      
          @reports.each do |r|
          
            period_name = period[:name]
          
            next unless r.wants_period?(period_name)
          
            von = period[:von].strftime("%Y-%m-%d 00:00:00")
            bis = period[:bis].strftime("%Y-%m-%d 23:59:59")

            table_name = r.table_name(period_name)

            table_exist   = r.table_exist?(period_name)
            sql           = r.sql(von, bis, period_name)
            report_exist  = report_exists?(table_name, von, bis)
        
            puts "report: #{r.table_name(period_name)} exist: #{table_exist}"
        
        
            unless table_exist
              exec("create table #{table_name} ENGINE=InnoDB default CHARSET=utf8 as #{sql} limit 0;")
            end
                    
            if !report_exist || period_name == :today
              ActiveRecord::Base.transaction do
                exec("insert into #{report_information_table_name} values ('#{table_name}', '#{von}', '#{bis}', now());") unless report_exist
            
                if period_name == :today
                  exec("truncate #{table_name};")
                end
              
                exec("insert into #{table_name} #{sql};")
              end
            end

        
          end
        end
        
        @since += 1.day
      end
      
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
  
    def report(name, &block)
      
      name = name.to_sym
      
      r = Report.new(name)
      r.instance_eval(&block)
    
      @reports << r
    end
  
  end
end