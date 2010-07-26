module PostInviteHelper

   def tab_class(tab)

      posted  = (session[:pi][:steps][tab] == "posted")
      errors  = (@errors[tab].size > 0 rescue false)
      current = (controller.action_name.to_s.starts_with(tab.to_s))
      if (tab == :done)
         if tab.to_s == controller.action_name
            return "wiz_send"
         else
            return "wiz_send_ready"
         end
      elsif current
         return 'wiz_on'
         #elsif posted and !errors
      elsif !errors
         return 'wiz_done'
         #elsif posted and errors
      elsif errors and posted
         return 'wiz_errors'
      end
      ''
   end

   def wiz_tab(tab)
      tab_name = ((tab == :done) ? 'Preview' :  tab.to_s.capitalize)
      link =  send("#{controller.action_name}_url")
      onclick_script = "$('button').value = '#{tab.to_sym}'; $('post_invite').submit(); return false;"
      content_tag('li', link_to(tab_name, '#', :onclick => onclick_script), :class => tab_class(tab))
   end

   def errors_for_step(obj, step, opts = { })
      return unless (session[:pi][:steps][step] == 'posted')
      return if obj.nil?
      obj.valid?
      opts[:user_facing_names] ||= { }
      attrs = PostInviteController::WIZARD.attributes_for_step(step)
      attrs << :base if opts[:include_base]
      attrs.uniq!
      messages = []
      attrs.each do | attr |
         if obj.errors.on(attr.to_sym)
            if attr.to_sym == :base
               msg = Array(obj.errors.on(attr.to_sym)).first
            else
               name = (opts[:user_facing_names][attr.to_sym] ||  attr.to_s.humanize.capitalize)
               msg = "#{name} #{Array(obj.errors.on(attr.to_sym)).first}"
            end
            msg << '.' unless msg[-1].chr == '.'
            messages << msg
         end
      end
      result = messages.collect { |m| content_tag('li', m) }
      result =  content_tag('ul', result, :id => 'errors')
      result << "<style type=\"text/css\" >  .fieldWithErrors input, .fieldWithErrors select, input.fieldWithErrors  { background-color: #fdbf7d; } </style>"
      result
   end



   def prev_button
      onclick_script = "$('button').value = 'previous'; $('post_invite').submit(); return false;"
      link_to(button_image("previous"), '#', :onclick => onclick_script)
   end

   def address_div_open(kind, invitation)
      display = (invitation.address.kind == kind.to_s) ? " " : "display: none;"
      tag('div', { :id => kind, :style => display }, true)
   end

   def old_value(changes, attribute)
      result = ''
      if changes[attribute]
         result =  content_tag('span', 'WAS: ', :class => 'was')
         result << content_tag('span', changes[attribute]['old'], :class => 'oldvalue')
      end
      result
   end

   def time_zone_update(inv)
      # tz_name = inv.address.time_zone.name rescue nil
      # tz_update = tz_name unless (tz_name.blank? or (inv.time_zone.blank? or inv.time_zone == tz_name))
      # if (tz_update.blank?)
      #   notice_load = ''
      # else
      #    notice_load = javascript_tag( "Event.observe(window, 'load', function() { check_tz_selected('#{tz_update}'); });" )
      # end
      # display = tz_update.blank? ? 'display:none;' : ''
      # tt_header = "Would you like to use the #{tz_name} time zone instead?"
      # id = 'tz_update_dialogue'
      # tt_text = link_to(image_tag('/images/ttb/button_yes.gif'), '#', :class => 'close', :onclick => "select_time_zone('#{tz_name}'); return false;")
      # tt_text += " #{link_to(image_tag('/images/ttb/button_no_thanks.gif'), '#',:class => 'close')}"
      # notice_content = link_to('The time zone selected is not correct for the location.', '#', :id => "activator_#{id}", :class => 'was')
      # tip = content_tag('div', tt_header, :class => 'tt_header')
      # tip << content_tag('div', tt_text, :id => 'tz_update_buttons')
      # notice_content << content_tag('div', tip, :id => id, :class => 'tooltip')
      # content_tag('div', notice_load + notice_content, :id => 'tz_notice', :style => display)
   end


   def show_public_who_section(invitation)
      return (invitation.is_public ? "" : "style='display: none;'")
   end

   def show_private_who_section(invitation)
     return (invitation.is_private ? "" : "style='display: none;'")
   end

   def undisclosed_checkbox(options)
      airport_version = options[:airport_version]
      result = []
      if( airport_version)
          result << check_box_tag('undisclosed_address_airport', "1", @invitation.undisclosed_address?)   
      else        	      
          result << check_box_tag('undisclosed_address_regular', "1", @invitation.undisclosed_address?)   
      end        
      result << image_tag('ttb/lock.invite.gif')

      result <<   "Disclose location details to confirmed attendees only."
      result << tool_tip('Undisclosed Address',
      undisclosed_address_tool_tip() ,
      :id => (div_id = "undisclosed_tool_#{airport_version}_tt"),
      :image => '/images/ttb/questionmark.tiny.postwiz.gif')
      result.join(" ")

   end
   
  def undisclosed_checkbox_new(options)
      airport_version = options[:airport_version]
      result = []
      if( airport_version)
          result << check_box_tag('undisclosed_address_airport', "1", @invitation.undisclosed_address?)   
      else        	      
          result << check_box_tag('undisclosed_address_regular', "1", @invitation.undisclosed_address?)   
      end        
      #result << tool_tip('Undisclosed Address',
      #undisclosed_address_tool_tip() ,
      #:id => (div_id = "undisclosed_tool_#{airport_version}_tt"),
      #:image => '/images/ttb/questionmark.tiny.postwiz.gif')
      #result.join(" ")
   end


   def undisclosed_address_tool_tip
      %{
         This invite will be published without the specific location of the proposed meeting,
         although we suggest you include general location information (e.g., neighborhood, zip code, district)
         on the WHERE tab and also include venue information such as cuisine (e.g., Italian, Chinese, etc.)
         and estimated costs (e.g., very expensive, moderate) on the WHAT tab in the Description field.
         The specific location will later be transmitted to those users who you have approved to attend the meeting.
      This feature allows you to control who is able attend your proposed meeting even when the invite is published on
         MeetingWave.com.

      }
   end

   # The validation.js library will actually insert the validation messages in the correct place most of the time, but
   # we create our own error message divs in some cases just to get the message we want where we want.
   def quick_input(name, hint, validation_message, opts = { })
      result = ''
      use_opts = { :id => name }.merge(opts)

      result << content_tag('label', hint, :class => 'overlabel', :for => name)
      result << text_field_tag(name, nil, use_opts)
      if validation_message
         result << content_tag('div', validation_message, :id => "advice-required-#{name}", :class => "validation-advice", :style => "display: none;")
      end
      result = content_tag('div', result, :class => 'compact_accessible_wrap regular_field')
      result

   end

   def get_started_input(name, hint, validation_message, opts = { })
      result = ''
      use_opts = { :id => name }.merge(opts)

      result << content_tag('label', hint, :class => 'overlabel', :for => name)
      result << text_field_tag(name, nil, use_opts)
      if validation_message
         result << content_tag('div', validation_message, :id => "advice-required-#{name}", :class => "validation-advice", :style => "display: none;")
      end
      result = content_tag('div', result, :class => 'compact_accessible_wrap')
      result
   end

   def purpose_field(invitation)
      if invitation.purpose.nil?
         selected = nil
         style = 'display: none;'
         value = ''
      else
         selected = (invitation.purpose.category == 'other' ? Purpose::OTHER.id : invitation.purpose.id).to_i
         style = (invitation.purpose.category != 'other' ? 'display: none;' : '')
         value = (invitation.purpose.category == 'other' ? invitation.purpose.name : '')
      end
      result =  select_tag('invitation[purpose_id]', options_for_select(Purpose::PURPOSE_OPTS, selected), :id => 'invitation_purpose_id',:class => "select")
      result << '&nbsp;'
      result << tool_tip('Purpose', purposes_tt_html, :id => 'purpose_tt', :image => '/images/ttb/questionmark.tiny.postwiz.gif', :style=>'cursor:pointer;')
      result << '<br/>'
      other_purpose_box =   content_tag('span', "PLEASE SPECIFY: ", :style => 'font-size: 10px;')
      other_purpose_box <<   text_field_tag('other_purpose', value,:class => "select")
      result << content_tag('span', other_purpose_box, :id => 'other_purpose', :style => style)
      result << observe_field('invitation_purpose_id', :function => "if(value == #{Purpose::OTHER.id}) {  $('other_purpose').show(); } else { $('other_purpose').hide(); } ")
      if invitation.errors.on(:purpose_id)
        result = content_tag('span', result, :class => 'fieldWithErrors')
      end
      return result
   end

   def mobile_purpose_field(invitation)
	 result = ''
	 if invitation.purpose.category == 'other'
	   result << hidden_field_tag('invitation[purpose_id]', Purpose::OTHER.id)
       result <<   text_field_tag('other_purpose', invitation.purpose.name, :size => '25')
     else
	   result << select_tag('invitation[purpose_id]', options_for_select(Purpose::PURPOSE_OPTS, invitation.purpose.id))
 	 end
      return result
   end

end




