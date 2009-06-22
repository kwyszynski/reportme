require 'activerecord'

module ReportMe
  class Report
  
    attr_reader :name
  
    def initialize(name)
      @name = name
    end
  
    def source(&block)
      @source = block
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