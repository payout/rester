module ApiHelper
  def http_basic_header(username, password)
    {
      'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.
        encode_credentials(username, password)
    }
  end
end
