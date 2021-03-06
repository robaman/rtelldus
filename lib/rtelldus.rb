require "rtelldus/version"
require 'oauth'
require 'json'
require 'user_config'

module Rtelldus
  @uconf = UserConfig.new(".rtelldus")
  def self.authorize
    # Get API settings
    unless File.exists? @uconf['api_settings.yaml'].path
      # No configuration exists, let's request some credentials from the user
      # Fetch the public and private keys from command line
      puts "The first time you use the API you need to enter your Public and Private keys, they can be generated at:"
      puts "\thttp://api.telldus.com/keys/index"
      puts "\nPublic Key:"
      public_key = $stdin.gets.strip
      @uconf["api_settings.yaml"]["consumer_key"] = public_key
      puts "\nPrivate Key:"
      private_key = $stdin.gets.strip
      @uconf["api_settings.yaml"]["consumer_secret"] = private_key
      ## Persistent settings
      @uconf["api_settings.yaml"]["api_host"] = "http://api.telldus.com"
      @uconf["api_settings.yaml"]["request_token_path"] = "/oauth/requestToken"
      @uconf["api_settings.yaml"]["access_token_path"] = "/oauth/accessToken"
      @uconf["api_settings.yaml"]["authorize_path"] = "/oauth/authorize"
      # Save for later use
      @uconf["api_settings.yaml"].save
    end

    # Setup OAuth
    consumer_options = { :site => @uconf["api_settings.yaml"]['api_host'],
                         :authorize_path => @uconf["api_settings.yaml"]['authorize_path'],
                         :request_token_path => @uconf["api_settings.yaml"]['request_token_path'],
                         :access_token_path => @uconf["api_settings.yaml"]['access_token_path'] }
    consumer = OAuth::Consumer.new(@uconf["api_settings.yaml"]['consumer_key'], @uconf["api_settings.yaml"]['consumer_secret'], consumer_options)

    if File.exists? @uconf["api_token.yaml"].path
      @access_token = OAuth::AccessToken.new(consumer, @uconf["api_token.yaml"]["access_token"], @uconf["api_token.yaml"]["access_secret"])
    else
      # No configuration exists, let's request some access tokens
      # Fetch a new access token and secret from the command line
      request_token = consumer.get_request_token
      puts "Copy and paste the following URL in your browser:"
      puts "\t#{request_token.authorize_url}"
      puts "When you sign in and accept, press enter.."
      verifier = $stdin.gets.strip
      access_token = request_token.get_access_token(:oauth_verifier => verifier)
      # Save the token and secret so the script can be used automatically in the future
      @uconf["api_token.yaml"]["access_token"] = access_token.token
      @uconf["api_token.yaml"]["access_secret"] = access_token.secret
      @uconf["api_token.yaml"].save
      @access_token = OAuth::AccessToken.new(consumer, @uconf["api_token.yaml"]["access_token"], @uconf["api_token.yaml"]["access_secret"])
    end
  end

  ## Clients
  def self.clients_list
    authorize unless @access_token
    json_txt = @access_token.get("/json/clients/list", 'x-li-format' => 'json').body
    clients = JSON.parse(json_txt)
  end

  ## Devices
  def self.devices_list
    authorize unless @access_token
    json_txt = @access_token.get("/json/devices/list", 'x-li-format' => 'json').body
    devices = JSON.parse(json_txt)
  end

  def self.device_info device_id
    authorize unless @access_token
    json_txt = @access_token.post("/json/device/info", {"id" => device_id}, 'x-li-format' => 'json').body
    status = JSON.parse(json_txt)
  end

  def self.device_turn_on device_id
    authorize unless @access_token
    json_txt = @access_token.post("/json/device/turnOn", {"id" => device_id}, 'x-li-format' => 'json').body
    status = JSON.parse(json_txt)
  end

  def self.device_turn_off device_id
    authorize unless @access_token
    json_txt = @access_token.post("/json/device/turnOff", {"id" => device_id}, 'x-li-format' => 'json').body
    status = JSON.parse(json_txt)
  end

  def self.device_dim device_id, level
    raise "Invalid dimlevel, this value should be 0-255" if level < 0 or level > 255
    authorize unless @access_token
    json_txt = @access_token.post("/json/device/dim", {"id" => device_id, "level" => level}, 'x-li-format' => 'json').body
    status = JSON.parse(json_txt)
  end

  def self.device_bell device_id
    authorize unless @access_token
    json_txt = @access_token.post("/json/device/bell", {"id" => device_id}, 'x-li-format' => 'json').body
    status = JSON.parse(json_txt)
  end

  ## Sensors
  def self.sensors_list
    authorize unless @access_token
    json_txt = @access_token.get("/json/sensors/list", 'x-li-format' => 'json').body
    devices = JSON.parse(json_txt)
  end

  def self.sensor_info sensor_id
    authorize unless @access_token
    json_txt = @access_token.post("/json/sensor/info", {"id" => sensor_id}, 'x-li-format' => 'json').body
    status = JSON.parse(json_txt)
  end
end
