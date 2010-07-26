require 'RMagick'
class University < ActiveRecord::Base
  has_many :aluminis
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :url
  validates_uniqueness_of :url
  validates_presence_of :welcome_text
  validates_presence_of :text_header
  validates_presence_of :signup_text
  has_many :email_domains
  has_many :alt_paths
  
  def logo=(input_data) 
    pic = Magick::Image.read_inline(Base64.encode64(input_data.read)).first
    imgwidth = pic.columns
    imgheight = pic.rows    

    if imgheight > 50
      thumbHt = 50
      percent = ( thumbHt * 100 ) / imgheight.to_f
      thumbWd = ( imgwidth * percent ) / 50
      img = pic.thumbnail(thumbWd, thumbHt)
      self.filename = input_data.original_filename 
      self.content_type = input_data.content_type.chomp 
      self.binary_data = img.to_blob 
    else
      self.filename = input_data.original_filename 
      self.content_type = input_data.content_type.chomp 
      self.binary_data = pic.to_blob 
    end  
  end   

end
