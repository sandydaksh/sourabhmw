class ContactController < ApplicationController
  layout 'contact'

  def index
    @email_input_options = {:class => 'txt'}
    return unless request.post?
	valid_email = (params[:email] =~ RE::VALID_EMAIL)
	valid_recaptcha = validate_recap(params, Member.new.errors )  
    if(valid_email && valid_recaptcha)
		ContactMailer.deliver_feedback( params[:email], params[:name], params[:subject], params[:feedback])
		ContactMailer.deliver_feedback_received(params[:email], params[:name])    
		redirect_to :action => 'thanks'
    else
	  if !valid_email
		  flash[:errors] = "Please provide a valid email address where we can contact you about your feedback." 
		  @email_input_options[:style] = 'background-color: #FF8400;'
	  end
      return
    end
  end

  def feedback
  end

  def thanks
  end

end
