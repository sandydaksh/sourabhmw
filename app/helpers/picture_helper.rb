module PictureHelper

  def pic_url(pic)
    show_picture_url(:id => pic.id, :dontcache => Time.now.to_i.to_s)
  end

end
