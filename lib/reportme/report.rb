module Reportme
  class Report
  
    attr_reader :name
  
    def initialize(name)
      @name = name
      @periods = [:today, :day, :week, :calendar_week, :month, :calendar_month]
    end
  
    def source(&block)
      @source = block
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
      "#{name}_#{period}"
    end
  
    def table_exist?(period)
      ActiveRecord::Base.connection.select_value("show tables like '#{table_name(period)}'") != nil
    end
  
  end
end