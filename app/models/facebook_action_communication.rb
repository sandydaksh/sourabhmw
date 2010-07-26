class FacebookActionCommunication < FacebookCommunication
   def validate
      errors.add(:data, "#{comm_class.to_s} is not defined for #{self.class.to_s}") unless comm_class === self.data
   end  

   def comm_class
	     Facebooker::Feed::Action
	end

   def push
      fb_user.publish_action(self.action)
   end

   def action
      self.data
   end
                                                                                            
   def action=(action)
      self.data = action
   end

   def action!
      self.action = comm_class.new if self.action.blank?   
      self.action
   end

   # When posting an action the name of the actor comes first
   # So the title should be something like " did something cool!"
   # Then users will see "David did something cool!"
   def title=(title)     
      action!.title = title
   end

   def body=(body)
      action!.body = body
   end

   def add_image(image_url, image_link)
      num = 0
      1.upto(5) do |num|
         break unless(action!.send("image_#{(num)}"))
      end

      action!.send("image_#{num}=", image_url)
      action!.send("image_#{num}_link=", image_link)

   end

   def clear_images
      1.upto(4) do |num|
         action!.send("image_#{num}=", nil)
         action!.send("image_#{num}_link=", nil)
      end
   end

end   

