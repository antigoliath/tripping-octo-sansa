class Expense < ActiveRecord::Base

  attr_accessible :cost, :exists, :location, 
  :name, :owner_id, :image, :remote_image_url

  mount_uploader :image, ImageUploader


  def connect_to_google
  	oauth_yaml = YAML.load_file('.google-api.yaml')
  	client = Google::APIClient.new
  	client.authorization.client_id = oauth_yaml["client_id"]
  	client.authorization.client_secret = oauth_yaml["client_secret"]
  	client.authorization.scope = oauth_yaml["scope"]
  	client.authorization.refresh_token = oauth_yaml["refresh_token"]
  	client.authorization.access_token = oauth_yaml["access_token"]
  
  	client
  end

  def process_image
  	client = self.connect_to_google
  	begin
	  	service = client.discovered_api('drive', 'v2')
	  	res = client.execute(:api_method => service.files.insert,
	  		:parameters => {:ocr => 'true', :body => self.image}
	  		)
	  	logger.info res
  	rescue
  		logger.info "Something's not right during image sending"
  	end
  end

end
