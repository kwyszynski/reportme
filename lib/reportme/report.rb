module Reportme
  class Report
  
    attr_reader :name
    
    def initialize(report_factory, name, temporary=false)
      
      name = name.to_sym
      
      @report_factory = report_factory
      @name = name
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
      dependencies = dependencies.collect{|d| d.to_sym}
      @depends_on += dependencies
    end
    
    def dependencies
      @depends_on
    end
    
    def sql(von, bis, period_name)
      raw = @source.call(von, bis, period_name)
      
      <<-SQL
        select
          '#{von}' as von,
          rtmp1.*
        from (
          #{raw}
          ) rtmp1
      SQL
      
    end
  
    def table_name(period)
      prefix = temporary? ? "tmp_" : ""
      "#{prefix}#{name}_#{period}"
    end
  
    
    def select_value(sql);    @report_factory.select_value(sql);    end
    def select_values(sql);   @report_factory.select_values(sql);   end
    def select_all(sql);      @report_factory.select_all(sql);      end
    def select_rows(sql);     @report_factory.select_rows(sql);     end
    def columns(table_name);  @report_factory.columns(table_name);  end
  
  end
end