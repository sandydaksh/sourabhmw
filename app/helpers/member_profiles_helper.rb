module MemberProfilesHelper

  def edit_this
    if @member == session[:member]      
      "[#{self.send(:link_to, 'Edit', 
       { :controller => 'member_profiles', :action => 'edit' },
       :onclick => "this.href = this.href + '?client_tz_offset=' + timeZoneOffset();"
       )}]"
    end
  end

  def birthdate_field(mp)
    val = (mp.birthdate.strftime("%m/%d/%Y") rescue nil)
    if val.nil?
      val = 'MM/DD/YYYY' 
      style = 'color: #777;'
    end
    text_field('member_profile', 'birthdate',:value => val, :style => style,
	            :onfocus => %q{if($F('member_profile_birthdate') == 'MM/DD/YYYY')$('member_profile_birthdate').value=''; $('member_profile_birthdate').style.color='#000';},
					    :onblur => %q{if($F('member_profile_birthdate') == ''){ $('member_profile_birthdate').value = 'MM/DD/YYYY'; $('member_profile_birthdate').style.color = '#777';} 	},
					    :class => 'fatinput')
  end

  def open_profile_button(section)
       my_id = "#{section}_open_button"
       result =  link_to_function("EDIT", "Element.toggle('#{section.downcase}'); Element.hide('#{section}_view');")
       content_tag('h5', result, :class => 'nomargin', :id => my_id)
  end

  def close_profile_button(section)
       open_id = "#{section}_view"
       result =  link_to_function("DONE EDITING", "Element.hide('#{section.downcase}'); Element.show('#{open_id}');")
       content_tag('h5', result, :class => 'nomargin', :id => "#{section}_close_button")
  end

  def preview_all_attributes(prof)
    res = preview_attributes(prof, 'employment', false)
    res << preview_attributes(prof, 'education', false)
    res << preview_attributes(prof, 'interests', false)
    res << preview_attributes(prof, 'personal', false)
    res << content_tag('span', 'No profile info yet.', :class => 'attr_value') if res.blank?
    res
  end

  def preview_attributes(prof, attribute_type, return_fill_when_blank = true)
    possible_attributes = MemberProfile::ATTRS_BY_TYPE[attribute_type.to_sym]
    result = ''
    possible_attributes.each do |attr_name|
      val = prof.send(attr_name)
      next if val.blank?
 
      if attr_name == 'educations'
         val = val.collect { |e| "#{e.name} #{e.abbreviated_graduation}" }.join(", ")
      elsif attr_name == 'jobs'
        val = val.collect { |j| j.to_s }.join(", ")
      elsif val.is_a?(Array)
         val = val.collect{ |item| item.name }.join(", ")
      end
      name = attr_name.gsub("_formatted", '')
      name = "FRATERNITY/SORORITY" if attr_name == "fraternity_sorority"
      name = "EDUCATION" if attr_name == "educations"
      name = "PROFESSION/JOBS and EMPLOYERS" if attr_name == "jobs"
      name = "PROFESSIONAL MEMBERSHIPS" if attr_name == "professional_associations"
      result << content_tag('span', "#{name.humanize.upcase}:", :class => 'attr_name')
      result << content_tag('span', val, :class => 'attr_value')
      result << ' '
    end
    if result.blank? and return_fill_when_blank
      content_tag('span', 'No profile info yet.', :class => 'attr_value')
    else
      result
    end
  end
  
  def format_timeframe(object_with_timeframe)
      start_year = object_with_timeframe.start_year
      end_year = object_with_timeframe.end_year
      result = ""
      if(!(start_year.blank? or end_year.blank?))
        result << "<b>#{start_year}</b> to <b>#{end_year}</b>"
      elsif start_year
        result << "<b>#{start_year}</b>"
      elsif end_year
        result << "<b>#{end_year}</b>"
      end
      return result
    
  end

  def format_job(job)
      result = format_timeframe(job) 
      result <<  "<br/>" unless result.blank?
      result << job.employer_name << "<br/>"  unless job.employer_name.blank?         
      result << job.location unless job.location.blank?
      return content_tag('h5', result, :class => 'entry')
  end

  def mobile_format_job(job)
      indent = "&nbsp;&nbsp;"
      result = format_timeframe(job)
	  result = (indent + result) unless result.blank?
      result <<  "<br/>" unless result.blank?
      result << indent << job.employer_name << "<br/>"  unless job.employer_name.blank?         
      result << indent << job.location unless job.location.blank?
      return content_tag('h5', result, :class => 'entry')
  end


  
  def format_interest(member_profile, interest)
    interest_value = member_profile.send(interest)
    if interest_value.is_a?(Array)
       interest_value = interest_value.collect{ |item| item.name }.join("<br/>")
    end
    return interest_value
  end  

  def color_widget_selector(param, text) 
	     content_tag(:div, 
						(content_tag(:div, "", :class => "current_color_box", :id => "current_color_box_#{param}" , :style => "background-color:##{@settings[param]};") +  
						link_to_function(text, "toggle_chooser_for('#{param}');", :class => "color_selector", :id => "#{param}_link")),
						:class => "color_selector_wrapper", :id => "wrapper_for_#{param}")
	end  
	
	def size_selector(size_text,size)
		   link_to_function(size_text.to_s.capitalize, "size_selected('#{size_text}','#{size}')", 
					:class => "size_selector #{@settings[:size].to_s == size ? "size_selected" : "" }", 
					:id => "#{size_text}_link")
	end

  def sortable_js
  	result =  sortable_element('column_A', :url => move_widget_url(:col => 'A'), 
  							      :containment => ['column_A','column_B'], 
    							    :dropOnEmpty => true,
    							    :tag => 'div',
  							      :constraint => false,
  							      :dropOnEmpty => true,
  							      :handle => 'movable')
  	result << sortable_element('column_B', :url => move_widget_url(:col => 'B'), 
  									 :containment => ['column_A','column_B'], 
  	 								 :dropOnEmpty => true,
  	 								 :tag => 'div',
  	 								 :constraint => false,
  	 								 :dropOnEmpty => true,
  	 								 :handle => 'movable')
    result
  end

  def profile_spinner(sub_id)
	content_tag('div', image_tag('/images/ttb/spinner.profile.gif'), :id => "#{sub_id}_spinner", :class => 'profile_spinner', :style => "display: none;")
  end

  def loading_script(sub_id)
	"Element.hide('edit_subsection_#{sub_id}'); Element.show('#{sub_id}_spinner');"
  end
  
  def widget_buttons(javascript_method)
     content_tag(:div, 
      ibutton('save_small') + ' ' + link_to_function(button_image('cancel_small'), javascript_method),   
      :class => 'buttons')
  end
    
  def widget_buttons_new(javascript_method)
     content_tag(:div, 
      button_image_save('save_small') +' '+ link_to_function(button_image_cancel('cancel_small'), javascript_method),   
      :class => 'buttons')
  end    
  
  def setup_member_profile_data
    @profile_widgets = @member.member_profile.profile_widgets
    @column_a_widgets = @member.member_profile.profile_widgets.find(:all, :conditions => [ ' col = "A"'], :order => 'row')
    @column_b_widgets = @member.member_profile.profile_widgets.find(:all, :conditions => [ ' col = "B"'], :order => 'row')

    @member_profile = @member.member_profile
   
  end

  def ibutton_member(name, opts = { })
    image_submit_tag(button_path_member(name),:onmouseover=>"this.src= '/images/emailsetting/#{name}-over.jpg';", :onmouseout=>"this.src = '/images/emailsetting/#{name}.jpg';",:class => "#{opts[:clas]}",:id => "#{opts[:id]}",:value => "#{opts[:value]}",:name => "#{opts[:name1]}",:onclick=>"imgvalue(this.value);") 
  end
  
  def ibutton_verify(name, opts = { })
    image_submit_tag(button_path_member(name),:onmouseover=>"this.src= '/images/emailsetting/#{name}-over.jpg';", :onmouseout=>"this.src = '/images/emailsetting/#{name}.jpg';",:class => "#{opts[:clas]}",:id => "#{opts[:id]}",:value => "#{opts[:value]}",:name => "#{opts[:name1]}",:onclick=>"return blankvalue();") 
  end
  
  def button_path_member(name)
    button_name =  (name + ".jpg")
    "/images/emailsetting/#{button_name}"
  end
  
  end
