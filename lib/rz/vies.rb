# frozen_string_literal: true

require_relative "vies/version"
require "savon"
require "httparty"
require "finest/builder"
require "active_support/isolated_execution_state"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/module"
require "active_support/core_ext/object"

module Rz
  module Vies
    class Error < StandardError; end

    mattr_accessor :endpoints, default: {
      siren: "https://api.insee.fr/entreprises/sirene/siren/%<siren>s",
      siren_token: "https://api.insee.fr/token?grant_type=client_credentials&client_id=%<id>s&client_secret=%<secret>s&validity_period=%<period>s",
      vat: "https://ec.europa.eu/taxation_customs/vies/services/checkVatService.wsdl"
    }
    mattr_accessor :customer_key, default: ENV["SIREN_CUSTOMER_KEY"]
    mattr_accessor :customer_secret, default: ENV["SIREN_CUSTOMER_SECRET"]

    # Setup data from initializer
    def self.setup
      yield(self)
    end

    class Client
      include Savon
      include HTTParty
      include Finest::Builder

      mattr_reader :id_numbers, default: { FR: "((12 + 3 * ( %d.divmod(97)[1])).divmod(97)[1])" }

      def initialize(args = nil)
        super args || {}
      end

      def check_vat_details(args)
        (args[:country_code].upcase == "FR" ? check_siren(args) : check_vat(args)).with_indifferent_access
      rescue StandardError => e
        { error: e&.message, valid: false }
      end

      protected

      def generate_id(vat)
        id_numbers[vat[:country_code].to_sym] &&
          "%02<digit>d%<vat>d" % {
            digit: eval(id_numbers[vat[:country_code].to_sym] % vat[:vat_number]),
            vat: vat[:vat_number]
          } || vat[:vat_number]
      rescue StandardError
        vat[:vat_number]
      end

      def check_vat(args)
        Savon::Client.new(wsdl: Rz::Vies.endpoints[:vat])
                     .call(
                       :check_vat,
                       message: args.merge({ vat_number: generate_id(args) }).as_json.transform_keys! { |i| i.camelize(:lower) },
                       message_tag: :checkVat
                     ).body[:check_vat_response].as_json(except: :@xmlns)
      end

      def check_siren(args)
        url = Rz::Vies.endpoints[:siren] % { siren: args.fetch(:vat_number) }
        if (
          resp = JSON.parse(
            self.class.method(:get).call(
              url,
              headers: {
                authorization: "Bearer #{siren_token}",
                'Content-Type': 'application/json'
              }
            ).body
          )
        ).dig("header", "statut") != 200
          { error: resp["header"]["message"], valid: false }
        else
          {
            valid: true,
            name: resp.dig("uniteLegale", "periodesUniteLegale")&.first&.dig("denominationUniteLegale"),
            address: "",
            siren: resp.dig("uniteLegale", "siren"),
            siret: "",
            nic: resp.dig("uniteLegale", "periodesUniteLegale")&.first&.dig("nicSiegeUniteLegale"),
            created: resp.dig("uniteLegale", "periodesUniteLegale")&.first&.dig("dateDebut"),
          }
        end
      end

      private

      def siren_token
        url = Rz::Vies.endpoints[:siren_token] % {
          id: Rz::Vies.customer_key,
          secret: Rz::Vies.customer_secret,
          period: 604800
        }
        resp = self.class.method(:post).call(url)
        JSON.parse(resp.body)["access_token"]
      end
    end
  end
end
