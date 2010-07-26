class NewsController < ApplicationController

 layout 'news'
  
 before_filter :admin_required, :only => ["admin_area","draft"]
 before_filter :setup , :except => "rss"
 def article
  published_date = Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
  @article = @klass.find(:first, :conditions => ['permalink = ? AND DATE(published_at) = ?', params[:permalink], published_date])
  @article = @klass.find(:first, :conditions => ['permalink = ?', params[:permalink]]) unless @article
  render :layout => false if params[:format] == "mp" and @article
  redirect_to( :action => "index" ) and return unless @article
 end

 def index
  @article = @all_articles.first      
  render :action => 'article'
 end
  
 def month
  @articles = @all_articles.select{|a| article_to_month_string(a) == params[:month]}
 end
  
 def admin_area
  @articles = @klass.find(:all, :order => 'published_at DESC')
  render :action => 'month'
 end
  
 def draft
  @article = @klass.find(params[:id])
  redirect_to( :action => "index" ) and return unless @article 
  render :action => "article"
 end
  
 def rss
    @klass = params[:type]  == "news" ? NewsArticle : BlogArticle

  @articles = @klass.find(:all, :conditions => [ '(draft is NULL OR draft = 0)'], :order => 'published_at DESC', :limit => 10)
  render :layout => false
 end

  
 private 
  
 def setup
  @klass = params[:type]  == "news" ? NewsArticle : BlogArticle
  @all_articles = @klass.find(:all, :conditions => [ '(draft is NULL OR draft = 0)'], :order => 'published_at DESC')
  @months = @all_articles.map{|a| article_to_month_string(a)}.uniq
 end
  
 def article_to_month_string(a)
  a.published_at.strftime("%B %Y")
 end
end
