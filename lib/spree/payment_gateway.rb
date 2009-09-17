require 'singleton'

# provides a buffer between Spree data and ActiveMerchant services
#
module Spree
  class PaymentGateway    
    include Singleton

    def authorize(checkout)
      amount = checkout.order.total
      puts "CO = #{checkout.inspect}"
      puts "CC = #{checkout.creditcard.inspect}"
      card   = create_card(checkout) # .creditcard)

      gateway = payment_gateway       
      # ActiveMerchant is configured to use cents so we need to multiply order total by 100
      response = gateway.authorize((amount * 100).to_i, card, gateway_options(checkout))      

      gateway_error(response) unless response.success?

      # create a creditcard_payment for the amount that was authorized
      spree_card = Creditcard.new checkout.creditcard      
      creditcard_payment = checkout.order.creditcard_payments.create(:amount => 0, :creditcard => spree_card)
      # create a transaction to reflect the authorization
      creditcard_payment.creditcard_txns << CreditcardTxn.new(
        :amount        => amount,
        :response_code => response.authorization,
        :txn_type      => CreditcardTxn::TxnType::AUTHORIZE
      )
    end

    def capture(authorization,order)
      gw = payment_gateway
      response = gw.capture((authorization.amount * 100).to_i, authorization.response_code, minimal_gateway_options(order))
      gateway_error(response) unless response.success?          
      creditcard_payment = authorization.creditcard_payment
      # create a transaction to reflect the capture
      creditcard_payment.creditcard_txns << CreditcardTxn.new(
        :amount => authorization.amount,
        :response_code => response.authorization,
        :txn_type => CreditcardTxn::TxnType::CAPTURE
      )
    end

    def purchase(amount)
      #combined Authorize and Capture that gets processed by the ActiveMerchant gateway as one single transaction.
      gateway = payment_gateway 
      response = gateway.purchase((amount * 100).to_i, self, gateway_options) 
      gateway_error(response) unless response.success?
      
      
      # create a creditcard_payment for the amount that was purchased
      creditcard_payment = checkout.order.creditcard_payments.create(:amount => amount, :creditcard => self)
      # create a transaction to reflect the purchase
      creditcard_payment.creditcard_txns << CreditcardTxn.new(
        :amount => amount,
        :response_code => response.authorization,
        :txn_type => CreditcardTxn::TxnType::PURCHASE
      )
    end

    def void
=begin
      authorization = find_authorization
      response = payment_gateway.void(authorization.response_code, minimal_gateway_options)
      gateway_error(response) unless response.success?
      self.creditcard_txns.create(:amount => order.total, :response_code => response.authorization, :txn_type => CreditcardTxn::TxnType::CAPTURE)
=end
    end
    
    def gateway_error(response)
      text = response.params['message'] || 
             response.params['response_reason_text'] ||
             response.message
      msg = "#{I18n.t('gateway_error')} ... #{text}"
      ActiveRecord::Base.logger.error(msg)
      raise Spree::GatewayError.new(msg)
    end

    def create_card(checkout)
      creditcard = checkout.creditcard
      creditcard[:type] = creditcard[:cc_type] = spree_cc_type
      creditcard[:first_name] = checkout.bill_address.firstname
      creditcard[:last_name]  = checkout.bill_address.lastname

      fields = %w[number month year type first_name last_name verification_value start_month start_year issue_number]
      card = ActiveMerchant::Billing::CreditCard.new(creditcard.slice(*fields))
      unless card.valid?
        # checkout.creditcard = card  # try this (to transfer validation errs) -- didn't seem to work
        raise "Invalid credit card -- #{card.errors.inspect} <br> #{card.inspect} <br> #{creditcard.inspect}" 
      end
      card
    end

    def gateway_options(checkout)
      options = {:billing_address  => generate_address_hash(checkout.bill_address), 
                 :shipping_address => generate_address_hash(checkout.shipment.address)}
      options.merge minimal_gateway_options(checkout.order)
    end    
    
    # Generates an ActiveMerchant compatible address hash from one of Spree's address objects
    def generate_address_hash(address)
      return {} if address.nil?
      {:name => address.full_name, :address1 => address.address1, :address2 => address.address2, :city => address.city,
       :state => address.state_text, :zip => address.zipcode, :country => address.country.iso, :phone => address.phone}
    end
    
    # Generates a minimal set of gateway options.  There appears to be some issues with passing in 
    # a billing address when authorizing/voiding a previously captured transaction.  So omits these 
    # options in this case since they aren't necessary.  
    def minimal_gateway_options(order)
      {:email    => order.checkout.email, 
       :customer => order.checkout.email, 
       :ip       => order.checkout.ip_address, 
       :order_id => order.number,
       :shipping => order.ship_total * 100,
       :tax      => order.tax_total * 100, 
       :subtotal => order.item_total * 100}  
    end
    
    # determine the CC type, with an exception for bogus mode
    def spree_cc_type
      return "visa" if ENV['RAILS_ENV'] == "development" and Spree::Gateway::Config[:use_bogus]
      ActiveMerchant::Billing::CreditCard.type?(number)
    end

    # instantiates the selected gateway and configures with the options stored in the database
    def payment_gateway
      return Spree::BogusGateway.new if ENV['RAILS_ENV'] == "development" and Spree::Gateway::Config[:use_bogus]

      # retrieve gateway configuration from the database
      gateway_config = GatewayConfiguration.find :first
      config_options = {}
      gateway_config.gateway_option_values.each do |option_value|
        key = option_value.gateway_option.name.to_sym
        config_options[key] = option_value.value
      end
      gateway = gateway_config.gateway.clazz.constantize.new(config_options)

      return gateway
    end  
  end
end
