require 'test_helper'
require 'base64'
require 'openssl'
require 'date'

class EpayBgHelperTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @helper = EpayBg::Helper.new(
      'order-500',
      'epay@example.com',
      :amount      => 500,
      :currency    => 'BGN',
      :credential2 => 'secret'
    )
  end

  def test_basic_helper_fields
    assert_field 'INVOICE'      , 'order-500'
    assert_field 'MIN_OR_EMAIL' , 'epay@example.com'
    assert_field 'AMOUNT'       , '500'
    assert_field 'CURRENCY'     , 'BGN'
    assert_field 'PAGE'         , 'paylogin'
  end

  def test_no_credentials
    assert_raise(ArgumentError) do
      EpayBg::Helper.new('order-500','1234567')
    end
  end

  def test_form_fields
    fields = @helper.form_fields
    assert_equal 'paylogin', fields['PAGE']

    checksum = OpenSSL::HMAC.hexdigest('sha1', 'secret', fields['ENCODED']).upcase
    assert_equal checksum, fields['CHECKSUM']

    assert_match /^[A-Za-z0-9\+\/]+=*$/, fields['ENCODED']
    decoded = Hash[*Base64.decode64(fields['ENCODED']).split(/\n|=/)]
    assert_false decoded.has_key?('MIN')
    assert_equal 'epay@example.com' , decoded['EMAIL']
    assert_equal '500'              , decoded['AMOUNT']
    assert_equal 'order-500'        , decoded['INVOICE']
    assert_equal '01.08.2020'       , decoded['EXP_TIME']
    assert_false decoded.has_key?('DESCR')
    assert_false decoded.has_key?('ENCODING')

    assert_false fields.has_key?('URL_OK')
    assert_false fields.has_key?('URL_CANCEL')
  end

  def test_form_fields_optional_fields
    @helper = EpayBg::Helper.new(
      'order-500',
      '1234567',
      :credential2 => 'secret'
    )
    @helper.return_url 'ok.example.com'
    @helper.cancel_return_url 'cancel.example.com'
    @helper.description 'descr'
    @helper.expiration_date Time.new(2001,2,3,4,5,6)
    fields = @helper.form_fields

    assert_equal 'ok.example.com', fields['URL_OK']
    assert_equal 'cancel.example.com', fields['URL_CANCEL']

    decoded = Hash[*Base64.decode64(fields['ENCODED']).split(/\n|=/)]
    assert_false decoded.has_key?('EMAIL')
    assert_equal '1234567'             , decoded['MIN']
    assert_equal '03.02.2001 04:05:06' , decoded['EXP_TIME']
    assert_equal 'descr'               , decoded['DESCR']
    assert_equal 'utf-8'               , decoded['ENCODING']
  end
end
