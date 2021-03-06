require 'geocoder/lookups/base'
require "geocoder/results/esri"
require 'geocoder/esri_token'

module Geocoder::Lookup
  class Esri < Base

    def name
      "Esri"
    end

    private # ---------------------------------------------------------------

    def base_query_url(query)
      action = query.reverse_geocode? ? "reverseGeocode" : "find"
      "#{protocol}://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/#{action}?"
    end

    def results(query)
      return [] unless doc = fetch_data(query)

      if (!query.reverse_geocode?)
        return [] if !doc['locations'] || doc['locations'].empty?
      end

      if (doc['error'].nil?)
        return [ doc ]
      else
        return []
      end
    end

    def query_url_params(query)
      params = {
        :f => "pjson",
        :outFields => "*"
      }
      if query.reverse_geocode?
        params[:location] = query.coordinates.reverse.join(',')
      else
        params[:text] = query.sanitized_text
      end
      params[:token] = token
      if for_storage_value = for_storage(query)
        params[:forStorage] = for_storage_value
      end
      params[:sourceCountry] = configuration[:source_country] if configuration[:source_country]
      params.merge(super)
    end

    def for_storage(query)
      if query.options.has_key?(:for_storage)
        query.options[:for_storage]
      else
        configuration[:for_storage]
      end
    end

    def token
      create_and_save_token! if !valid_token_configured? and configuration.api_key
      configuration[:token].to_s unless configuration[:token].nil?
    end

    def valid_token_configured?
      !configuration[:token].nil? and configuration[:token].active?
    end

    def create_and_save_token!
      save_token!(create_token)
    end

    def create_token
      Geocoder::EsriToken.generate_token(*configuration.api_key)
    end

    def save_token!(token_instance)
      Geocoder.merge_into_lookup_config(:esri, token: token_instance)
    end
  end
end
