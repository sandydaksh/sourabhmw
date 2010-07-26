class PictureController < ApplicationController
  before_filter :private_global
  
   layout  "profile"
   skip_before_filter :verify_if_facebook

   before_filter :login_required, :except => [ :show, :thumb, :mini_thumb ]

   after_filter :expire_cache, :only => [:save_crop, :rotate, :upload]
      caches_page :thumb, :mini_thumb
   def new
      @member = current_member
      @picture = Picture.new
      @invites = @member.public_posted_invites(4).reverse
      check_render_facebook()
   end

   def crop
      @member = current_member
      @picture = Picture.find(params[:id])
      @invites = @member.public_posted_invites(4).reverse
      check_render_facebook('profile', :wrapper)
   end

   def save_crop
      @picture = current_member.member_profile.picture
      @picture.crop(params[:geometry])
      redirect_to my_profile_url
  
   end

   def upload
      @picture = Picture.new(params[:picture])
      @member = current_member
      current_member.member_profile = current_member.create_member_profile if current_member.member_profile.nil?
      old_pic = current_member.member_profile.picture
      @picture.member_profile = current_member.member_profile
      if @picture.save
         ###expire_cache(old_pic.id) Don't do this since old cached pages will have  a differnt URL.  Makes more sense for the ID's here to be the current user.
         old_pic.destroy unless old_pic.blank?
         redirect_to(crop_picture_url(:id => @picture.id))
      else
         render(:action => :new)
      end
   
   end

   def show
      @picture = Picture.find(params[:id])
      send_data(@picture.data, :filename => @picture.filename, :type => @picture.content_type, :disposition => "inline")
   rescue
      logger.error("Could not send picture data: #{$!}.")
      render :text => 'The picture you selected could not be found.', :layout => false, :status => 404
   end

   def thumb
      begin
         @picture = Picture.find(params[:id])
         data = File.exists?(@picture.real_thumb_fname) ? @picture.thumb_data : File.new(File.join(RAILS_ROOT, 'public/images/ttb/default_pic.jpg')).read
         send_data(data, :filename => @picture.thumb_filename, :type => @picture.content_type, :disposition => "inline")
	 return
      rescue Exception
         logger.error("Could not send picture data: #{$!}.")
               render :text => 'The picture you selected could not be found.', :layout => false, :status => 404
      end
   end
   

   def mini_thumb
      begin
      @picture = Picture.find(params[:id])
      send_data(@picture.mini_thumb_data, :filename => @picture.mini_thumb_filename, :type => @picture.content_type, :disposition => "inline")
      rescue 
              render :text => 'The picture you selected could not be found.', :layout => false, :status => 404
      end
   end

   def rotate
      @picture = current_member.member_profile.picture
      degrees = (params[:dir] == "right" ? 90 : -90 )
      @picture.rotate(degrees)
  
   end
   
   private
   def expire_cache(id = @picture.id)
       expire_page(:action => "thumb", :id => id)
      expire_page(:action => "mini_thumb", :id => id)
    end
    
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
    end
  end
  
end
