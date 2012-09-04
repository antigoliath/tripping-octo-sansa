class Expense < ActiveRecord::Base

  	attr_accessible :cost, :exists, :location, 
  	:name, :owner_id, :image, :google_doc_id

	before do
	  # Make sure access token is up to date for each request
	  api_client.authorization.update_token!(session)
	  if api_client.authorization.refresh_token &&
	      api_client.authorization.expired?
	    api_client.authorization.fetch_access_token!
	  end
	end

	def api_client
		oauth_yaml = YAML.load_file('.google-api.yaml')
		client = Google::APIClient.new
		client.authorization.client_id = oauth_yaml["client_id"]
		client.authorization.client_secret = oauth_yaml["client_secret"]
		client.authorization.scope = oauth_yaml["scope"]
		client.authorization.refresh_token = oauth_yaml["refresh_token"]
		client.authorization.access_token = oauth_yaml["access_token"]

		client
	end

	def send_image_to_google
		client = self.api_client
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

	def parse_google_doc
		client = self.api_client
		begin
			service = client.discovered_api('drive', 'v2')
			res = client.execute(:api_method => service.files.get,
				:parameters => {:fileId => self.google_doc_id})
			logger.info res
		rescue
			logger.info "Something's not right during retrieval of document"
		end
	end

end
