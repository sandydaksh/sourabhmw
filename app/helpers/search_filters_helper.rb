module SearchFiltersHelper

   RADII = [['100 miles', 100],
            ['50 miles', 50], 
            ['25 miles', 25], 
            ['10 miles', 10], 
            ['5 miles', 5], 
            ['1 mile', 1]] 

   def radius_options(search_filter)
      options_for_select(RADII, search_filter.radius.to_i) 
   end

end
