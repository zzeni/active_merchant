require 'test_helper'
require 'openssl'

class EpayBgNotificationTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @epay_bg = EpayBg::Notification.new(item_data)
  end

  def test_accessors
    assert @epay_bg.complete?
    assert_equal 'Completed' , @epay_bg.status
    assert_equal '111111'    , @epay_bg.transaction_id
    assert_equal '123456'    , @epay_bg.item_id
    assert_equal 'BBBBBB'    , @epay_bg.authorization_code
    assert_equal '10.11'     , @epay_bg.gross
    assert_equal '321'       , @epay_bg.card_bin
    assert_equal Time.new(2001,2,3,4,5,6), @epay_bg.received_at
    assert_equal 'INVOICE=123456:STATUS=OK', @epay_bg.item_response('OK')
  end

  def test_compositions
    assert_equal Money.new(1011, 'BGN'), @epay_bg.amount
  end

  def test_canceled_item
    @canceled = EpayBg::Notification.new(canceled_item_data)
    assert_equal 'Cancelled', @canceled.status
  end

  def test_bulk_acknowledged
    assert EpayBg::Notification.bulk_acknowledged?(raw_bulk_data, 'secret')
  end

  def test_bulk_acknowledged_wrong_secret
    assert_false EpayBg::Notification.bulk_acknowledged?(raw_bulk_data, 'wrong_secret')
  end

  def test_get_bulk
    bulk = EpayBg::Notification.get_bulk(raw_bulk_data)
    assert_equal 3, bulk.count
    assert bulk.first.instance_of? EpayBg::Notification
    assert_equal '123456', bulk.first.item_id
  end

  def test_respond_to_acknowledge
    assert @epay_bg.respond_to?(:acknowledge)
  end

  private
  def item_data
    'INVOICE=123456:STATUS=PAID:PAY_TIME=20010203040506:STAN=111111:BCODE=BBBBBB:AMOUNT=10.11:BIN=321'.gsub(':', '&')
  end

  def canceled_item_data
    'INVOICE=123456:STATUS=DENIED'.gsub(':', '&')
  end

  def raw_bulk_data
    data = [
      'INVOICE=123456:STATUS=PAID:PAY_TIME=20010203040506:STAN=111111:BCODE=BBBBBB:AMOUNT=10.11:BIN=321',
      'INVOICE=123457:STATUS=DENIED',
      'INVOICE=123458:STATUS=EXPIRED'
    ].join "\n"
    encoded = Base64.encode64(data).gsub("\n", '')
    checksum = OpenSSL::HMAC.hexdigest('sha1', 'secret', encoded)
    "ENCODED=#{encoded}&CHECKSUM=#{checksum}"
  end
end
