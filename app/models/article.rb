class Article < ActiveRecord::Base

  belongs_to :author, :class_name => "Member", :foreign_key => "author_id"
  
  before_create :create_permalink
  before_save :publish
  
  TYPES = ["BlogArticle", "NewsArticle"]
  def create_permalink
    str = self.title
    self.permalink = str.gsub(/\W+/, ' ').strip.downcase.gsub(/\ +/, '-')
  end
  
  def full_permalink
   
    base = in_the_news? ? "in_news" : "blog"
    if published? 
      ["/#{base}", published_at.year, published_at.month, published_at.day, permalink] * '/'
    else
      "/#{base}/draft/#{self.id}"
    end
  end
  
  [:year, :month, :day].each do |m|
   define_method(m) do 
    published_at.send(m)
   end
  end
  
  def published?
    !draft?
  end
  
  def publish
    unless draft?
      self.published_at ||= Time.now
    end
  end
  
  def in_the_news?
    self.class == NewsArticle
  end
  
end
