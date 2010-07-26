class Admin::FaqsController < ApplicationController   
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
	
	
	 def list      
		   
		   @faqs = Faq.find(:all, :order => :position, :conditions => ["faq_section_id = ?", params[:section_id] || 1])
		end
		
		def create 

			 @faq = Faq.create(params[:faq])
			 redirect_to(:action => :list,:section_id => @faq.section.id)
			
		end  
		
		def update
			 @faq = Faq.find(params[:id])
			 @faq.update_attributes(params[:faq])
			 redirect_to(:action => :list, :section_id => @faq.section.id)
		end
		
		def edit
			 @faq = Faq.find(params[:id])  
			 render :action => :new
		end
		
		def new   
			  @faq = Faq.new
			
		end
		
		def index
			
		end  
		
		def sort
			 @section = FaqSection.find(params[:id])
			 @faqs = @section.faqs    
			 
			 @faqs.each do |faq|
				   faq.position = params['faqs'].index(faq.id.to_s) + 1
				   faq.save!
				end
				render :nothing => true
				 
			 
		end
end
