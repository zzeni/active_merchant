require File.dirname(__FILE__) + '/e24_payment_pipe/message'
require File.dirname(__FILE__) + '/e24_payment_pipe/errors'
require File.dirname(__FILE__) + '/e24_payment_pipe/secure_settings'
require File.dirname(__FILE__) + '/e24_payment_pipe/parser'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class E24PaymentPipeGateway < Gateway
      attr_reader :settings
      attr_reader :response
      attr_accessor :id
      attr_accessor :page

      def initialize(settings = {})
        @settings = {}.merge!(values_to_string(settings))
      end

      def init_payment
        check_required(:action, :currency_code, :lang_id, :response_url, :error_url,
                       :track_id, :resource_file, :alias, :amount)

        secure_settings = E24PaymentPipe::SecureSettings.new(@settings)
        secure_data = secure_settings.secure_data

        @response = E24PaymentPipe::Message.new(@settings.merge(secure_data)).send(:payment)

        parse_payment_response
      end

      def process_transaction
        @response = E24PaymentPipe::Message.new(@settings).send(:transaction)
      end

      private

      def values_to_string(hash)
        hash.map { |key, value| { key.to_sym => value.to_s } }.inject(:merge)
      end

      def parse_payment_response
        raise E24PaymentPipe::PaymentError, 'Response is blank' if @response.blank?
        raise E24PaymentPipe::PaymentError, @response if @response.include?('!ERROR!')

        match = /:/.match(@response)

        unless match.nil?
          @payment_id = match.pre_match
          @page = match.post_match
        end
      end

      def check_required(*args)
        args.each do |arg|
          msg = replace_underscore(arg.to_s)
          raise E24PaymentPipe::PaymentError, "Please set #{msg}" if @settings[arg].blank?
        end
      end

      def replace_underscore(str)
        str.gsub("_", " ")
      end

    end
  end
end
