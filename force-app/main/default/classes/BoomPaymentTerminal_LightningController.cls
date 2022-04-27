public without sharing class BoomPaymentTerminal_LightningController {
  public static final String ESSENTIAL_ENG = 'Essential Engine';
  public static final List<String> ALLOWED_PROFILES = new List<String>{
    'FSP - Accounting +',
    'System Administrator'
  };

  public static final List<String> DISALLOW_STATUSES = new List<String>{
    'Draft',
    'Released',
    'Submitted for Approval'
  };

  public static final String FINANCE_FEE_ACC = 'Multi payment Convenience Fee';
  public static final String DISC_PRODUCTNAME = 'Discount';

  public static final List<String> CONTACT_FIELDS = new List<String>{
    'Id',
    'Name',
    'FirstName',
    'LastName',
    'MailingStreet',
    'MailingPostalCode',
    'MailingState',
    'MailingCity',
    'MailingCountry',
    'MX_Customer_Id__c'
  };
  // FINANCE FEE = (ORDER TOTAL - TODAYS PAYMENT) * FINANCE FEE %)
  // do not allow multiple for essential engine orders
  // first payment date is one month from order date and not editable by AM SF profile
  public virtual class TerminalWrapper {
    @AuraEnabled
    public Boolean allowMultiple { get; set; }
    @AuraEnabled
    public Boolean isAmProfile { get; set; }
    @AuraEnabled
    public Date firstPaymentDate { get; set; }
    // @AuraEnabled
    // public Decimal financeFeeRate { get; set; }
    @AuraEnabled
    public Decimal totalAmount { get; set; }
    @AuraEnabled
    public Decimal orderTotal { get; set; }
    @AuraEnabled
    public Decimal amountDue { get; set; }
    @AuraEnabled
    public Decimal amountPaid { get; set; }
    @AuraEnabled
    public Id contactId { get; set; }
    @AuraEnabled
    public String accountName { get; set; }
    @AuraEnabled
    public Boolean allowPayments { get; set; }
  }

  public virtual class MultiplePayment {
    @AuraEnabled
    public Boolean waveFinanceFee { get; set; }
    @AuraEnabled
    public Integer numberOfPayments { get; set; }
    @AuraEnabled
    public Decimal financeFee { get; set; }
    @AuraEnabled
    public Decimal paymentAmount { get; set; }
    @AuraEnabled
    public Id paymentMethodId { get; set; }
    @AuraEnabled
    public Id salesOrderId { get; set; }
    @AuraEnabled
    public Decimal firstPayment { get; set; }
    @AuraEnabled
    public Date newFirstPaymentDate { get; set; }
    @AuraEnabled
    public Id contactId { get; set; }
  }

  public virtual class CustomPaymentMethod {
    @AuraEnabled
    public String cardNumber { get; set; }
    @AuraEnabled
    public String expirationMonth { get; set; }
    @AuraEnabled
    public String expirationYear { get; set; }
    @AuraEnabled
    public String customerMerchantId { get; set; }
  }

  public virtual class ReturnObject {
    @AuraEnabled
    public Boolean error { get; set; }
    @AuraEnabled
    public String message { get; set; }
  }

  public virtual class SinglePayment {
    @AuraEnabled
    public Decimal amount { get; set; }
    @AuraEnabled
    public Id salesOrderId { get; set; }
    @AuraEnabled
    public Id paymentMethodId { get; set; }
    @AuraEnabled
    public Id contactId { get; set; }
  }
  

  @AuraEnabled
  public static ReturnObject handleMultiplePayments(MultiplePayment multiplePayment) {
    ReturnObject returnObject = new ReturnObject();
    
    try {
      SinglePayment firstPm = new SinglePayment();
      firstPm.amount = multiplePayment.firstPayment;
      firstPm.contactId = multiplePayment.contactId;
      firstPm.paymentMethodId = multiplePayment.paymentMethodId;
      firstPm.salesOrderId = multiplePayment.salesOrderId;
      returnObject = handleSinglePayment(firstPm);

      if(returnObject.error != null && returnObject.error) {
        return returnObject;
      }

      SalesOrder__c so = [SELECT Id, Name, ContactBilling__c, Account__c FROM SalesOrder__c WHERE Id = :multiplePayment.salesOrderId];
      List<Payment__c> scheduledPayments = new List<Payment__c>();

      if(multiplePayment.financeFee != 0 && multiplePayment.numberOfPayments > 1) {
        processFinanceFee(multiplePayment.waveFinanceFee, multiplePayment.financeFee, multiplePayment.salesOrderId, so.ContactBilling__c);
      }

      Integer month = multiplePayment.newFirstPaymentDate.month();
      Integer year = multiplePayment.newFirstPaymentDate.year();
      Integer day = multiplePayment.newFirstPaymentDate.day();
      Integer daysInMonth = Date.daysInMonth(year, month);
      
      for(Integer i = 0; i < multiplePayment.numberOfPayments; i++) {
        Integer dayCorrected = day;
        if(day > daysInMonth) {
          dayCorrected = daysInMonth;
        }
        Date paymentDate = Date.newInstance(year, month, dayCorrected);

        Payment__c payment = new Payment__c();
        payment.Account__c = so.Account__c;
        payment.Amount__c = multiplePayment.paymentAmount;
        payment.Payment_Method__c = multiplePayment.paymentMethodId;
        payment.Sales_Order__c = so.Id;
        payment.Contact__c = multiplePayment.contactId;
        payment.Payment_Type__c = 'Credit Card';
        payment.Scheduled_Payment_Date__c = paymentDate;
        payment.Date__c = paymentDate;
        payment.Status__c = 'Scheduled';
        scheduledPayments.add(payment);
        if(month < 12) {
          month++;
        } else {
          month = 1;
          year++;
        }
      }

      insert scheduledPayments;

      return returnObject;
    } catch (Exception err) {
      System.debug(err.getLineNumber() + ':' + err.getMessage());
      throw new AuraHandledException(err.getMessage());
    }
    
  }

  @future
  public static void processFinanceFee(Boolean waived, Decimal financeFee, String orderId, String contactId) {
    List<AdditionalChargeCredit__c> acc = [SELECT Id FROM AdditionalChargeCredit__c WHERE Name = :FINANCE_FEE_ACC AND IsActive__c = true LIMIT 1];
    if(acc.size() > 0) {
      Id accId = acc[0].Id;
      SalesOrderAdditionalChargeCredit__c newSOACC = new SalesOrderAdditionalChargeCredit__c();
      newSOACC.Additional_Charge_Credit__c = accId;
      newSOACC.Quantity__c = 1;
      newSOACC.SalesOrder__c = orderId;
      newSOACC.SalesPrice__c = financeFee;
      newSOACC.LineDescription__c = 'Finance Fee';
      newSOACC.Date__c = System.today();
      insert newSOACC;

      if(waived) {
        List<Product2> discProd = [SELECT Id FROM Product2 WHERE Name = :DISC_PRODUCTNAME AND IsActive = true LIMIT 1];
        if(discProd.size() > 0) {
          Id discProdId = discProd[0].Id;
          SalesOrderProductLine__c newSopl = new SalesOrderProductLine__c();
          newSopl.ContactShipping__c = contactId;
          newSopl.SalesOrder__c = orderId;
          newSopl.SalesPrice__c = 0 - financeFee;
          newSopl.Quantity__c = 1;
          newSopl.Product__c = discProdId;
          newSopl.DateRequired__c = System.today();
          newSopl.Display_Name_for_Invoice__c = 'Finance Fee Waiver';
          newSopl.ListPrice__c = 0;
          insert newSopl;
        }
      }
    }
  }

  @AuraEnabled
  public static ReturnObject handleSinglePayment(SinglePayment singlePayment) {
      ReturnObject returnObject = new ReturnObject();
      SalesOrder__c so = [
        SELECT Id, Name, Account__c
        FROM SalesOrder__c
        WHERE Id = :singlePayment.salesOrderId
      ];
      Payment_Method__c pm = [
        SELECT Id, MX_Customer_Id__c, Merchant_Token__c, ExternalId__c
        FROM Payment_Method__c
        WHERE Id = :singlePayment.paymentMethodId
      ];
      
      Payment__c payment = new Payment__c(
        Account__c = so.Account__c,
        Amount__c = singlePayment.amount,
        Contact__c = singlePayment.contactId,
        Payment_Method__c = singlePayment.paymentMethodId,
        Payment_Type__c = 'Credit Card',
        Sales_Order__c = singlePayment.salesOrderId,
        Status__c = 'Error'
      );

      try {
      Zealynx.PaymentResource pr = new Zealynx.PaymentResource();
      pr.amount = singlePayment.amount;
      pr.paymentType = 'Sale';
      pr.entryClass = 'WEB';
      pr.cardAccountToken = pm.Merchant_Token__c;
      pr.clientReference = so.Name;
      pr.invoice = so.Name.length() > 16 ? so.Name.replace('-', '') : so.Name;
      Map<String, Object> retData = Zealynx.makePayment(pr);
      if(retData.get('payment') != null) {
        Zealynx.PaymentResource pmtData = (Zealynx.PaymentResource) retData.get('payment');
        if(pmtData.status == 'Approved') {
          payment.Status__c = 'Completed';
          payment.Authorization_Id__c = pmtData.authCode;
        } else if (pmtData.status == 'Declined') {
          payment.Status__c = 'Declined';
          returnObject.error = true;
          returnObject.message = 'The payment was declined. Please try again.';
        }
        payment.Payment_Token__c = String.valueOf(pmtData.paymentToken);
        payment.MX_Payment_Id__c = String.valueOf(pmtData.id);
        payment.Transaction_Id__c = String.valueOf(pmtData.reference);
        payment.Transaction_Type__c = 'Payment';
        payment.Date__c = System.today();
      }
      insert payment;

      return returnObject;
    } catch (Exception err) {
      payment.Status__c = 'Error';
      if(String.isNotEmpty(payment.MX_Payment_Id__c)) {
        Zealynx.PaymentResource voidRec = new Zealynx.PaymentResource();
        voidRec.id = Long.valueOf(payment.MX_Payment_Id__c);
        Zealynx.voidPayment(voidRec);
      }
      insert payment;
      System.debug(err.getLineNumber() + ': ' + err.getMessage());
      throw new AuraHandledException(err.getMessage());
    }
  }

  @AuraEnabled
  public static Contact saveCustomer(Contact record) {
    Zealynx.CustomerResource customerResource = new Zealynx.CustomerResource();
    customerResource.firstName = record.FirstName;
    customerResource.lastName = record.LastName;
    customerResource.REPLACE_number = record.Id;
    customerResource.address1 = record.MailingStreet;
    customerResource.address2 = '';
    customerResource.city = record.MailingCity;
    customerResource.state = record.MailingState;
    String zipCode = record.MailingPostalCode;
    if (zipCode.length() == 5) {
      customerResource.zip = zipCode;
    } else {
      customerResource.zip = '0' + zipCode;
      record.MailingPostalCode = '0' + zipCode;
    }
    customerResource.customerType = 'Business';
    try {
      Map<String, Object> res = Zealynx.saveCustomer(customerResource);
      if (res.get('customer') != null) {
        Zealynx.CustomerResource customer = (Zealynx.CustomerResource) res.get(
          'customer'
        );
        if (customer.id == null) {
          throw new AuraHandledException(
            'There was a problem retrieving customer data from the payment merchant.'
          );
        }
        update new Contact(
          Id = record.Id,
          MX_Customer_Id__c = String.valueOf(customer.id)
        );
        System.debug('Customer created successfully');
      }

      return returnRelatedContact(record.Id);
    } catch (Exception e) {
      System.debug(e.getLineNumber() + ' ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Payment_Method__c savePaymentMethod(
    Payment_Method__c record,
    CustomPaymentMethod customRecord
  ) {
    try {
      Zealynx.CreditCardResource ccResource = new Zealynx.CreditCardResource();
      ccResource.customerId = Long.valueOf(customRecord.customerMerchantId);
      ccResource.isDefault = Boolean.valueOf(record.Default__c);
      ccResource.expiryMonth = customRecord.expirationMonth;
      ccResource.expiryYear = customRecord.expirationYear;
      ccResource.name =
        record.Billing_First_Name__c +
        ' ' +
        record.Billing_Last_Name__c;
      ccResource.avsStreet = record.Billing_Street__c;
      String zipCode = record.Billing_Postal_Code__c;
      if (zipCode.length() == 5) {
        ccResource.avsZip = zipCode;
      } else {
        ccResource.avsZip = '0' + zipCode;
      }
      ccResource.REPLACE_number = customRecord.cardNumber;
      ccResource.alias =
        record.Billing_First_Name__c +
        ' ' +
        record.Billing_Last_Name__c +
        ' ' +
        record.Card_Type__c;

      Map<String, Object> res = Zealynx.savePaymentMethod(ccResource);

      if (
        Boolean.valueOf(res.get('isSuccess')) && res.get('creditCard') != null
      ) {
        Zealynx.CreditCardResource creditCard = (Zealynx.CreditCardResource) res.get(
          'creditCard'
        );
        List<Payment_Method__c> existing = [
          SELECT Id
          FROM Payment_Method__c
          WHERE Merchant_Token__c = :creditCard.token AND Inactive__c = FALSE
          LIMIT 1
        ];
        if (existing.size() > 0) {
          throw new AuraException(
            'This card is already associated with another account.'
          );
        }

        record.ExternalId__c = String.valueOf(creditCard.id);
        record.Merchant_Token__c = String.valueOf(creditCard.token);

        Integer numberDays = Date.daysInMonth(
          Integer.valueOf(customRecord.expirationYear),
          Integer.valueOf(customRecord.expirationMonth)
        );
        record.Expiration_Date__c = Date.newInstance(
          Integer.valueOf(customRecord.expirationYear),
          Integer.valueOf(customRecord.expirationMonth),
          numberDays
        );
        record.Last_4_Digits_of_Card__c = customRecord.cardNumber.substring(
          customRecord.cardNumber.length() - 4
        );

        upsert record;
      }

      return record;
    } catch (Exception e) {
      System.debug(e.getLineNumber() + ' ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static TerminalWrapper getRecordData(Id recordId) {
    try {
      SalesOrder__c so = [
        SELECT
          Id,
          Name,
          ContactBilling__c,
          Account__r.Name,
          OrderDate__c,
          CompletedPayments__c,
          NetAmount__c,
          ExistingPayments__c,
          BalanceDueAmount__c,
          Net_Due__c,
          Price_Book__r.Business_Unit__c,
          TotalAmount__c,
          Status_Picklist__c
        FROM SalesOrder__c
        WHERE Id = :recordId
      ];

      Profile userProfile = [
        SELECT Id, Name
        FROM Profile
        WHERE Id = :UserInfo.getProfileId()
      ];

      // Decimal financeFeeRate = 0;

      // if (
      //   so.TotalAmount__c >= 500 &&
      //   so.TotalAmount__c < 1000 &&
      //   Finance_Fee_Chart__mdt.getInstance('X500') != null
      // ) {
      //   financeFeeRate = Finance_Fee_Chart__mdt.getInstance('X500')
      //     .Finance_Fee_Rate__c;
      // } else if (
      //   so.TotalAmount__c >= 1000 &&
      //   Finance_Fee_Chart__mdt.getInstance('X1000') != null
      // ) {
      //   financeFeeRate = Finance_Fee_Chart__mdt.getInstance('X1000')
      //     .Finance_Fee_Rate__c;
      // }

      TerminalWrapper retData = new TerminalWrapper();
      retData.allowMultiple =
        so.Price_Book__r.Business_Unit__c != ESSENTIAL_ENG;
      retData.isAmProfile = !ALLOWED_PROFILES.contains(userProfile.Name);
      retData.firstPaymentDate = System.today().addMonths(1);
      // retData.financeFeeRate = financeFeeRate;
      retData.totalAmount = so.NetAmount__c;
      retData.orderTotal = so.NetAmount__c;
      retData.amountDue = so.BalanceDueAmount__c;
      retData.amountPaid = so.ExistingPayments__c;
      retData.contactId = so.ContactBilling__c;
      retData.accountName = so.Account__r.Name;
      retData.allowPayments = !DISALLOW_STATUSES.contains(so.Status_Picklist__c);
      return retData;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Map<Id, Payment_Method__c> returnPaymentMethods(Id contactId) {
    try {
      return new Map<Id, Payment_Method__c>(
        [
          SELECT
            Id,
            Billing_First_Name__c,
            Billing_Last_Name__c,
            Billing_Street__c,
            Billing_Postal_Code__c,
            Contact__c,
            Contact__r.Name,
            Card_Type__c,
            Expiration_Date__c,
            Last_4_Digits_of_Card__c,
            MX_Customer_Id__c,
            Merchant_Token__c,
            ExternalId__c,
            Default__c
          FROM Payment_Method__c
          WHERE Contact__c = :contactId AND Inactive__c = FALSE
        ]
      );
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static Contact returnRelatedContact(Id contactId) {
    try {
      String queryString =
        'SELECT ' +
        String.join(CONTACT_FIELDS, ', ') +
        ' FROM Contact WHERE Id = :contactId';
      return Database.query(queryString);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
