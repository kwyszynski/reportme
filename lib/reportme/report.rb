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
    
    def periods(*args)
      unless args.blank?
        @periods.clear
        args.each do |period|
          @periods << period
        end
      end
    end
    
    def wants_period?(period)
      @periods.include?(period)
    end
    
    def periods
      
    end
    
    def sql(von, bis)
      @source.call(von, bis)
    end
  
    def table_name(period)
      "#{name}_#{period}"
    end
  
    def table_exist?(period)
      ActiveRecord::Base.connection.select_value("show tables like '#{table_name(period)}'") != nil
    end
  
  end
end