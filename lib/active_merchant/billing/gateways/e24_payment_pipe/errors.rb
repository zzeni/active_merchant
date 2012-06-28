module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module E24PaymentPipe
      class SecureSettingsError < StandardError;  end
      class ParserError < StandardError;  end
      class MessageError < StandardError;  end
      class TransactionError < StandardError;  end
      class PaymentError < StandardError;  end
    end
  end
end
