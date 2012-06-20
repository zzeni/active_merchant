module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module EpayBg
        autoload :Helper, File.dirname(__FILE__) + '/epay_bg/helper.rb'
        autoload :Notification, File.dirname(__FILE__) + '/epay_bg/notification.rb'

        mattr_accessor :production_url, :test_url

        self.production_url = 'https://www.epay.bg/'
        self.test_url       = 'https://devep2.datamax.bg/ep2/epay2_demo/'

        def self.service_url
          mode = ActiveMerchant::Billing::Base.integration_mode
          case mode
          when :production
            self.production_url
          when :test
            self.test_url
          else
            raise StandardError, "Integration mode set to an invalid value: #{mode}"
          end
        end

        def self.notification(post, options = {})
          Notification.new(post, options)
        end
      end
    end
  end
end
