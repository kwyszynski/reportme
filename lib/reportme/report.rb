module Reportme
  class Report
  
    attr_reader :name
    
    def initialize(report_factory, name, temporary=false)
      @report_factory = report_factory
      @name = name
      @periods = [:today, :day, :week, :calendar_week, :month, :calendar_month]
      @depends_on = []
      @temporary = temporary
    end
  
    def temporary?
      @temporary
    end
    
    def source(&block)
      @source = block
    end
    
    def depends_on(dependencies=[])
      @depends_on += dependencies
    end
    
    def dependencies
      @depends_on
    end
    
    def periods(wanted_periods=[])
      unless wanted_periods.blank?
        @periods.clear
        wanted_periods.each do |period|
          @periods << period
        end
      end
    end
    
    def wants_period?(period)
      @periods.include?(period)
    end
    
    def sql(von, bis, period_name)
      @source.call(von, bis, period_name)
    end
  
    def table_name(period)
      prefix = temporary? ? "tmp_" : ""
      "#{prefix}#{name}_#{period}"
    end
  
    def table_exist?(period)
      ActiveRecord::Base.connection.select_value("show tables like '#{table_name(period)}'") != nil
    end
    
    def select_value(sql);    @report_factory.select_value(sql);    end
    def select_values(sql);   @report_factory.select_values(sql);   end
    def select_all(sql);      @report_factory.select_all(sql);      end
    def select_rows(sql);     @report_factory.select_rows(sql);     end
    def columns(table_name);  @report_factory.columns(table_name);  end
  
  end
end