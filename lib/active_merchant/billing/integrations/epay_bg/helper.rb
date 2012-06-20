require 'base64'
require 'openssl'
require 'date'
require 'uri'
require 'net/http'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module EpayBg
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          mapping :account           , 'MIN_OR_EMAIL'
          mapping :amount            , 'AMOUNT'
          mapping :cancel_return_url , 'URL_CANCEL'
          mapping :currency          , 'CURRENCY'
          mapping :description       , 'DESCR'
          mapping :order             , 'INVOICE'
          mapping :return_url        , 'URL_OK'
          mapping :expiration_date   , 'EXP_TIME'

          def initialize(order, account, options = {})
            super
            add_field('PAGE', 'paylogin')

            if options[:credential2].nil?
              raise ArgumentError,
                'You need to provide the secret key as the option :credential2'
            end
            @secret = options[:credential2]
            @ssl_strict = ssl_strict
          end

          def expiration_date(value)
            # EXP_TIME=DD.MM.YYYY[ hh:mm[:ss]]
            exp_time = value
            if value.kind_of? Time
              exp_time = value.strftime '%d.%m.%Y %H:%M:%S'
            elsif value.kind_of? Date
              exp_time = value.strftime '%d.%m.%Y'
            end
            add_field('EXP_TIME', exp_time)
          end

          def encoded
            return @encoded unless @encoded.nil?

            data = {
              'INVOICE'  => @fields['INVOICE'],
              'AMOUNT'   => @fields['AMOUNT'],
              'EXP_TIME' => @fields['EXP_TIME'] || '01.08.2020',
            }
            if @fields['MIN_OR_EMAIL'] =~ /^\w\d+$/
              data['MIN'] = @fields['MIN_OR_EMAIL']
            else
              data['EMAIL'] = @fields['MIN_OR_EMAIL']
            end
            if @fields['DESCR']
              data['DESCR'] = @fields['DESCR'].gsub("\n", ' ')
              data['ENCODING'] = 'utf-8'
            end

            data_string = data.collect { |k, v| "#{k}=#{v}" }.join "\n"
            @encoded = Base64.encode64(data_string).gsub("\n", '')
          end

          def checksum
            @checksum ||= OpenSSL::HMAC.hexdigest('sha1', @secret, encoded).upcase
          end

          def form_fields
            fields = {
              'PAGE'     => @fields['PAGE'],
              'ENCODED'  => encoded,
              'CHECKSUM' => checksum,
            }
            fields['URL_OK']     = @fields['URL_OK'] if @fields['URL_OK']
            fields['URL_CANCEL'] = @fields['URL_CANCEL'] if @fields['URL_CANCEL']
            fields
          end

          def issue_easypay_token
            response = request_easypay_token
            parse_easypay_token_response(response)
          end

          def request_easypay_token
            params = {
              'ENCODED'  => encoded,
              'CHECKSUM' => checksum,
            }
            uri = URI.parse(easypay_token_url)
            uri.query = URI.encode_www_form(params)

            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict

            request = Net::HTTP::Get.new(uri.path + (uri.query.empty? ? '' : "?#{uri.query}"))
            response = http.start {|http| http.request(request) }

          end

          def parse_easypay_token_response(response)
            if response kind_of?(Net::HTTPSuccess)
              result = response.body.encode('UTF-8', 'cp1251')
              match_data = result.match(/^IDN=(\d{10})/) and return match_data[1]

              raise StandardError, "Response doesn't contain token, or has wrong format: #{result}"
            end

            raise StandardError, "Request for Easypay token failed: #{response.header}"
          end
        end
      end
    end
  end
end
