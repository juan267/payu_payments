require 'httparty'
require "base64"
require 'ostruct'

module PayuPayments
  class Caller
    include ::HTTParty
    include Model
 
    API = "https://api.payulatam.com"
    API_SANDBOX = "https://stg.api.payulatam.com"

    attr_accessor :access, :base, :resource, :errors
    format :json
    debug_output $stdout

    def set_base_uri
      if PayuPayments.config[:mode] == "production"
        self.class.base_uri API
      else
        self.class.base_uri API_SANDBOX
      end
    end

    def initialize(params={})
      self.set_base_uri
      @access = PayuPayments.config
      @base = OpenStruct.new
      base.marshal_load params
      @errors = []
    end
 
    def http_call(type, url, params={})
        if type == "post" || type == "put"
            headers = { 'Accept' => "application/json", 
                        'Content-Type' => 'application/json; charset=UTF-8',
                        'Authorization' => "Basic #{basic_auth.to_s}"}
            resp = self.class.send(type, url, :body => params.to_json, :verify => (access[:mode] == "production"), :headers => headers)
        else
            headers = { 'Accept' => "application/json", 
                        'Authorization' => "Basic #{basic_auth.to_s}"}
            resp = self.class.send(type, url, :query => params, :verify => (access[:mode] == "production"), :headers => headers)
        end

        respond_with = (resp == "" or resp.nil?) ? {} : resp.inject({ }) { |h, (k,v)| h[k.to_sym] = v; h }

        if resp.code.to_s.match(/2\d\d/)
          respond_with
        else
          [respond_with[:type], respond_with[:description]]
        end
    end


private

    def basic_params
        { :language => "ES", 
          :test => (access[:mode] == "development"),
          :merchant => { :apiLogin => access[:api_login], 
                         :apiKey => access[:api_key]
                        }
        }
    end

    def basic_auth
        Base64.encode64("#{access[:api_login]}:#{access[:api_key]}")
    end

  end
end
