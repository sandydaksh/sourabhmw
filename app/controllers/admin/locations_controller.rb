class Admin::LocationsController < ApplicationController   
  layout 'admin'

  def index

  end

  def search
    @zip_codes = ZipCode.find_all_by_city_and_state(params[:city], params[:state])

    unless @zip_codes.blank?
      @zip_code_name = "#{@zip_codes.first.city}, #{@zip_codes.first.state}"
    end

    render :update do |page|
      page.replace_html 'zip_code_name', @zip_code_name
      page.replace_html 'zip_codes', @zip_codes.collect(&:zip).uniq.join(', ') 
      page.replace_html 'existing_aliases', @zip_codes.collect(&:city_alias_name).uniq.join(', ') 
      page.show 'step2'
      page.call('setSelectedZip', @zip_codes.first.id)
    end
  end

  def add_alias
    @zip_code = ZipCode.find(params[:selected_zip_id])
    @zip_codes = ZipCode.find(:all, :conditions => [ " city = ? and state = ? ", @zip_code.city, @zip_code.state], :group => :zip)

    # Now create a duplicate record for each zip code using the new alias.  Everything else is the same...
    @zip_codes.each do |zip_code|
      attrs = zip_code.attributes.dup
      attrs.delete("id")
      attrs["city_alias_name"] = params[:alias]
      ZipCode.create_with_attributes_and_point(attrs)
    end
    redirect_to :action => "alias_added", :id => @zip_code.id, :alias => params[:alias]
  end

  def alias_added
    @zip_code = ZipCode.find(params[:id]) 
    @alias = params[:alias]
    @invitations = @zip_code.all_invitations_with_same_city_state
    return unless request.post?
    errors = []
    @invitations.each do |inv| 
      begin
        inv.save 
      rescue
        errors << "INVITE=#{inv.name};ID=#{inv.id};ERROR=#{$!}"
      end
    end
    if errors.size.zero?
      flash[:notice] = "Successfully added alias #{params[:alias]} and re-indexed #{@invitations.size} Invites."
    else
      flash[:notice] = "Added alias #{params[:alias]} and re-indexed #{@invitations.size - errors.size} out of #{@invitations.size} Invites.  <br> There were #{errors.size} errors:<ul> <li>#{errors.join("<li>")}</ul>."
    end
    redirect_to :action => "index"
  end

end
