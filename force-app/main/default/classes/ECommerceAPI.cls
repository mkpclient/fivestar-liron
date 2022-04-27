@RestResource(urlMapping='/ecommerce/*')
global with sharing class ECommerceAPI {
/**
 You can test this class as follows in execute anonymous:

  ECommerceAPI.eCommerceRequestResource ecr = new ECommerceAPI.eCommerceRequestResource().mock();
  ecr = ECommerceAPI.processBody(JSON.serialize(ecr),'test');

**/
    
  // static final Id ECOMMERCE_PRICEBOOKID = Test.isRunningTest() ? Test.getStandardPricebookId() : '01s6T0000015dLrQAI';
  static final Id ECOMMERCE_PRICEBOOKID = Test.isRunningTest() ? Test.getStandardPricebookId() : '01s6T000001Ywcp';

  @HttpPost
  global static void postMethod() {
    RestRequest req = RestContext.request;
    String uri = req.requestURI;
    String body = req.requestBody.toString();
    RestResponse res = RestContext.response;
  	eCommerceRequestResource ecrr = processBody(body, uri);
    res.statusCode = 200;
    res.responseBody = blob.valueOf(JSON.serialize(ecrr));
  }

  public static eCommerceRequestResource processBody(String body, String uri){
    eCommerceRequestResource ecrr;
//    try {
      ecrr = (eCommerceRequestResource)JSON.deserialize(body, eCommerceRequestResource.class);
//      try {
        ecrr = saveOrders(ecrr);
//      } catch ( Exception saveException ){
//    	system.debug(saveException);      
//        for ( OpportunityProductResource opr : ecrr.OpportunitiesProducts ){
//          opr.Success = false;
//          opr.ErrorMessage = saveException.getLineNumber()+' '+saveException.getMessage();
//        }   
//        log('POST', uri, body);
//      }
//    } catch ( Exception jsonDeserializeException ){
//      ecrr = new eCommerceRequestResource();
//      ecrr.OpportunitiesProducts = new List<OpportunityProductResource>{new OpportunityProductResource()};
//      ecrr.OpportunitiesProducts[0].Success = false;
//      ecrr.OpportunitiesProducts[0].ErrorMessage = jsonDeserializeException.getLineNumber()+' '+jsonDeserializeException.getMessage();
//      log('POST', uri, jsonDeserializeException.getMessage());
//    }
    log('POST', uri, JSON.serialize(ecrr));
    return ecrr;
  }

  static Map<Id,Opportunity> queryOpportunityMap(Set<Id> opportunityIds){
    return new Map<Id,Opportunity>([
      SELECT Id, AccountId, Core_Market__c, Market_Project__c, (
        SELECT Id, Product2Id, PricebookEntryId
        FROM OpportunityLineItems
      )
      FROM Opportunity
      WHERE Id IN :opportunityIds
    ]);
  }

  static Map<Id,Contact> queryContactMap(Set<Id> contactIds){
    return new Map<Id,Contact>([
      SELECT Id, FirstName, LastName, MX_Customer_Id__c, MailingStreet, MailingCity, MailingState,
      MailingPostalCode, MailingCountry, (
        SELECT Id, Card_Type__c, Last_4_Digits_of_Card__c, ExternalId__c
        FROM Payment_Methods__r
        WHERE Inactive__c = FALSE 
      )
      FROM Contact
      WHERE Id IN :contactIds
    ]);
  }

  static eCommerceRequestResource saveOrders(eCommerceRequestResource e){
    Map<Id,Contact> contactMap = new Map<Id,Contact>();
    contactMap.put(e.BillingAddress.ContactId,null);
    contactMap = queryContactMap(contactMap.keySet());

    Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();
    for ( OpportunityProductResource opr : e.OpportunitiesProducts ){
      opportunityMap.put(opr.OpportunityId, null);
    }
    opportunityMap = queryOpportunityMap(opportunityMap.keySet());

    List<SalesOrder__c> salesOrders = new List<SalesOrder__c>();
    List<SalesOrderProductLine__c> sopls = new List<SalesOrderProductLine__c>();
    List<Payment_Method__c> paymentMethods = new List<Payment_Method__c>();
    List<Payment__c> payments = new List<Payment__c>();
    for ( OpportunityProductResource opr : e.OpportunitiesProducts ){
      if ( !contactMap.containsKey(e.BillingAddress.ContactId) ){
        opr.Success = false;
        opr.ErrorMessage = 'Contact '+e.BillingAddress.ContactId+' not found';
      }
      else if ( !opportunityMap.containsKey(opr.OpportunityId)  ){
        opr.Success = false;
        opr.ErrorMessage = 'Opportunity '+opr.OpportunityId+' not found';
      } else {
          Contact existingContact = contactMap.get(e.BillingAddress.ContactId);
          Opportunity existingOpportunity = opportunityMap.get(opr.OpportunityId);
          SalesOrder__c so = saveSalesOrder(existingOpportunity, e);
		      salesOrders.add(so);
            
          Order_Line_Recipient__c olr = new Order_Line_Recipient__c();
          olr.Order__c = so.Id;
          olr.Recipient__c = existingContact.Id;

          Decimal totalAmount = 0;
          for ( ProductLineResource plr : opr.ProductLines ){
            totalAmount += plr.TotalAmount;
            SalesOrderProductLine__c sopl = new SalesOrderProductLine__c();
            sopl.SalesOrder__r = so;
            sopl.Quantity__c = plr.Quantity;
            sopl.SalesPrice__c = plr.TotalAmount / plr.Quantity;
            sopl.Actual_Selling_Price__c = sopl.SalesPrice__c;
            sopl.Product__c = plr.ProductId;
            sopls.add(sopl);     
          }
          Zealynx.CustomerResource zealynxCustomer = saveZealynxCustomer(existingContact, e.BillingAddress);
          Payment_Method__c paymentMethod;
          for ( Payment_Method__c existingPaymentMethod : existingContact.Payment_Methods__r ){
            if ( 
              existingPaymentMethod.Card_Type__c == e.CreditCard.CardType &&
              existingPaymentMethod.Last_4_Digits_of_Card__c == e.CreditCard.CardNumber.right(4)
            ){
              paymentMethod = existingPaymentMethod;
              break;
            }
          }
          paymentMethod = saveZealynxPaymentMethod(existingContact, paymentMethod, e.CreditCard);
          paymentMethods.add(paymentMethod);

          Payment__c payment = saveZealynxPayment(existingContact, paymentMethod, totalAmount);
          payment.Sales_Order__r = so;
          payment.Ship_To_City__c = e.ShippingAddress.City;
          payment.Status__c = 'Completed';
          payment.Payment_Type__c = 'Credit Card';
          payments.add(payment);
          
          opr.Success = true;
      }
    }
    insert salesOrders;
    
    // insert olr;
    for ( SalesOrderProductLine__c sopl : sopls ){
      sopl.SalesOrder__c = sopl.SalesOrder__r.Id;
      sopl.SalesOrder__r = null;
    }
    insert sopls;

    for(SalesOrder__c so : salesOrders) {
      so.Status_Picklist__c = 'Approved';
    }
    update salesOrders;

    if ( contactMap.size() > 0 ){
      update contactMap.values();
    }
    upsert paymentMethods;
    for ( Payment__c p : payments ){
      p.Payment_Method__c = p.Payment_Method__r.Id;
      p.Payment_Method__r = null;
      p.Sales_Order__c = p.Sales_Order__r.Id;
      p.Sales_Order__r = null;
    }
    insert payments;

    for(Integer i = 0; i < e.OpportunitiesProducts.size(); i++){
      e.OpportunitiesProducts[i].OrderId = salesOrders[i].Id;
    }
    return e;
  }

  static SalesOrder__c saveSalesOrder(Opportunity existingOpportunity, eCommerceRequestResource e){
    SalesOrder__c so = new SalesOrder__c();
    so.Account__c = existingOpportunity.AccountId;
    so.Opportunity__c = existingOpportunity.Id;
    so.ContactBilling__c = e.BillingAddress.ContactId;
    so.ContactBuying__c = e.BillingAddress.ContactId;
    so.ContactShipping__c = e.ShippingAddress.ContactId;
    so.Market__c = existingOpportunity.Market_Project__c;
    so.OrderDate__c = System.Today();
    so.Price_Book__c = ECOMMERCE_PRICEBOOKID;
    return so;
  }

  static Zealynx.CustomerResource saveZealynxCustomer(Contact existingContact, AddressResource billingAddress){
    Zealynx.CustomerResource zealynxCustomer = new Zealynx.CustomerResource();
    if ( String.isNotBlank(existingContact.MX_Customer_Id__c) ){
      zealynxCustomer.id = Long.valueOf(existingContact.MX_Customer_Id__c);
    } else {
      zealynxCustomer.name = billingAddress.FirstName+' '+billingAddress.LastName;
      zealynxCustomer.FirstName = billingAddress.FirstName;
      zealynxCustomer.LastName = billingAddress.LastName;
      zealynxCustomer.REPLACE_number = existingContact.Id;
      zealynxCustomer.address1 = existingContact.MailingStreet;
      //zealynxCustomer.address2 {get; set;} 
      zealynxCustomer.city = existingContact.MailingCity;
      zealynxCustomer.state = existingContact.MailingState;
      zealynxCustomer.zip = existingContact.MailingPostalCode;
      zealynxCustomer.customerType = 'Person';
      zealynxCustomer = zealynxCustomer.save();
      if ( zealynxCustomer.id != null ){
        existingContact.MX_Customer_Id__c = String.valueOf(zealynxCustomer.id);
      }
    }
    return zealynxCustomer;
  }

  static Payment_Method__c saveZealynxPaymentMethod(Contact existingContact, Payment_Method__c paymentMethod, CreditCardResource creditCard){
    if ( paymentMethod == null ){
      paymentMethod = new Payment_Method__c();
      paymentMethod.Contact__c = existingContact.Id;
      paymentMethod.Card_Type__c = creditCard.CardType;
      paymentMethod.Payment_Processor__c = 'MX Merchant';

      Zealynx.CreditCardResource zealynxCreditCardResource = new Zealynx.CreditCardResource();
      zealynxCreditCardResource.customerId = Long.valueOf(existingContact.MX_Customer_Id__c);
      zealynxCreditCardResource.expiryMonth = ''+creditCard.ExpirationMonth;
      zealynxCreditCardResource.expiryYear = ''+creditCard.ExpirationYear;
      zealynxCreditCardResource.cvv = creditCard.CVC;
      zealynxCreditCardResource.REPLACE_number = creditCard.CardNumber;
      zealynxCreditCardResource.name = existingContact.FirstName+' '+existingContact.LastName;
      zealynxCreditCardResource.alias = zealynxCreditCardResource.name + ' '+ creditCard.CardType;
      zealynxCreditCardResource = zealynxCreditCardResource.save();
      if ( zealynxCreditCardResource.id != null ){ 
        paymentMethod.ExternalId__c = String.valueOf(zealynxCreditCardResource.id);
      }
    }
    return paymentMethod;
  }

  static Payment__c saveZealynxPayment(Contact existingContact, Payment_Method__c paymentMethod, Decimal totalAmount){
    Zealynx.PaymentResource zealynxPayment = new Zealynx.PaymentResource();
    zealynxPayment.amount = totalAmount;
    zealynxPayment.paymentType = 'Sale';
    zealynxPayment.tenderType = 'Card';
    zealynxPayment.tenderType = 'WEB';
    zealynxPayment.cardPresent = false;
    zealynxPayment.authOnly = false;
    zealynxPayment.isSettleFunds = true;
    zealynxPayment.customerId = Long.valueOf(existingContact.MX_Customer_Id__c);
    zealynxPayment.cardAccountToken = paymentMethod.ExternalId__c;
    zealynxPayment = zealynxPayment.save();

    Payment__c payment = new Payment__c();
    // payment.Account__c = 
    payment.Contact__c = paymentMethod.Contact__c;
    payment.Amount__c = totalAmount;
    payment.MX_Payment_Id__c = String.valueOf(zealynxPayment.id);
    payment.Date__c = system.today();
    payment.Payment_Method__r = paymentMethod;
    payment.Payment_Processor__c = 'MX Merchant';
    return payment;
  }

  static void log(String method, String requestURI, String requestBody){
    try {
      Task t = new Task();
      t.ActivityDate = system.today();
      t.Subject = method+':'+requestURI;
      t.Description = requestBody;
      insert t;
    } catch ( Exception e){
      system.debug(e);
    }
  }

  public class eCommerceRequestResource {
    List<OpportunityProductResource> OpportunitiesProducts;
  	AddressResource ShippingAddress;
	  AddressResource BillingAddress;
    CreditCardResource CreditCard;

    public eCommerceRequestResource mock(){
      OpportunitiesProducts = new List<OpportunityProductResource>();
      OpportunitiesProducts.add(new OpportunityProductResource().mock('0068F000002qK9C'));
      OpportunitiesProducts.add(new OpportunityProductResource().mock('0068F000002qK9C'));
      OpportunitiesProducts[1].ProductLines[0].ProductId = '01t6T000006BZPwQAO';
      OpportunitiesProducts[1].ProductLines[0].Quantity = 3;
      OpportunitiesProducts[1].ProductLines[0].TotalAmount = 207;
      ShippingAddress = new AddressResource().mock('0038F000007RlXD');
      BillingAddress = new AddressResource().mock('0038F000007RlXD');
      CreditCard = new CreditCardResource().mock();
      return this;
    }
  }
  class OpportunityProductResource {
    String OpportunityId;
    String OrderId;
    Boolean Success;
    String ErrorMessage;
    List<ProductLineResource> ProductLines;

    public OpportunityProductResource mock(){
      return mock('0062C00000H0Ib8QAF');
    }
    public OpportunityProductResource mock(Id opportunityId){
      this.OpportunityId = opportunityId;
      ProductLines = new List<ProductLineResource>{new ProductLineResource().mock()};
      return this;
    }
  } 
  class ProductLineResource {
    String ProductId;
    Decimal Quantity;
    Decimal TotalAmount;

    public ProductLineResource mock(){
      return mock('01t6T000006BZPmQAO');
    }
    public ProductLineResource mock(Id productId){
      this.ProductId = productId;
      Quantity = 2;
      TotalAmount = 90;
      return this;
    }
  }

  public class AddressResource {
    Id ContactId;
    String FirstName;
    String LastName;
    String StreetAddress;
    String City;
    String State;
    String Zip;
    String Country;
    String CompanyName;
    String PhoneNumber;
    String Email;

    public AddressResource mock(Id contactId){
      this.ContactId = contactId;
      FirstName = 'FnameNewCustomer';
      LastName = 'LnameNewCustomer';
      StreetAddress = '123 any st addr2';
      City = 'Seattle';
      State = 'WA';
      Zip = '12345';
      CompanyName = 'ACME Global, Inc.';
      PhoneNumber = '8005551212';
      Email = 'victoriasample@fivestarprofessional.com';
      return this;
    }
  }

  public class CreditCardResource {
    String FirstName;
    String LastName;
    String CardType;
    String CardNumber;        
    Integer ExpirationMonth;        
    Integer ExpirationYear;        
    String CVC;

    public CreditCardResource mock(){
      FirstName = 'asdf';
      LastName = 'asdf';
      CardType = 'Visa';
      CardNumber = '4111111111111111';
      ExpirationMonth = 1;
      ExpirationYear = 22;
      CVC = '123';
      return this;
    }
  }

  public static String sampleRequest(){
 
    return null;
  }
}