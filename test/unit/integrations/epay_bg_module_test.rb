require 'test_helper'

class EPayBgModuleTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def test_notification_method
    assert_instance_of EpayBg::Notification, EpayBg.notification('name=cody', :credential2 => 'secret')
  end

  def test_test_mode
    ActiveMerchant::Billing::Base.integration_mode = :test
    assert_equal 'https://devep2.datamax.bg/ep2/epay2_demo/', EpayBg.service_url
  end

  def test_production_mode
    ActiveMerchant::Billing::Base.integration_mode = :production
    assert_equal 'https://www.epay.bg/', EpayBg.service_url
  end

  def test_invalid_mode
    ActiveMerchant::Billing::Base.integration_mode = :coolmode
    assert_raise(StandardError){ EpayBg.service_url }
  end
end
