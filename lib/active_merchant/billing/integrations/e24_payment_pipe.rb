module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module E24PaymentPipe
        autoload :Notification, File.dirname(__FILE__) + '/e24_payment_pipe/notification.rb'

        mattr_accessor :service_url

        def self.notification(post, options = {})
          Notification.new(post, options)
        end
      end
    end
  end
end

