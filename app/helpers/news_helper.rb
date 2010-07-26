module NewsHelper
 
 def title_prefix
    in_the_news? ?  "MW In the News" : "MW Blog"
 end
 
 def header_title
     title_prefix
 end
 
 def archives_title
  in_the_news? ? "News Archives" : "Blog Archives"
 end
 
 def month_link(month)
  in_the_news? ? in_news_month_url(month) : blog_month_url(month)
  
 end
 
 def blog_link(path)
 "http://" + request.host_with_port + path
 end
 
 def rss_title
    in_the_news? ? "MW In The News" : "MW Blog"
 end
 
 def rss_home_link
    in_the_news? ? in_news_home_url : blog_home_url
 end
 
 def rss_description
     in_the_news? ? "Feed for news events relating to MeetingWave" : "A blog about MeetingWave and the importance of offline networking"
 end
 
 def rss_link
  in_the_news? ? in_news_rss_url : blog_rss_url
 end
 
 
 def in_the_news?
  params[:type] == "news"
 end
end
