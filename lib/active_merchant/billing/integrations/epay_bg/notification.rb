require 'openssl'
require 'time'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module EpayBg
        class Notification < ActiveMerchant::Billing::Integrations::Notification

          # Whole bulk must be acknowledged manually
          def self.bulk_acknowledged?(raw, secret)
            params = parse_raw_params(raw)

            if params['ENCODED'].nil? || params['CHECKSUM'].nil?
              raise ArgumentError, "No parameters or wrong format given"
            end

            checksum = OpenSSL::HMAC.hexdigest('sha1', secret, params['ENCODED'])
            return checksum.upcase == params['CHECKSUM'].upcase
          end

          def self.get_bulk(raw)
            params = parse_raw_params(raw)

            notifications = []
            decoded = Base64.decode64(params['ENCODED'])
            decoded.split("\n").each do |item_data|
              notifications << self.new(item_data.gsub(':', '&'))
            end
            notifications
          end

          def item_response(status, error = nil)
            status = 'ERR' unless %w(OK NO ERR).include? status

            response = "INVOICE=#{item_id}:STATUS=#{status}"
            response += ":ERR=#{error.to_s}" if error
            response
          end

          def complete?
            status == 'Completed'
          end

          def item_id
            params['INVOICE']
          end

          def transaction_id
            params['STAN']
          end

          # When was this payment received by the client.
          def received_at
            Time.strptime(params['PAY_TIME'], '%Y%m%d%H%M%S') rescue nil
          end

          # the money amount we received in X.2 decimal.
          def gross
            # send only on discount
            params['AMOUNT']
          end

          # send only on discount
          def card_bin
            params['BIN']
          end

          def currency
            'BGN'
          end

          def authorization_code
            params['BCODE']
          end

          def status_code
            params['STATUS']
          end

          def status
            # STATUS=[PAID | DENIED | EXPIRED]
            case params['STATUS']
            when 'PAID'
              'Completed'
            when 'DENIED'
              'Cancelled'
            when 'EXPIRED'
              'Expired'
            else
              'Error'
            end
          end

          def acknowledge
            true
          end

          private
          def self.parse_raw_params(raw)
            params = {}
            raw.nil? or raw.split('&').each do |param|
              key, value = *param.scan( %r{^([A-Za-z0-9_.]+)\=(.*)$} ).flatten
              if !key.blank? && !value.blank?
                params[key.upcase] = CGI.unescape(value)
              end
            end
            params
          end
        end
      end
    end
  end
end
