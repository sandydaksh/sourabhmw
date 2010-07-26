class CachingObserver < ActiveRecord::Observer
  observe Invitation, Confirmation, Message, MemberProfile, Contact, Picture
  def logger
    RAILS_DEFAULT_LOGGER
  end

  def self.logger
    RAILS_DEFAULT_LOGGER
  end

  def after_save(record)     
    if(Contact === record )
      clean_contacts(record.member)
    else     
     record = record.member_profile if(Picture === record)
    clean_for_invite(record)
    clean_for_user(record.member) if(record.respond_to?(:member))
    update_five_stars(record) if(record.respond_to?(:admin_rating))
    end
  end 
  
  def after_destroy(record)
    after_save(record)
  end
   
   
  def clean_for_invite(record)
    invitation = record.invitation if(record.respond_to?(:invitation))
    invitation = record if(Invitation === record )   
    clean_for_invitation(invitation)
  end
   
  def update_five_stars(record)
      if(record.admin_rating == 5)
        expire_home_page_invitations if(Invitation === record)
        expire_home_page_wave_makers if(MemberProfile === record )
      end  
  end
   
  def clean_for_invitation(invitation)
     return unless Invitation === invitation
     InvitationsController.new.expire_fragment("invitations/#{invitation.id}")    
     clean_for_user(invitation.inviter)     
  end
  
  def clean_for_user(user)
     self.class.clean_for_user(user)

  end
  
  def clean_contacts(user)
     InvitationsController.new.expire_fragment(self.class.contacts_base_key(user))
  end
  
  SIMPLE_KEYS = [:home_page_wave_makers, :home_page_map, :home_page_invitations ]
  class <<self
    SIMPLE_KEYS.each do |key|
      define_method( "#{key}_key") do
        key.to_s
      end
    end   
    # Everyother key method should call this one... So that we can make smart decisions about the contents of flash.
    def key(string)
      if( (controller = ApplicationController.current_controller) && !(flash = controller.send(:flash)).empty?)
          string += flash.collect{|key, value| 
           next unless value
           next if( key == :fb_connect_post )
           value[-10..-1].gsub(/\s+/, "_") 
          }.compact.join("_")
      else
        string
      end
    end    
    def clean_for_user(user)
           InvitationsController.new.expire_fragment(user_base_key(user))
    end
    
    def upcoming_near_user_key(user)
      key "#{user_base_key(user)}/upcoming_near"
    end   

    def archives_for_user_key(user, params)
      key tack_params("#{user_base_key(user)}/archives", params)
    end   
    
    def myinvites_map_key(user)
      upcoming_near_user_key(user) + "_map"
    end
    
    def facebook_tab_key(user)
      key "#{user_base_key(user)}/facebook_tab"
    end
    
    def my_invitations_key(user,params)
      key tack_params("#{user_base_key(user)}/myinvites",params)
    end
    
    def map_page_key(params)
      key "map/#{params[:action]}"
    end
    
    def map_page_ttl
      1.day.from_now
    end

    
    def my_contacts_key(user)
      key  "#{contacts_base_key(user)}/home_contacts"
    end
    
    def contacts_page_key(user)
       key "#{contacts_base_key(user)}/contacts_page"
    end
    
    def member_profile_invites_key(user,params)
       key tack_params("#{user_base_key(user)}/invites_sidebar",params)
    end
    
    def show_invite_key(current_member, params) 
      key tack_params( tack_member("invitations/#{params[:id].to_i}/#{params[:meeting_id]}", current_member), params)
  end
  
     def invites_of_interest_key(invitation)
       key "invitations/#{invitation.id}/invites_of_interest"
     end
  
  def tack_member(base, current_member)
    base += ( current_member.nil? ? "_logged_out" : "_#{current_member.id}" ) 
  end
    
    def member_profile_show_key(user, params)
      key  tack_params("#{user_base_key(user)}/profile_columns",params)
    end
    
    def contacts_base_key(user)
      "/contacts/#{user.id}"
    end
    
    def user_base_key(user)
      "/user/#{user.id rescue 0}"
    end
    
    def tack_params(base, params)
      base + "_" + ( params[:format] || "html" ).to_s + "_" + (params[:context] || "web").to_s
    end
  
    def upcoming_near_ttl
      2.hours.from_now
    end    
    
    def archives_ttl
      2.hours.from_now
    end    

    def my_invitations_ttl
      2.hours.from_now
    end
    
    def show_invite_ttl
     4.hours.from_now
    end

  end
  
  SIMPLE_KEYS.each do |key|
    define_method( "expire_#{key}") do
      InvitationsController.new.expire_fragment(key.to_s)
    end  
  end   
   
end
