class MemberNotify < ActionMailer::Base
  helper :invitation_notify 

  def signup(member, password,level,url=nil)
     setup_email(member)
     url = clean_url(url)
       
      # Email header info
    @subject += "Welcome to MeetingWave!"

    # Email body substitutions
    @body["level"] = level
    @body["name"] = member.welcome_name
    @body["login"] = member.email
    @body["password"] = password
    @body["url"] = url || APPLICATION_URL.to_s
    
  end
  
    def signup_f(member, password,url=nil)
     setup_email(member)
     url = clean_url(url)
       
      # Email header info
    @subject += "Welcome to MeetingWave!"

    # Email body substitutions
    #~ @body["level"] = level
    @body["name"] = member.welcome_name
    @body["login"] = member.email
    @body["password"] = password
    @body["url"] = url || APPLICATION_URL.to_s
    
  end
  
  def account_verification(reqparam,account)
    setup_private_email(account)
     url = "http://#{reqparam}/invitations/do_verify?id=#{account.member_id}&key=#{account.verification_code}"

    # Email header info
    @subject += "Welcome to MeetingWave!"

    # Email body substitutions
    @body["name"] = account.member.welcome_name
    #~ @body["login"] = member.email
    #~ @body["password"] = password
    @body["url"] = url #|| APPLICATION_URL.to_s
  end
  
  def domain_email_verification(reqparam,account)
    setup_domain_email(account)
     url = "http://#{reqparam}/invitations/emaildomainverify?id=#{account.id}"

    # Email header info
    @subject += "Welcome to MeetingWave!"

    # Email body substitutions
    @body["name"] = account.member.welcome_name
    #~ @body["login"] = member.email
    #~ @body["password"] = password
    @body["url"] = url #|| APPLICATION_URL.to_s
  end
  
  
  def signupwithmeeting(member, password,ename,url=nil)
    setup_email(member)
     url = clean_url(url)

    # Email header info
    @subject += "Welcome to MeetingWave!"

    # Email body substitutions
    @body["name"] = member.welcome_name
    @body["login"] = member.email
    @body["password"] = password
    @body["url"] = url || APPLICATION_URL.to_s
    @body["ename"] = ename
  end

  def verified(member,level)
    setup_email(member)
     
    # Email header info
    @subject += "Welcome to MeetingWave!"

    # Email body substitutions
    @body["level"] = level
    @body["name"] = member.welcome_name
    @body["login"] = member.email
  end


  def forgot_password(member, url=nil)
    setup_email(member)
     url = clean_url(url)

    # Email header info
    @subject += "Forgotten password notification"

    # Email body substitutions
    @body["name"] = member.welcome_name
    @body["login"] = member.email
    @body["url"] = url || APPLICATION_URL.to_s
  end

  def change_password(member, password, url=nil)
    setup_email(member)
     url = clean_url(url)

    # Email header info
    @subject += "Changed password notification"

    # Email body substitutions
    @body["name"] = member.welcome_name
    @body["login"] = member.email
    @body["password"] = password
    @body["url"] = url || APPLICATION_URL.to_s
  end

  def delete(member, url=nil)
    setup_email(member)
     url = clean_url(url)
    # Email header info
    @subject += "Delete member notification"

    # Email body substitutions
    @body["name"] = member.welcome_name
    @body["url"] = url || APPLICATION_URL.to_s
  end

  def setup_email(member)
    @recipients = "#{member.email}"
    @from       = MemberSystem::CONFIG[:email_from].to_s
    @subject    = "[MeetingWave] "
    @sent_on    = Time.now
    headers['Content-Type'] = "text/plain; charset=#{MemberSystem::CONFIG[:mail_charset]}; format=flowed"
  end
  
  def setup_private_email(account)
    @recipients = "#{account.email}"
    @from       = MemberSystem::CONFIG[:email_from].to_s
    @subject    = "[#{account.university_name.capitalize} MeetingWave]"
    @sent_on    = Time.now
    headers['Content-Type'] = "text/plain; charset=#{MemberSystem::CONFIG[:mail_charset]}; format=flowed"
  end  
  
  def setup_domain_email(account)
    @recipients = "#{account.email}"
    @from       = MemberSystem::CONFIG[:email_from].to_s
    @subject    = "[MeetingWave]"
    @sent_on    = Time.now
    headers['Content-Type'] = "text/plain; charset=#{MemberSystem::CONFIG[:mail_charset]}; format=flowed"
  end  
  
  
     def clean_url(url)  
	   if( !url.blank? && url.respond_to?(:gsub))    
	   	url.gsub(/context/, "no_context").gsub(/fb_sig_session_key/,"no_key").gsub("https", "http") 
	   else 
		   url
		 end
	end


end
