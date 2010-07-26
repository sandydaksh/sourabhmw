class OpenIdController < ApplicationController
	layout 'open_id_signup'
  before_filter :private_global
	skip_before_filter :get_username_for_openid
  
#  def create
#	openid_url = params[:openid_url]
#
#	begin
#	  check_id_req = openid_consumer.begin openid_url
#    rescue OpenID::OpenIDError => e
#      flash[:error] = "Discovery failed for #{params[:openid_identifier]}: #{e}"
#      redirect_to :controller => 'member', :action => 'signup'
#      return
#    end
#
#	check_id_req.add_extension_arg('sreg','optional','email,nickname,fullname')
#	redirect_url = check_id_req.redirect_url(APPLICATION_URL, complete_openid_url)
#	redirect_to redirect_url
#
#  end

  
  def complete
	  params_without_ror_crap = params.dup
	  %w{ action controller service_type }.each do |key|
		  params_without_ror_crap.delete(key)
	  end

 	  response = openid_consumer.complete(params_without_ror_crap, complete_openid_url(:service_type => params[:service_type]))

	  if response.status == OpenID::Consumer::SUCCESS

		  # There are three cases to consider:
		  #
		  #  1. A user is a returning OpenID user.  We look him up and send him on his way.
		  #
		  #  2. A user is a returning MW user who is signing in with
		  #     OpenID for the first time.  We look him up, save the OpenID
		  #     url and send him on his way.
		  #
		  #  3. A user is brand new to us.  We create his member record, then ask him for a username.
		  #

		  @registration_info = response.extension_response('http://openid.net/srv/ax/1.0', false)
		  email = @registration_info['value.email']
		  member = Member.find_by_open_id_url(response.identity_url)
		  if member
			  session[:member] = member
			  redirect_to home_url
			  return
		  elsif email
			  member = Member.find_by_email(email)
			  if member
				  member.open_id_url = response.identity_url
				  member.save!
				  session[:member] = member
				  redirect_to home_url
				  return
			  else
				  member = Member.new(:email => email, :open_id_url => response.identity_url)
				  member.do_username_validation = false
				  member.save!
				  session[:member] = member
				  redirect_to username_url
				  return
			  end
		  end
	  end
	  flash[:loginerror] = 'Could not log on with your OpenID'
	  redirect_to signin_url
  end

  def google
	openid_url = 'https://www.google.com/accounts/o8/id'
	
	begin
	  check_id_req = openid_consumer.begin openid_url
    rescue OpenID::OpenIDError => e
      flash[:error] = "Discovery failed for #{params[:openid_identifier]}: #{e}"
      redirect_to :controller => 'member', :action => 'signup'
      return
    end
	
	check_id_req.add_extension_arg('http://openid.net/srv/ax/1.0','required','email')
	check_id_req.add_extension_arg('http://openid.net/srv/ax/1.0','type.email','http://schema.openid.net/contact/email')
	check_id_req.add_extension_arg('http://openid.net/srv/ax/1.0','mode','fetch_request')
  if private_mw?
    redirect_url = check_id_req.redirect_url("http://#{request.host}", complete_openid_url(:service_type => 'google'))
  else
    redirect_url = check_id_req.redirect_url("http://#{request.host}", complete_openid_url(:service_type => 'google'))
  end
	redirect_to redirect_url

  end

  def username
	  @member = current_member
	  return unless request.post?
	  current_member.attributes = params[:member]
    current_member.university_name = @univ_account
	  current_member.do_username_validation = true
	  if current_member.save
		  session[:member] = current_member.reload
		  redirect_to my_invites_url
		  return
	  end
  end

#  def yahoo
#	openid_url = 'http://yahoo.com'
#
#	begin
#	  check_id_req = openid_consumer.begin openid_url
#    rescue OpenID::OpenIDError => e
#      flash[:loginerror] = "Discovery failed for #{params[:openid_identifier]}: #{e}"
#      redirect_to :controller => 'member', :action => 'signup'
#      return
#    end
#
#	check_id_req.add_extension_arg('sreg','required','email')
#	redirect_url = check_id_req.redirect_url(APPLICATION_URL, complete_openid_url(:service_type => 'yahoo'))
#	redirect_to redirect_url
#
#  end

  protected

  def openid_consumer
	@openid_consumer ||= OpenID::Consumer.new(session,      
	  OpenID::Store::Filesystem.new("#{RAILS_ROOT}/tmp/openid"))
  end
  
  def private_global
    if !private_mw?
      @univ_account = 'public'
    else
      @univ_account = private_mw
      session[:university] = private_mw
      #render :action => :verify_alumini,:layout => "verifyalumni" unless !session[:university].nil?
    end
  end

end
