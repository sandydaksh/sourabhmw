class Email < ActiveRecord::Base
   before_save :rewrite_recipients
   
   def destroy
      self.update_attribute(:deleted, true)
   end               

   def self.find(type, options ={})
      conditions = options[:conditions] ||= []

      conditions[0] ||= ''
      conditions[0] << " and deleted = ?"
      conditions << false

      super(type, options)
   end    

   # Rails 2.3 bug fix... 
  def scoped_methods #:nodoc:
          Thread.current[:"#{self}_scoped_methods"] ||= []
  end   
   
   private
   def rewrite_recipients
      unless RAILS_ENV == 'production'
        if to.match(/@meetingwave.com/) or to.match(/@travelersdev.com/) or to.match(/@travelerstable.com/) or to.match(/@falesafe.net/)
          return
        end
        member = Member.find_by_email(self.to)
        unless(member and member.administrator?)
          self.to = to.gsub('@', '-') + '@travelersdev.com'
        end
      end
      return true
   end
   
end    





