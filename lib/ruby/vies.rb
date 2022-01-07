# frozen_string_literal: true

require_relative "vies/version"
require "savon"
require "httparty"
require "finest/builder"
require 'active_support/isolated_execution_state'
require "active_support/core_ext/module"
require "active_support/core_ext/object"

module Ruby
  module Vies
    class Error < StandardError; end

    class Client
      include Savon
      include HTTParty
      include Finest::Builder

      mattr_reader :id_numbers, default: { FR: "((12 + 3 * ( %d.divmod(97)[1])).divmod(97)[1])" }

      def initialize(args = {})
        super args
      end

      def check_vat_details(args = {})
        args[:country_code].upcase == "FR" ? check_siren(args) : check_vat(args)
      rescue => e
        { error: e&.message, valid: false }
      end

      protected

      def generate_id(vat = {})
        id_numbers[vat[:country_code].to_sym] &&
          "%02<digit>d%<vat>d" % {
            digit: eval(id_numbers[vat[:country_code].to_sym] % vat[:vat_number]),
            vat: vat[:vat_number]
          } || vat[:vat_number]
      rescue
        vat[:vat_number]
      end

      def check_vat(args = {})
        Savon::Client.new(wsdl: "https://ec.europa.eu/taxation_customs/vies/checkVatService.wsdl")
                     .call(
                       :check_vat,
                       message: args.merge({ vat_number: generate_id(args) }).as_json.transform_keys! { |i| i.camelize(:lower) },
                       message_tag: :checkVat
                     ).body[:check_vat_response].as_json(except: :@xmlns)
      end

      def check_siren(args = {})
        url = "https://api.avis-situation-sirene.insee.fr/identification/siren/#{args.fetch(:vat_number)}"
        if (resp = JSON.parse(self.class.method(:get).call(url).body))["code"]
          { error: resp["message"], valid: false }
        else
          {
            valid: true,
            name: resp.dig("uniteLegale", "periodesUniteLegale")&.first&.dig("denominationUniteLegale"),
            address: resp.dig("etablissements")&.first&.dig("adresseEtablissement").values.join(" "),
            siren: resp.dig("etablissements")&.first&.dig("siren"),
            siret: resp.dig("etablissements")&.first&.dig("siret"),
            nic: resp.dig("etablissements")&.first&.dig("nic"),
            created: resp.dig("etablissements")&.first&.dig("dateCreationEtablissement")
          }
        end

      end
    end
  end
end
