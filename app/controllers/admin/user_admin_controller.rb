class Admin::UserAdminController < ApplicationController

  before_filter :admin_required

  layout 'admin'

  def index

  end


  def find_problem_user
    @problem_user = Member.find_by_user_name(params[:user_name])
	if @problem_user.nil?
		@problem_user = Member.find_by_email(params[:user_name])
	end

    render :update do |page|
      if @problem_user.nil?
        page.replace_html 'flash', "Could not find user with user_name #{params[:user_name]}."
        page.show 'flash'
        page.hide 'step2'
      else
        page.replace_html 'user_result', :partial => "problem_user", :object => @problem_user
        page.call('setSelectedUser', @problem_user.id)
        page.show 'step2'
        page.hide 'flash'
      end
    end

  end

  def delete_problem_user
    @problem_user = Member.find(params[:user_id])
    if params[:confirmed] == "true"
      @problem_user.destroy
      flash[:notice] = "#{ @problem_user.user_name} has been deleted."
      redirect_to :action => "index"
    end
  end
  
 




end
