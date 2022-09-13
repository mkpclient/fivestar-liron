@RestResource(urlMapping='/ecommerce/*')
global with sharing class ECommerceAPI {
  /**
 You can test this class as follows in execute anonymous:

  ECommerceAPI.eCommerceRequestResource ecr = new ECommerceAPI.eCommerceRequestResource().mock();
  ecr = ECommerceAPI.processBody(JSON.serialize(ecr),'test');

**/

  // static final Id ECOMMERCE_PRICEBOOKID = Test.isRunningTest() ? Test.getStandardPricebookId() : '01s6T0000015dLrQAI';
  static final Id ECOMMERCE_PRICEBOOKID = Test.isRunningTest()
    ? Test.getStandardPricebookId()
    : '01s6T0000015dLrQAI';

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

  public static eCommerceRequestResource processBody(String body, String uri) {
    eCommerceRequestResource ecrr;
    //    try {
    ecrr = (eCommerceRequestResource) JSON.deserialize(
      body,
      eCommerceRequestResource.class
    );
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

  static Map<Id, Opportunity> queryOpportunityMap(Set<Id> opportunityIds) {
    return new Map<Id, Opportunity>(
      [
        SELECT
          Id,
          AccountId,
          Core_Market__c,
          Market_Project__c,
          (SELECT Id, Product2Id, PricebookEntryId FROM OpportunityLineItems)
        FROM Opportunity
        WHERE Id IN :opportunityIds
      ]
    );
  }

  static Map<Id, Contact> queryContactMap(Set<Id> contactIds) {
    return new Map<Id, Contact>(
      [
        SELECT
          Id,
          FirstName,
          LastName,
          MX_Customer_Id__c,
          MailingStreet,
          MailingCity,
          MailingState,
          MailingPostalCode,
          MailingCountry,
          (
            SELECT Id, Card_Type__c, Last_4_Digits_of_Card__c, ExternalId__c, Merchant_Token__c
            FROM Payment_Methods__r
            WHERE Inactive__c = FALSE
          )
        FROM Contact
        WHERE Id IN :contactIds
      ]
    );
  }

  static eCommerceRequestResource saveOrders(eCommerceRequestResource e) {
    Map<Id, Contact> contactMap = new Map<Id, Contact>();
    contactMap.put(e.BillingAddress.ContactId, null);
    contactMap = queryContactMap(contactMap.keySet());

    Map<Id, Product2> productMap = new Map<Id, Product2>();
    for (OpportunityProductResource opr : e.OpportunitiesProducts) {
      for (ProductLineResource plr : opr.ProductLines) {
        productMap.put(plr.ProductId, null);
      }
    }
    productMap = queryProductMap(productMap.keySet());

    Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
    for (OpportunityProductResource opr : e.OpportunitiesProducts) {
      opportunityMap.put(opr.OpportunityId, null);
    }
    opportunityMap = queryOpportunityMap(opportunityMap.keySet());

    List<SalesOrder__c> salesOrders = new List<SalesOrder__c>();
    List<SalesOrderProductLine__c> sopls = new List<SalesOrderProductLine__c>();
    Map<String, Payment_Method__c> paymentMethods = new Map<String, Payment_Method__c>();
    List<Payment__c> payments = new List<Payment__c>();
    for (OpportunityProductResource opr : e.OpportunitiesProducts) {
      if (!contactMap.containsKey(e.BillingAddress.ContactId)) {
        opr.Success = false;
        opr.ErrorMessage =
          'Contact ' +
          e.BillingAddress.ContactId +
          ' not found';
      } else if (!opportunityMap.containsKey(opr.OpportunityId)) {
        opr.Success = false;
        opr.ErrorMessage = 'Opportunity ' + opr.OpportunityId + ' not found';
      } else {
        Contact existingContact = contactMap.get(e.BillingAddress.ContactId);
        Opportunity existingOpportunity = opportunityMap.get(opr.OpportunityId);
        SalesOrder__c so = saveSalesOrder(existingOpportunity, e);
        salesOrders.add(so);

        Order_Line_Recipient__c olr = new Order_Line_Recipient__c();
        olr.Order__c = so.Id;
        olr.Recipient__c = existingContact.Id;

        Decimal totalAmount = 0;
        for (ProductLineResource plr : opr.ProductLines) {
          totalAmount += plr.TotalAmount;
          SalesOrderProductLine__c sopl = new SalesOrderProductLine__c();
          sopl.SalesOrder__r = so;
          sopl.Quantity__c = plr.Quantity;
          sopl.SalesPrice__c = plr.TotalAmount / plr.Quantity;
          sopl.Actual_Selling_Price__c = sopl.SalesPrice__c;
          sopl.Product__c = plr.ProductId;

          if (
            productMap.containsKey(plr.ProductId) &&
            productMap.get(plr.ProductId).PricebookEntries != null &&
            productMap.get(plr.ProductId).PricebookEntries.size() > 0
          ) {
            sopl.ListPrice__c = productMap.get(plr.ProductId)
              .PricebookEntries[0]
              .UnitPrice;
          }

          sopls.add(sopl);
        }
        Zealynx.CustomerResource zealynxCustomer = saveZealynxCustomer(
          existingContact,
          e.BillingAddress
        );

        if (zealynxCustomer.id != null && String.isEmpty(existingContact.MX_Customer_Id__c)) {
          existingContact.MX_Customer_Id__c = String.valueOf(zealynxCustomer.id);
          contactMap.put(existingContact.Id, existingContact);
        }

        Payment_Method__c paymentMethod;
        for (
          Payment_Method__c existingPaymentMethod : existingContact.Payment_Methods__r
        ) {
          if (
            existingPaymentMethod.Card_Type__c == e.CreditCard.CardType &&
            existingPaymentMethod.Last_4_Digits_of_Card__c ==
            e.CreditCard.CardNumber.right(4)
          ) {
            paymentMethod = existingPaymentMethod;
            break;
          }
        }
        paymentMethod = saveZealynxPaymentMethod(
          existingContact,
          paymentMethod,
          e.CreditCard
        );
        paymentMethods.put(paymentMethod.ExternalId__c, paymentMethod);

        Payment__c payment = saveZealynxPayment(
          existingContact,
          paymentMethod,
          totalAmount
        );
        payment.Sales_Order__r = so;
        payment.Account__c = so.Account__c;
        payment.Ship_To_City__c = e.ShippingAddress.City;
        payment.Payment_Type__c = 'Credit Card';
        payments.add(payment);

        opr.Success = true;
      }
    }
    insert salesOrders;

    // insert olr;
    for (SalesOrderProductLine__c sopl : sopls) {
      sopl.SalesOrder__c = sopl.SalesOrder__r.Id;
      sopl.SalesOrder__r = null;
    }
    insert sopls;

    for (SalesOrder__c so : salesOrders) {
      so.Status_Picklist__c = 'Approved';
    }
    update salesOrders;

    if (contactMap.size() > 0) {
      update contactMap.values();
    }

    upsert paymentMethods.values() ExternalId__c;

    for (Payment__c p : payments) {
      p.Payment_Method__c = p.Payment_Method__r.Id;
      p.Payment_Method__r = null;
      p.Sales_Order__c = p.Sales_Order__r.Id;
      p.Sales_Order__r = null;
    }
    insert payments;

    for (Integer i = 0; i < e.OpportunitiesProducts.size(); i++) {
      e.OpportunitiesProducts[i].OrderId = salesOrders[i].Id;
    }
    return e;
  }

  static SalesOrder__c saveSalesOrder(
    Opportunity existingOpportunity,
    eCommerceRequestResource e
  ) {
    SalesOrder__c so = new SalesOrder__c();
    so.Account__c = existingOpportunity.AccountId;
    so.Opportunity__c = existingOpportunity.Id;
    so.ContactBilling__c = e.BillingAddress.ContactId;
    so.ContactBuying__c = e.BillingAddress.ContactId;
    so.ContactShipping__c = e.ShippingAddress.ContactId;
    so.Market__c = existingOpportunity.Market_Project__c;
    so.OrderDate__c = System.Today();
    so.Price_Book__c = ECOMMERCE_PRICEBOOKID;
    so.BillToCity__c = e.BillingAddress.City;
    so.BillToCountry__c = e.BillingAddress.Country;
    so.BillToName__c = e.BillingAddress.FirstName + ' ' + e.BillingAddress.LastName;
    so.BillToStateProvince__c = e.BillingAddress.State;
    so.BillToStreetLong__c = e.BillingAddress.StreetAddress;
    so.BillToZipPostalCode__c = e.BillingAddress.Zip;
    so.ShipToCity__c = e.ShippingAddress.City;
    so.ShipToCountry__c = e.ShippingAddress.Country;
    so.ShipToName__c = e.ShippingAddress.FirstName + ' ' + e.ShippingAddress.LastName;
    so.ShipToStateProvince__c = e.ShippingAddress.State;
    so.ShipToStreetLong__c = e.ShippingAddress.StreetAddress;
    so.ShipToZipPostalCode__c = e.ShippingAddress.Zip;
    return so;
  }

  static Zealynx.CustomerResource saveZealynxCustomer(
    Contact existingContact,
    AddressResource billingAddress
  ) {
    Zealynx.CustomerResource zealynxCustomer = new Zealynx.CustomerResource();
    if (String.isNotBlank(existingContact.MX_Customer_Id__c)) {
      zealynxCustomer.id = Long.valueOf(existingContact.MX_Customer_Id__c);
    } else {
      zealynxCustomer.name =
        billingAddress.FirstName +
        ' ' +
        billingAddress.LastName;
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
    }
    return zealynxCustomer;
  }

  static Payment_Method__c saveZealynxPaymentMethod(
    Contact existingContact,
    Payment_Method__c paymentMethod,
    CreditCardResource creditCard
  ) {
    if (paymentMethod == null) {
      paymentMethod = new Payment_Method__c();
      paymentMethod.Contact__c = existingContact.Id;
      paymentMethod.Card_Type__c = creditCard.CardType;
      paymentMethod.Payment_Processor__c = 'MX Merchant';
      paymentMethod.Last_4_Digits_of_Card__c = '' + creditCard.CardNumber.right(4);
      paymentMethod.Billing_Street__c = existingContact.MailingStreet;
      paymentMethod.Billing_City__c = existingContact.MailingCity;
      paymentMethod.Billing_State__c = existingContact.MailingState;
      paymentMethod.Billing_Postal_Code__c = existingContact.MailingPostalCode;
      paymentMethod.Billing_Country__c = existingContact.MailingCountry;
      paymentMethod.Expiration_Date__c = Date.newInstance(Integer.valueOf('20' + creditCard.ExpirationYear), Integer.valueOf(creditCard.ExpirationMonth), Date.daysInMonth(Integer.valueOf('20' + creditCard.ExpirationYear), Integer.valueOf(creditCard.ExpirationMonth)));


      Zealynx.CreditCardResource zealynxCreditCardResource = new Zealynx.CreditCardResource();
      zealynxCreditCardResource.customerId = Long.valueOf(
        existingContact.MX_Customer_Id__c
      );
      zealynxCreditCardResource.expiryMonth = '' + creditCard.ExpirationMonth;
      zealynxCreditCardResource.expiryYear = '' + creditCard.ExpirationYear;
      zealynxCreditCardResource.cvv = creditCard.CVC;
      zealynxCreditCardResource.avsStreet = existingContact.MailingStreet;
      zealynxCreditCardResource.avsZip = existingContact.MailingPostalCode;
      zealynxCreditCardResource.REPLACE_number = creditCard.CardNumber;
      zealynxCreditCardResource.name =
        existingContact.FirstName +
        ' ' +
        existingContact.LastName;
      zealynxCreditCardResource.alias =
        zealynxCreditCardResource.name +
        ' ' +
        creditCard.CardType;
      zealynxCreditCardResource = zealynxCreditCardResource.save();
      if (zealynxCreditCardResource.id != null) {
        paymentMethod.ExternalId__c = String.valueOf(
          zealynxCreditCardResource.id
        );
      if(zealynxCreditCardResource.token != null) {
        paymentMethod.Merchant_Token__c = zealynxCreditCardResource.token;
      }
      }
    }
    return paymentMethod;
  }

  static Payment__c saveZealynxPayment(
    Contact existingContact,
    Payment_Method__c paymentMethod,
    Decimal totalAmount
  ) {
    Zealynx.PaymentResource zealynxPayment = new Zealynx.PaymentResource();
    zealynxPayment.amount = totalAmount;
    zealynxPayment.paymentType = 'Sale';
    zealynxPayment.tenderType = 'Card';
    zealynxPayment.entryClass = 'WEB';
    zealynxPayment.cardPresent = false;
    zealynxPayment.authOnly = false;
    zealynxPayment.isSettleFunds = true;
    zealynxPayment.customerId = Long.valueOf(existingContact.MX_Customer_Id__c);
    zealynxPayment.cardAccountToken = paymentMethod.Merchant_Token__c;
    zealynxPayment = zealynxPayment.save();

    Payment__c payment = new Payment__c();
    // payment.Account__c =
    payment.Contact__c = existingContact.Id;
    payment.Billing_Name__c = existingContact.FirstName + ' ' + existingContact.LastName;

    payment.Amount__c = totalAmount;
    if(zealynxPayment.status == 'Approved') {
      payment.Status__c = 'Completed';
    } else if(zealynxPayment.status == 'Declined') {
      payment.Status__c = 'Declined';
    } else {
      payment.Status__c = 'Error';
    }
    if(zealynxPayment.id != null) {
      payment.MX_Payment_Id__c = String.valueOf(zealynxPayment.id);
    }
    if(zealynxPayment.reference != null) {
      payment.Transaction_Id__c = String.valueOf(zealynxPayment.reference);
    }
    if(zealynxPayment.paymentToken != null) {
      payment.Payment_Token__c = zealynxPayment.paymentToken;
    }
    if(zealynxPayment.authCode != null) {
      payment.Authorization_Id__c = zealynxPayment.authCode;
    }
    payment.Date__c = system.today();
    payment.Payment_Method__r = paymentMethod;
    payment.Payment_Processor__c = 'MX Merchant';
    return payment;
  }

  static void log(String method, String requestURI, String requestBody) {
    try {
      Task t = new Task();
      t.ActivityDate = system.today();
      t.Subject = method + ':' + requestURI;
      t.Description = requestBody;
      insert t;
    } catch (Exception e) {
      system.debug(e);
    }
  }

  public class eCommerceRequestResource {
    List<OpportunityProductResource> OpportunitiesProducts;
    AddressResource ShippingAddress;
    AddressResource BillingAddress;
    CreditCardResource CreditCard;

    public eCommerceRequestResource mock() {
      OpportunitiesProducts = new List<OpportunityProductResource>();
      OpportunitiesProducts.add(
        new OpportunityProductResource().mock('0066T000015FDavQAG')
      );
      OpportunitiesProducts.add(
        new OpportunityProductResource().mock('0066T000015FDavQAG')
      );
      OpportunitiesProducts[1].ProductLines[0].ProductId = '01t6T000006BZPwQAO';
      OpportunitiesProducts[1].ProductLines[0].Quantity = 3;
      OpportunitiesProducts[1].ProductLines[0].TotalAmount = 207;
      ShippingAddress = new AddressResource().mock('0036T000044HGItQAO');
      BillingAddress = new AddressResource().mock('0036T000044HGItQAO');
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

    public OpportunityProductResource mock() {
      return mock('0062C00000H0Ib8QAF');
    }
    public OpportunityProductResource mock(Id opportunityId) {
      this.OpportunityId = opportunityId;
      ProductLines = new List<ProductLineResource>{
        new ProductLineResource().mock()
      };
      return this;
    }
  }
  class ProductLineResource {
    String ProductId;
    Decimal Quantity;
    Decimal TotalAmount;

    public ProductLineResource mock() {
      return mock('01t6T000006BZPmQAO');
    }
    public ProductLineResource mock(Id productId) {
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

    public AddressResource mock(Id contactId) {
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

    public CreditCardResource mock() {
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

  public static String sampleRequest() {
    return null;
  }

  public static Map<Id, Product2> queryProductMap(Set<Id> productIds) {
    return new Map<Id, Product2>(
      [
        SELECT
          Id,
          (
            SELECT UnitPrice
            FROM PricebookEntries
            WHERE Pricebook2Id = :ECOMMERCE_PRICEBOOKID
            LIMIT 1
          )
        FROM Product2
        WHERE Id IN :productIds
      ]
    );
  }
}