public without sharing class Zealynx {
  // https://developer.mxmerchant.com/reference#create-customer
  static final String ENDPOINT = 'callout:Zealynx/v1/';

  @AuraEnabled
  public static Map<String,Object> saveCustomer(CustomerResource customer){
    system.debug(customer);
    Map<String,Object> results = new Map<String,Object>();
    customer = customer.save();
    results.put('isSuccess', customer.isSuccess);
    results.put('errorMessage', '');
    // results.put('errorCode', 400);
    results.put('customer', customer);
    return results;
  }


  /**
   * @description Use to both create and update a CreditCard on file
   */
  @AuraEnabled
  public static Map<String,Object> savePaymentMethod(CreditCardResource creditCard){
    System.debug(creditCard);
    Map<String,Object> results = new Map<String,Object>();
    creditCard = creditCard.save();
    results.put('isSuccess', creditCard.isSuccess);
    results.put('errorMessage', creditCard.errorMessage);
    // results.put('errorCode', 400);
    results.put('creditCard', creditCard);
    return results;
  }

  @AuraEnabled
  public static Map<String,Object> deletePaymentMethod(CreditCardResource creditCard){
    Map<String,Object> results = new Map<String,Object>();
    creditCard = creditCard.deleteCard();
    results.put('isSuccess', creditCard.isSuccess);
    results.put('errorMessage', '');
    // results.put('errorCode', 400);
    return results;
  }

  @AuraEnabled
  public static Map<String,Object> makePayment(PaymentResource payment){
    System.debug(payment);
    Map<String,Object> results = new Map<String,Object>();
    payment = payment.save();
    results.put('isSuccess', payment.isSuccess);
    results.put('errorMessage', '');
    // results.put('errorCode', 400);
    results.put('payment', payment);
    return results;
  }

  @AuraEnabled
  public static Map<String,Object> refundPayment(PaymentResource payment){
    System.debug(payment);
    Map<String,Object> results = new Map<String,Object>();
    payment = payment.refund();
    results.put('isSuccess', payment.isSuccess);
    results.put('errorMessage', '');
    // results.put('errorCode', 400);
    results.put('payment', payment);
    return results;
  }

  @AuraEnabled
  public static Map<String,Object> voidPayment(PaymentResource payment){
    Map<String,Object> results = new Map<String,Object>();
    payment = payment.void();
    results.put('isSuccess', payment.isSuccess);
    results.put('errorMessage', '');
    // results.put('errorCode', 400);
    results.put('payment', payment);
    return results;
  }


  /**
   * @name callout
   */
  static HttpResponse callout(String method, String endpoint, List<List<String>> headers, String body){
    HttpRequest req = new HttpRequest();
    req.setMethod(method);
    req.setEndpoint(endpoint);
    if ( headers == null ){
      headers = new List<List<String>>();
      headers.add(new List<String>{'Content-Type','application/json'});
      headers.add(new List<String>{'Accept','application/json'});
    }
    for ( List<String> header : headers ){
      req.setHeader(header[0],header[1]);
    }
    if ( String.isNotBlank(body) ){
      system.debug(JSON.serializePretty(JSON.deserializeUntyped(body)));
      req.setBody(body);
    }
    try {
      HttpResponse res = new Http().send(req);
      system.debug( res.toString() );
      system.debug( res.getBody() );
      return res;       
    } catch (Exception e) {
      system.debug(e);
      throw new AuraHandledException(e.getMessage());
    }
     
  } 

  // https://developer.mxmerchant.com/reference#create-customer
  public class CustomerResource extends MXMerchantResource {
    @AuraEnabled public DateTime created {get; set;} //Read-Only to LWC
    @AuraEnabled public String name {get; set;} 
    @AuraEnabled public String firstName {get; set;} 
    @AuraEnabled public String lastName {get; set;} 
    @AuraEnabled public String REPLACE_number {get; set;}  // Populate with Salesforce Contact Id
    @AuraEnabled public String taxId {get; set;} 
    @AuraEnabled public Integer visits {get; set;} 
    // @AuraEnabled public String transactionCount": 0,
    // @AuraEnabled public String spend": "0",
    // @AuraEnabled public String sales": "0",
    // @AuraEnabled public String refunds": "0",
    // @AuraEnabled public String lastActivity": "2018-01-30T15:02:12.827Z",
    // @AuraEnabled public String allowPromotions": false,
    // @AuraEnabled public String loyaltyStatus": "Declined",
    // @AuraEnabled public String loyaltyEnrolled": "",
    // @AuraEnabled public String isVip": false,
    // @AuraEnabled public String spendProfile": "New",
    // @AuraEnabled public String spendProfileIcon": "glyphicon-butterfly",
    // @AuraEnabled public String addressName": "Headquarters",
    @AuraEnabled public String address1 {get; set;} 
    @AuraEnabled public String address2 {get; set;} 
    @AuraEnabled public String city {get; set;} 
    @AuraEnabled public String state {get; set;}  //"TX"
    @AuraEnabled public String zip {get; set;}  //"75252"
    @AuraEnabled public String customerType {get; set;}  // Business or Person
    @AuraEnabled public String spendProfileOverride {get; set;}  // true,
    // @AuraEnabled public String hasPayments": false,
    // @AuraEnabled public String hasContracts": false,
    // @AuraEnabled public String hasInvoices": false,
    // @AuraEnabled public String displayColor": "A1BC3A",
    @AuraEnabled public Boolean activeStatus {get; set;}  // true

    public CustomerResource(){
      activeStatus = true;
    }

    public CustomerResource mock(){
      name = 'First Last';
      firstName = 'First';
      lastName = 'Last';
      REPLACE_number = '003000000ZZZZZ'; // Populate with Salesforce Contact Id
      address1 = '5709 Cahuenga';
      // address2;
      city = 'North Hollywood';
      state = 'CA';
      zip = '91601';
      customerType = 'Person'; // Business or Person 
      return this; 
    }

    public CustomerResource save(){
      System.debug('Customer save');
      System.debug(this);
      Map<String,Object> bodyMap = new Map<String,Object>();
      bodyMap.put('zealynx_sourceOperation','Upsert');
      bodyMap.put('zealynx_sourceObject','Customer');
      bodyMap.put('records', new List<Object>{this});
      HttpResponse res = callout('POST',endpoint,null,JSON.serialize(bodyMap).replace('REPLACE_', ''));
      ZealynxResponseResource ZealynxResponse = (ZealynxResponseResource)JSON.deserialize(res.getBody(), ZealynxResponseResource.class);
      if ( 
        ZealynxResponse.responses != null && 
        ZealynxResponse.responses.size() > 0 &&
        ZealynxResponse.responses[0].records != null &&
        ZealynxResponse.responses[0].records.size() > 0 &&
        ZealynxResponse.responses[0].records[0].id != null
      ){
        id = ZealynxResponse.responses[0].records[0].id;
      }
      return this;
    }
  }

  public class ZealynxResponseResource {
    public Integer status;
    public String statusText;
    public Integer errorCount;
    public List<MXMerchantResponseResource> responses;
  }

  public class MXMerchantResponseResource {
    public Integer status;
    public String statusText;
    public List<MXMerchantResource> records;
    public List<Object> errors;
  }

  public virtual class MXMerchantResource {
    @AuraEnabled public Boolean isSuccess {get; set;}
    @AuraEnabled public String errorMessage {get; set;}
    @AuraEnabled public Long id {get; set;}// 10000000532311
    @AuraEnabled public String token {get; set;}
    @AuraEnabled public String paymentToken {get; set; }
    @AuraEnabled public String status {get; set;}
    @AuraEnabled public String authCode { get; set; }
    @AuraEnabled public String reference { get; set; }

  }

  public class CreditCardResource extends MXMerchantResource {
    @AuraEnabled public String code {get; set;}
    @AuraEnabled public Long customerId {get; set;}
    // @AuraEnabled public Long subId {get; set;}
    // @AuraEnabled public String cardId {get; set;} //": "eXlrPIqkMmVxqnqTxmvMMJO0dOcf",
    @AuraEnabled public Boolean isDefault {get; set;} //true,
    @AuraEnabled public String alias {get; set;} //": "alias - credit",
    // @AuraEnabled public String cardType {get; set;} //": D"Visa",
    // @AuraEnabled public String last4 {get; set;} //": "3343",
    // @AuraEnabled public String token {get; set;} //": "TRKOO2SD9ZJAHYBTRUNNHBKJYCQWAUJS",
    @AuraEnabled public String expiryMonth {get; set;} //": "11",
    @AuraEnabled public String expiryYear {get; set;} //": "2038",
    @AuraEnabled public String name {get; set;} //": "NoTax Customer",
    @AuraEnabled public String avsStreet {get; set;} //": "1776 Main Street Unit 3",
    @AuraEnabled public String avsZip {get; set;} //": "30005",
    // @AuraEnabled public Boolean hasContract {get; set;} //": false
    @AuraEnabled public String REPLACE_number {get; set;}
    @AuraEnabled public String cvv {get; set;}
    

    public CreditCardResource() {
      // hasContract = false;
      code = 'card';
    }

    public CreditCardResource save(){
      Map<String,Object> bodyMap = new Map<String,Object>();
      bodyMap.put('zealynx_sourceOperation','Upsert');
      bodyMap.put('zealynx_sourceObject','customercardaccount');
      bodyMap.put('records', new List<CreditCardResource>{this});
      HttpResponse res = callout('POST',endpoint,null,JSON.serialize(bodyMap).replace('REPLACE_', ''));
      System.debug(res.getBody());
      ZealynxResponseResource ZealynxResponse = (ZealynxResponseResource)JSON.deserialize(res.getBody(), ZealynxResponseResource.class);
      System.debug(ZealynxResponse.responses);
      if ( 
        ZealynxResponse.responses != null && 
        ZealynxResponse.responses.size() > 0 &&
        ZealynxResponse.responses[0].records != null &&
        ZealynxResponse.responses[0].records.size() > 0 &&
        ZealynxResponse.responses[0].records[0].id != null &&
        ZealynxResponse.responses[0].records[0].token != null
      ){
        isSuccess = ZealynxResponse.status < 300;
        id = ZealynxResponse.responses[0].records[0].id;
        token = ZealynxResponse.responses[0].records[0].token;
      } else if (ZealynxResponse.responses[0].errors != null && ZealynxResponse.responses[0].errors.size() > 0){
        isSuccess = false;
        errorMessage = JSON.serialize(ZealynxResponse.responses[0].errors[0]);
      }
      return this;
    }

    public CreditCardResource deleteCard(){
      Map<String,Object> bodyMap = new Map<String,Object>();
      bodyMap.put('zealynx_sourceOperation','Delete');
      bodyMap.put('zealynx_sourceObject','customercardaccount');
      bodyMap.put('records', new List<CreditCardResource>{this});
      HttpResponse res = callout('POST',endpoint,null,JSON.serialize(bodyMap));
      ZealynxResponseResource ZealynxResponse = (ZealynxResponseResource)JSON.deserialize(res.getBody(), ZealynxResponseResource.class);
      if ( 
        ZealynxResponse.responses != null && 
        ZealynxResponse.responses.size() > 0 &&
        ZealynxResponse.responses[0].records != null &&
        ZealynxResponse.responses[0].records.size() > 0 &&
        ZealynxResponse.responses[0].records[0].id != null
      ){
        isSuccess = ZealynxResponse.status < 300;
      }
      return this;
    }



  }

  public class PaymentResource extends MXMerchantResource {
    @AuraEnabled public Decimal amount {get; set;}
    @AuraEnabled public String paymentType {get; set;}    //Type of transaction Values: Sale, Refund, CashAdvance, Prepaid, Adjustment, Void, Reversal, Authorization, SaleCompletion, PaymentTransaction, Withdrawal, Balance
    public String tenderType {get; set;}  //Card, Check, Cash, Multiple, Loyalty, ACH
    @AuraEnabled public String entryClass {get; set;}  // CCD, PPD, TEL, WEB
    public Boolean cardPresent {get; set;}
    public Boolean authOnly {get; set;}
    @AuraEnabled public Boolean isAuth {get; set;}
    @AuraEnabled public Boolean isSettleFunds {get; set;}
    @AuraEnabled public String clientReference {get; set;}
    @AuraEnabled public String cardAccountToken {get; set;} // Payment Method Id
    @AuraEnabled public String invoice {get; set;} //Unique Id of this Payment
    @AuraEnabled public Long customerId {get; set;}
    @AuraEnabled public Boolean isTaxExempt {get; set;}

    public PaymentResource(){
      tenderType = 'Card';
      isSettleFunds = true;
      isAuth = true;
      authOnly = false;
      cardPresent = false;
      isTaxExempt = false;
    }

    public PaymentResource save(){
      Map<String,Object> bodyMap = new Map<String,Object>();
      bodyMap.put('zealynx_sourceOperation','Upsert');
      bodyMap.put('zealynx_sourceObject','Payment');
      bodyMap.put('records', new List<PaymentResource>{this});
      System.debug('IN PAYMENT SAVE BEFORE CALLOUT');
      HttpResponse res = callout('POST',endpoint,null,JSON.serialize(bodyMap));
      ZealynxResponseResource ZealynxResponse = (ZealynxResponseResource)JSON.deserialize(res.getBody(), ZealynxResponseResource.class);
      System.debug(ZealynxResponse.responses);

      if ( 
        ZealynxResponse.responses != null && 
        ZealynxResponse.responses.size() > 0 &&
        ZealynxResponse.responses[0].records != null &&
        ZealynxResponse.responses[0].records.size() > 0 &&
        ZealynxResponse.responses[0].records[0].id != null && 
        ZealynxResponse.responses[0].records[0].paymentToken != null &&
        ZealynxResponse.responses[0].records[0].status != null
      ){
        isSuccess = ZealynxResponse.status < 300;
        id = ZealynxResponse.responses[0].records[0].id;
        paymentToken = ZealynxResponse.responses[0].records[0].paymentToken;
        status = ZealynxResponse.responses[0].records[0].status;
        if(
          ZealynxResponse.responses[0].records[0].authCode != null
          ) {
            authCode = ZealynxResponse.responses[0].records[0].authCode;  
          }
        if(ZealynxResponse.responses[0].records[0].reference != null) {
          reference = ZealynxResponse.responses[0].records[0].reference;  
        }
      }
      return this;
    }

    public PaymentResource refund(){
      Map<String,Object> bodyMap = new Map<String,Object>();
      bodyMap.put('zealynx_sourceOperation','Refund');
      bodyMap.put('zealynx_sourceObject','Payment');
      bodyMap.put('records', new List<PaymentResource>{this});
      System.debug('IN REFUND BEFORE CALLOUT');
      HttpResponse res = callout('POST',endpoint,null,JSON.serialize(bodyMap));
      ZealynxResponseResource ZealynxResponse = (ZealynxResponseResource)JSON.deserialize(res.getBody(), ZealynxResponseResource.class);
      if ( 
        ZealynxResponse.responses != null && 
        ZealynxResponse.responses.size() > 0 &&
        ZealynxResponse.responses[0].records != null &&
        ZealynxResponse.responses[0].records.size() > 0 &&
        ZealynxResponse.responses[0].records[0].id != null && 
        ZealynxResponse.responses[0].records[0].paymentToken != null &&
        ZealynxResponse.responses[0].records[0].status != null &&
        ZealynxResponse.responses[0].records[0].authCode != null &&
        ZealynxResponse.responses[0].records[0].reference != null

      ){
        isSuccess = ZealynxResponse.status < 300;
        id = ZealynxResponse.responses[0].records[0].id;
        paymentToken = ZealynxResponse.responses[0].records[0].paymentToken;
        status = ZealynxResponse.responses[0].records[0].status;
        authCode = ZealynxResponse.responses[0].records[0].authCode;  
        reference = ZealynxResponse.responses[0].records[0].reference;

      }
      return this;
    }

    public PaymentResource void(){
      Map<String,Object> bodyMap = new Map<String,Object>();
      bodyMap.put('zealynx_sourceOperation','Void');
      bodyMap.put('zealynx_sourceObject','Payment');
      bodyMap.put('records', new List<PaymentResource>{this});
      HttpResponse res = callout('POST',endpoint,null,JSON.serialize(bodyMap));
      ZealynxResponseResource ZealynxResponse = (ZealynxResponseResource)JSON.deserialize(res.getBody(), ZealynxResponseResource.class);
      System.debug(ZealynxResponse);
      if ( 
        ZealynxResponse.responses != null && 
        ZealynxResponse.responses.size() > 0 &&
        ZealynxResponse.responses[0].records != null &&
        ZealynxResponse.responses[0].records.size() > 0 &&
        ZealynxResponse.responses[0].records[0].id != null
      ){
        isSuccess = ZealynxResponse.status < 300;
      }
      return this;
    }

  }


}