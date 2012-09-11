class Expense < ActiveRecord::Base
	attr_accessible :cost, :exists, :location, :expire_time,
	:name, :owner_id, :image, :google_doc_id, :remote_image_url,
	:access_token
	attr_accessor :client
	mount_uploader :image, ImageUploader

	def check_expire_time!
		if(!expire_time || expire_time+50 < Time.now)
			get_service_token
		end
	end

  	def get_service_token
  		# when the token will expire
		self.expire_time = Time.now+3600
		self.save
		oauth_yaml = YAML.load_file('.google-api.yaml')		

		begin
			# load in private key
			keydata = nil
			File.open(Rails.root.to_s+"/config/google_api_key.p12",:encoding => "binary") {|f| keydata = f.read(); }
			pk = OpenSSL::PKCS12.new(keydata,"notasecret")
			# generate the JWT
			jwt = JWT.encode({
			  :iss    => "1068974786990-t0ioqtrnes5nk86r7be3l3vgsmen8bf7@developer.gserviceaccount.com",
			  :scope  => oauth_yaml["scope"],
			  :aud    => "https://accounts.google.com/o/oauth2/token",
			  :exp    => (Time.now + 3600).to_i,
			  :iat    => Time.now.to_i
			},pk.key,"RS256")

			# -- Convert into an OAUTH2 Token -- #
			uri = URI("https://accounts.google.com/o/oauth2/token")
			req = Net::HTTP::Post.new uri.path
			req.set_form_data(:grant_type => "assertion", :assertion_type => "http://oauth.net/grant_type/jwt/1.0/bearer", :assertion => jwt)

			conn = Net::HTTP.new uri.host, uri.port
			conn.use_ssl = true
			resp = conn.start do |http|
			  http.request(req)
			end

			json = JSON.parse(resp.body)
			# token is at json['access_token']		
			self.access_token = json['access_token']
			self.save

			json
		rescue
			logger.info "Something wrong with getting token"
		end
	end

	def send_image_to_google
		check_expire_time!
		oauth_yaml = YAML.load_file('.google-api.yaml')		
		begin
			@client = Google::APIClient.new
			@client.authorization.access_token = self.access_token
			
		  	service = @client.discovered_api('drive', 'v2')

		  	logger.info @client
		  	res = @client.execute!(
		  		:api_method => service.files.insert,
		  		:body => image.read,
		  		:headers => {
		  			'Content-Type' => 'image/png'
		  		},
		  		:convert => 'true',
		  		:mimeType => 'image/png',
		  		:parameters => {
		  			:uploadType => 'multipart',
		  			:ocr => 'true',
		  			})
		  	self.google_doc_id = res.data.id
		  	self.save
		  	res.data.id
		rescue
			logger.info "Something's not right during image sending"
		end
	end

	def parse_google_doc
		check_expire_time!
		oauth_yaml = YAML.load_file('.google-api.yaml')		
		begin
			@client = Google::APIClient.new
			@client.authorization.access_token = self.access_token
			
		  	service = @client.discovered_api('drive', 'v2')
			res = @client.execute!(:api_method => service.files.get,
				:parameters => {:fileId => self.google_doc_id})
			logger.info res
		rescue
			logger.info "Something's not right during retrieval of document"
		end
	end

end
