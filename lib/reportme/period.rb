module Reportme
  
  class Period

    def self.calc(today, wanted_periods=[:day])

      today = today.to_date
      
      r = []

      wanted_periods.each do |period|
      
        von, bis = case period
          when :today
            [today, today]
          when :day
            [today - 1.day, today - 1.day]
          when :week
            [today - 1.week, today - 1.day]
          when :calendar_week
            day_lastweek = today.to_date - 7.days
            monday = day_lastweek - (day_lastweek.cwday - 1).days
            [monday, monday + 6.days]
          when :month
            [today - 1.day - 30.days, today - 1.day]
          when :calendar_month
            n = today - 1.month
            [n.beginning_of_month, n.end_of_month]
        end
      
        von = von.to_datetime
        bis = bis.to_datetime + 23.hours + 59.minutes + 59.seconds
      
        r << {:name => period, :von => von, :bis => bis}

      end
    
      r
    end

    
  end
  
end