class Admin::BlogController < ApplicationController
	
 before_filter :admin_required
 layout 'static'
 uses_tiny_mce(:options => { :theme => 'advanced',
                  :mode => "textareas",
                  :width => "675px",
                  :convert_urls => false,
                  :remove_script_host => true,
                  :theme_advanced_toolbar_location => "top",
                  :theme_advanced_toolbar_align => "left",
                  :theme_advanced_resizing => true,
                  :theme_advanced_resize_horizontal => false,
                  :theme_advanced_buttons1 => %w{ bold italic underline strikethrough separator justifyleft justifycenter justifyright indent outdent separator bullist numlist forecolor backcolor separator link unlink image undo redo code},
                  :theme_advanced_buttons2 => %w{ formatselect fontselect fontsizeselect pastetext pasteword selectall },
                  :theme_advanced_buttons3_add => %w{ tablecontrols fullscreen},
                  :paste_create_paragraphs => true,
                  :paste_create_linebreaks => true,
                  :paste_use_dialog => true,
                  :paste_auto_cleanup_on_paste => true,
                  :paste_convert_middot_lists => false,
                  :paste_unindented_list_class => "unindentedList",
                  :paste_convert_headers_to_strong => true,
                  :paste_insert_word_content_callback => "convertWord",
                  :plugins => %w{ contextmenu paste table fullscreen} },
              
  :only => [:new, :edit])
  

 def new
  @mode = :mce
  
  @article = Article.new(:author => current_member, :draft => true)
 end

 def new_plain
  @mode = :plain
  @article = Article.new(:author => current_member, :draft => true)
  render :action => :new
 end

 def edit
  @mode = :mce
  @article = Article.find(params["id"])
 end

 def edit_plain
  @mode = :plain
  @article = Article.find(params["id"])
  render :action => :edit
 end
  
 def save
  klass = params[:article].delete(:type).constantize
  if params[:article][:id].blank?
   @article = klass.new(:author => current_member)
  else
   @article = Article.find(params[:article][:id])
  end
    
  @article.attributes = params[:article]
  if ((params[:article][:draft].to_i rescue 0) == 1)
   @article.draft = true
  else
   @article.draft = false
  end
  # @article.body_preview = truncate(strip_tags(@article.body), 100)
  @article.save!
  
  if( @article.class !=  klass )
     @article.update_attribute(:type, klass.to_s)
  end
  redirect_to :action => 'index'
 end
  
  
 def index
  @articles = Article.find(:all)
 end

 def delete
  @article = Article.find_by_author_id_and_id(current_member.id, params[:id])
  @article.destroy
  redirect_to :action => :index
	
 end
 
 private
  before_filter :save_asset_host
 after_filter :return_asset_host
 def save_asset_host
    @asset_host = ActionController::Base.asset_host
    
  ActionController::Base.asset_host = request.host_with_port
 end
 
 def return_asset_host
  ActionController::Base.asset_host = @asset_host
 end

end
