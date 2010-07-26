class YelpController < ApplicationController

	def yelp
		client = Yelp::Client.new
		request = Yelp::Review::Request::BoundingBox.new(
                :bottom_right_latitude => params['br_lat'],
                :bottom_right_longitude => params['br_long'],
                :top_left_latitude => params['tl_lat'],
                :top_left_longitude => params['tl_long'],
                :radius => 2,
				:num_biz_requested => 10,
                :term => params['term'],
                :yws_id => YWSID)
		response = client.search(request)

		render :json => response

	end

end
