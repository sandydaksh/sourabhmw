module MemberHelper

  DEFAULT_HEAD_OPTIONS = {
    :notice => true,
    :message => true,
    :error => false
  }.freeze

  
  def button_helper(name, options = {})
    label = l(:"#{@controller.controller_name}_#{name}_button")
    "#{self.send(:submit_tag, label, options)}"
  end

  def link_helper(name, options = {})
    raise ArgumentError if name.nil?
    label = l(:"#{@controller.controller_name}_#{name}_link")
    "#{self.send(:link_to, label, options)}"
  end


  def head_helper(options = {})
    label = l(:"#{@controller.controller_name}_#{@controller.action_name}_head")
    notice = message = error = nil
    opts = DEFAULT_HEAD_OPTIONS.dup
    opts.update(options.symbolize_keys)
    s = "<h3>#{label}</h3>"
    if flash[:message] and not opts[:message].nil? and opts[:message]
      message = "<div id=\"ErrorExplanation\"><p>#{flash[:message]}</p></div>"
      s = s + message
    end
    if not opts[:error].nil? and opts[:error]
     error = error_messages_for('member')
     if not error.nil?
       error = error + "<br/>"
       s = s + error
     end
   end
   return s
<<-EOL
    <h3>#{label}</h3>
    #{message}
    #{error}
EOL
  end

  def message_helper(name)
    l(:"#{@controller.controller_name}_#{name}_message")
  end

  def form_tag_helper(options = {})
    url = url_for(:action => "#{@controller.action_name}")
    "#{self.send(:form_tag, url, options)}"
  end

  def attributes(hash)
    hash.keys.inject("") { |attrs, key| attrs + %{#{key}="#{h(hash[key])}" } }
  end

  def read_only_field(form_name, field_name, html_options)
    "<span #{attributes(html_options)}>#{instance_variable_get('@' + form_name)[field_name]}</span>"
  end
  
  def submit_button(form_name, prompt, html_options)
    %{<input name="submit" type="submit" value="#{prompt}" />}
  end

  def changeable(member, field)
    if member.new_record? or MemberSystem::CONFIG[:changeable_fields].include?(field)
      :text_field
    else
      :read_only_field
    end
  end

  def password_confirmation_field(opts = { })
	opts.merge!(:class => 'txt') unless opts[:class]
    res = password_field_tag('member[password_confirmation]', nil, opts)
    if @member.errors.on(:password)
      return content_tag('span', res, :class => 'fieldWithErrors')
    else
      return res
    end
  end
  
  def password_error
    password_err = (Array(@member.errors.on(:password)).first rescue nil)
    logger.error("PASSWORD: #{password_err}")
    return '' if password_err.blank?
    unless password_err.starts_uppercase?
       password_err = "Password #{password_err}."
    end
    return password_err
  end
    
  def mini_icon_for_autocomplete(member)
    if member.is_a?(Member) && member.member_profile && member.member_profile.picture 
      return image_tag(mini_thumb_url(:id => member.member_profile.picture.id, :dontcache => Time.now.to_i.to_s), :alt => '--') 
    else 
      return image_tag("/images/ttb/little_guy_light_bg.gif") 
    end
  end
end
