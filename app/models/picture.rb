# Schema as of Wed Jul 18 09:16:16 -0600 2007 (schema version 77)
#
#  id                  :integer(11)   not null
#  member_profile_id   :integer(11)   
#  name                :string(255)   
#  full_height         :integer(11)   
#  full_width          :integer(11)   
#  content_type        :string(255)   
#  filename            :string(255)   
#

class Picture < ActiveRecord::Base
  include Magick
  FULL_PICTURE_DIR = File.join(RAILS_ROOT, "pictures")
  ORIGINAL_RES = "400x300"
  THUMBNAIL_RES= "155x155"
  MINI_RES     = "40x40"
  belongs_to :member_profile
  

   
    validates_format_of :content_type, 
                      :with => /^image/,
                      :message => "We can not leave this box blank and can only upload images.",:if => Proc.new {|picture| picture.content_type != ""} 
                      
    
 
  
    def uploaded_picture=(picture_field)
    
    @k= picture_field.original_filename.split('.')
    
    if @k[1]=="jpeg" || @k[1]=="jpg" || @k[1]=="gif" || @k[1]=="png"
 
    self.name         = base_part_of(picture_field.original_filename)
    self.content_type = picture_field.content_type.chomp
    self.filename     = get_filename(self.name)

    raw_img = Magick::Image.read_inline(Base64.encode64(picture_field.read)).first
    raw_img.change_geometry(ORIGINAL_RES)  do |cols, rows, img| 
      resized_img = img.resize(cols, rows)
      self.full_width, self.full_height = cols, rows
      resized_img.write(self.real_fname) 
    end

    resized_img = raw_img.resize(155, 155)
    resized_img.write(self.real_thumb_fname) 
    
    resized_img = raw_img.resize(40, 40)
    resized_img.write(self.real_mini_thumb_fname)
    
 
end
    
    
  end

  def before_destroy
     if File.exist?(self.filename)
        FileUtils.rm_f(self.filename)
     end
     if File.exist?(self.thumb_filename)
        FileUtils.rm_f(self.thumb_filename)
     end
     if File.exist?(self.mini_thumb_filename)
        FileUtils.rm_f(self.mini_thumb_filename)
     end
  end

  def base_part_of(file_name)
    File.basename(file_name).gsub(/[^\w._-]/, '')
  end

  def get_filename(original_name)
    new_name = original_name
    if File.exists?(File.join(FULL_PICTURE_DIR, new_name))
      base = File.basename(original_name, ".*")
      ext = File.extname(original_name)
      i = 1
      while File.exists?(File.join(FULL_PICTURE_DIR, new_name)) 
        new_name = "#{base}-#{i += 1}#{ext}"
      end
    end
    new_name
  end

  def thumb_filename
    "#{File.basename(self.filename, '.*')}.thumb#{File.extname(self.filename)}"
  end
  
  def mini_thumb_filename
    "#{File.basename(self.filename, '.*')}.mini_thumb#{File.extname(self.filename)}"
  end

  def data
    File.open(self.real_fname, "r") { |pic| pic.read }
  end

  def thumb_data
    File.open(self.real_thumb_fname, "r") { |pic| pic.read }
  end
  
  def mini_thumb_data
    File.open(self.real_mini_thumb_fname, "r") { |pic| pic.read }
  end

   def rotate(deg)
      img = Magick::Image.read(self.real_fname).first
      img.rotate!(deg)
      img.write(self.real_fname)
      update_attributes(:full_width => img.columns, :full_height => img.rows)
      img = Magick::Image.read(self.real_thumb_fname).first
      img.rotate!(deg)
      img.write(self.real_thumb_fname)
      img = Magick::Image.read(self.real_mini_thumb_fname).first
      img.rotate!(deg)
      img.write(self.real_mini_thumb_fname)
   end

   def real_fname
     File.join(FULL_PICTURE_DIR, self.filename)
   end

   def real_thumb_fname
      File.join(FULL_PICTURE_DIR, self.thumb_filename)
   end
   
   def real_mini_thumb_fname
      File.join(FULL_PICTURE_DIR, self.mini_thumb_filename)
   end

   def crop(geometry)
      img = Magick::Image.read(self.real_fname).first 
      img.crop!(geometry[:left].to_i, geometry[:top].to_i, geometry[:width].to_i, geometry[:height].to_i)
      img.write(self.real_fname)
      update_attributes(:full_width => img.columns, :full_height => img.rows)
      img.change_geometry(THUMBNAIL_RES)  do |cols, rows, img| 
        resized_img = img.resize(155, 155)
        resized_img.write(self.real_thumb_fname) 
      end
      img.change_geometry(MINI_RES)  do |cols, rows, img| 
        resized_img = img.resize(40, 40)
        resized_img.write(self.real_mini_thumb_fname) 
      end
   end
   
   def self.make_mini_thumbs
    self.find(:all).each do | p |
      begin
        img = Magick::Image.read(p.real_fname).first
        resized_img = img.resize(40, 40)
        resized_img.write(p.real_mini_thumb_fname)
      rescue
        puts "Skipping: #{p.id}, error was: #{$!}"
      end
    end
   end

  

end
