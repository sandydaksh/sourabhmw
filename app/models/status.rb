class Status
  attr_accessor :id, :name, :simple_name

  def initialize(options = {})
    options = options.symbolize_keys
    @id, @name, @simple_name = options[:id], options[:name], options[:simple_name]
  end   

  
  def symbol
    @name.to_s.downcase.intern
  end
  
  def self.[](value)
    @@statuses.select { |status| status.symbol == value.to_s.downcase.intern }.first
  end
  
  def self.find(value)
    if @@statuses.collect { |s| s.id }.include?(value)
      @@statuses.select { |s| s.id.to_s == value.to_s }.first
    elsif @@statuses.collect { |s| s.symbol }.include?(value.to_sym)
      @@statuses.select { |s| s.symbol == value.to_sym }.first
    elsif value.to_sym == :all
      @@statuses.dup
    else
      "Couldn't find a Status using '#{value}'. Please try another id or string or use :all for all statuses."
    end
  end
  
  def self.find_all
    self.find(:all)
  end

  def <=>(other)
    id <=> other.id
  end
  
  def self.ids_for(*names)
		names.collect{|name| id_for(name) }   
	end  
	
	def self.id_for(name)
		  name_to_status_map[name.to_s].first.id
	end    
	
	def self.name_to_status_map  
		@@name_to_status_map ||= @@statuses.group_by(&:name)
	  
	end   
	
	def to_s
		 self.id.to_s
	end
	
  @@statuses = [
    Status.new( :id => 5,   :name => 'active',    :simple_name => 'Active'),
    Status.new( :id => 10,  :name => 'expired',   :simple_name => 'Expired'),
    Status.new( :id => 105, :name => 'accepted',  :simple_name => 'Invite Requested'),    # Peter pledge
    Status.new( :id => 110, :name => 'approved',  :simple_name => 'Invited'),    # Pre selected invitee
    Status.new( :id => 120, :name => 'confirmed', :simple_name => 'Attending'),
    Status.new( :id => 119, :name => 'declined',  :simple_name => 'Declined'),
    Status.new( :id => 130, :name => 'modified',  :simple_name => 'Modified'),
    Status.new( :id => 100, :name => 'saved',     :simple_name => 'Watching'),
    Status.new( :id => 500, :name => 'rejected',  :simple_name => 'Declined'),
    Status.new( :id => 1000, :name => 'new',       :simple_name => 'New'),
  ]    

  NOT_ATTENDING = [Status[:approved], Status[:accepted],Status[:rejected],Status[:declined] ]  
  
  INVITE_REQUESTED = Status['accepted']
  INVITED = Status['approved']

end
