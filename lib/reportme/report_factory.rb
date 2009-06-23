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
            # [today - 1.day - 1.week, today - 1.day]
            [today - 1.week, today - 1.day]
          when :calendar_week
            n = today - 1.day
            [n - n.cwday + 1, n - n.cwday + 7]
          when :month
            # [today - 1.day - 1.month, today - 1.day]
            [today - 1.month, today - 1.day]
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

    def week_data_present?(report, von, bis)
      puts "von: #{von} ... bis: #{bis}"
    end

    def ensure_report_table_exist(report, period)
      unless report.table_exist?(period)
        table_name  = report.table_name(period)
        sql         = report.sql('0000-00-00 00:00:00', '0000-00-00 00:00:00', period)

        exec("create table #{table_name} ENGINE=InnoDB default CHARSET=utf8 as #{sql} limit 0;")
      end
    end
    
    def ensure_report_informations_table_exist
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
    end
    
    def try_weekly_report_by_daily_reports(report, _von, _bis)

      table_name = report.table_name(:week)

      von = _von.strftime("%Y-%m-%d 00:00:00")
      bis = _bis.strftime("%Y-%m-%d 23:59:59")
      
      existing_daily_reports = select_value(<<-SQL
        select
          count(1) cnt
        from
          #{report_information_table_name}
        where
          report = '#{report.table_name(:day)}'
          and von between '#{von}' and '#{(_von + 6.days).strftime("%Y-%m-%d 23:59:59")}'
      SQL
      ).to_i
      
      puts "weekly report depends on 7 daily reports ... #{existing_daily_reports} daily found"
      
      if existing_daily_reports == 7
        ActiveRecord::Base.transaction do
          exec("insert into #{report_information_table_name} values ('#{table_name}', '#{von}', '#{bis}', now());")
          exec("insert into #{table_name} select * from #{report.table_name(:day)} where von between '#{von}' and '#{(_von + 6.days).strftime("%Y-%m-%d 00:00:00")}';")
        end
      end
    end

    def run
    
      ensure_report_informations_table_exist
    
      while !@since.future?
        
        periods(@since).each do |period|
      
          @reports.each do |r|
          
            period_name = period[:name]
          
            next unless r.wants_period?(period_name)

            _von = period[:von]
            _bis = period[:bis]

            von = _von.strftime("%Y-%m-%d 00:00:00")
            bis = _bis.strftime("%Y-%m-%d 23:59:59")

            table_name = r.table_name(period_name)

            table_exist   = r.table_exist?(period_name)
            sql           = r.sql(von, bis, period_name)
        
            puts "report: #{r.table_name(period_name)} exist: #{table_exist}"

            ensure_report_table_exist(r, period_name)
            
            report_exists = report_exists?(table_name, von, bis)
            
            try_weekly_report_by_daily_reports(r, _von, _bis) if period_name == :week && !report_exists

            report_exists = report_exists?(table_name, von, bis)
            
            if !report_exists || period_name == :today
              ActiveRecord::Base.transaction do
                exec("insert into #{report_information_table_name} values ('#{table_name}', '#{von}', '#{bis}', now());") unless report_exists
            
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