module Admin::FacebookAdminHelper
	 
	 def profile_pic(facebook_user)
		  
		  begin     
			     content_tag(:img, "", :src => facebook_user.get_facebook_user.pic_square, :alt => facebook_user.name, :title => facebook_user.name) 
			     
			rescue  Facebooker::Session::SessionExpired => err
				   "BROKEN?"
			end
	 end
end
