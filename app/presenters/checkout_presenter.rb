class CheckoutPresenter < ActivePresenter::Base
  presents :creditcard, {:bill_address => Address}, {:ship_address => Address} 

  include ActionView::Helpers::NumberHelper # Needed for JS usable rate information 
  
  alias_method :old_initialize, :initialize 
  attr_accessor :order
  attr_accessor :shipping_method
  attr_accessor :order_hash   
  attr_accessor :final_answer
  attr_accessor :shipping_instructions
  
  def initialize(args = {})               
    old_initialize(args)
    default_country = Country.find_by_id Spree::Config[:default_country_id]
    bill_address.country ||= default_country
    ship_address.country ||= default_country    
    # credit card needs to use some bill_address attributes
    creditcard.address = bill_address  
    creditcard.first_name = bill_address.firstname
    creditcard.last_name = bill_address.lastname   
    self.order_hash = {}   
  end 
  
  def save           
    # TODO: js should give validity, so this line should go eventually
    raise t('checkout_had_errors') unless final_answer.blank? or valid?

    saved = nil

    # save and fix the final order details
    ActiveRecord::Base.transaction do
      # clear existing addresses, eventually this won't be necessary (we'll have an address book)
      order.user.addresses.clear
      order.user.addresses << bill_address.clone
      
      # clear existing shipments (no orphans please)                             
      order.shipments.clear
      order.shipments.create(:address => ship_address, :shipping_method => shipping_method)
      order.special_instructions = shipping_instructions
      
      order.ship_amount = order.shipment.shipping_method.calculate_shipping(order.shipment) if order.shipment and order.shipment.shipping_method
      order.tax_amount = order.calculate_tax
      order.save!
    end

    # populate the order hash from the information just set
    order_hash[:ship_amount] = number_to_currency(order.ship_amount)
    order_hash[:tax_amount]  = number_to_currency(order.tax_amount)
    order_hash[:order_total] = number_to_currency(order.total)
    order_hash[:ship_method] = order.shipment.shipping_method.name if order.shipment and order.shipment.shipping_method
 
    # do the CC stuff ONLY IF it is definitely the final step
    unless final_answer.blank?
      ActiveRecord::Base.transaction do
        # authorize the credit card and then save 
        # (authorize first before number is cleared for security purposes)
        # idea - shift the TX to here.
        # also do the error decoding here
        creditcard.order = order
        result = creditcard.authorize(order.total)

        saved = result
        creditcard.save 	
          # expect all details to go through - since validation checked in JS and above
          # PCC: this is superfluous?
          # PCC: cc is definitely saved (and masked) at this point, where from???

        if result.is_a?(CreditcardTxn)
          order.complete
        end 
      end
    end      
    # still nil here means we just want to report the new partial info via JS
    saved  
  end
end
