class ApplicationController < ActionController::Base
	around_action :log_everything, only: :index

	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	# protect_from_forgery with: :null_session

	def user_has_permissions(permission_level_needed, &block)
		token = request.headers["X-Auth-Token"]
		if !token and params[:token] then
			token = params[:token]
		end
		permitted = true
		if User.where(token: token).present? then
			user = User.where(token: token).first
			permitted = (user.permissions & permission_level_needed) == permission_level_needed
		else
			permitted = false
		end

		if block then
			if permitted then
				block.call
			else
				render json: {
					:message => :error,
					:error => "Unauthorized access."
				}, :status => 401
			end
		else
			return permitted
		end
	end

	def user_from_token
		token = request.headers["X-Auth-Token"]
		User.where(token: token).first
	end
	
private
def log_everything
  log_headers
  yield
ensure
  log_response
end

def log_headers
  http_envs = {}.tap do |envs|
    request.headers.each do |key, value|
      envs[key] = value if key.downcase.starts_with?('http')
    end
  end

  logger.info "Received #{request.method.inspect} to #{request.url.inspect} from #{request.remote_ip.inspect}. Processing with headers #{http_envs.inspect} and params #{params.inspect}"
end

def log_response
  logger.info "Responding with #{response.status.inspect} => #{response.body.inspect}"
end	
	
end