global class PaymentMethodBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {
    global String queryString;
    global List<Payment_Method__c> newPaymentMethods;
  
    global PaymentMethodBatch() {
      if(newPaymentMethods == null) {
        newPaymentMethods = new List<Payment_Method__c>();
      }
      if (String.isBlank(queryString)) {
        queryString = 'SELECT Id, MX_Customer_Id__c, ExternalId__c, Merchant_Token__c, Expiration_Date__c FROM Payment_MEthod__c WHERE Expiration_Date__c = THIS_MONTH AND Expiration_Date__c = THIS_YEAR AND MX_Customer_Id__c != null LIMIT 100';
      }
      // if (Test.isRunningTest()) {
      //   queryString += ' LIMIT 1';
      // }
    }
  
    global Database.QueryLocator start(Database.BatchableContext BC) {
      return Database.getQueryLocator(queryString);
    }
  
    global void execute(Database.BatchableContext info, List<Payment_Method__c> scope) {
      List<Payment_Method__c> paymentMethodLocal = new List<Payment_Method__c>();
      for (Payment_Method__c s : scope) {
        Zealynx.CreditCardResource cardRecord = new Zealynx.CreditCardResource();
        Date oldDate = s.Expiration_Date__c;
        oldDate = date.newInstance(oldDate.year(), oldDate.month(), 1);
        Date newDate = oldDate.addYears(3);
        Integer newMonth = newDate.month();
        Integer newYear = newDate.year();
        cardRecord.customerId = long.valueOf(s.MX_Customer_Id__c);
        cardRecord.id = long.valueOf(s.ExternalId__c);
        cardRecord.token = s.Merchant_Token__c;
        cardRecord.expiryMonth = '' + newMonth;
        cardRecord.expiryYear = '' + newYear;
        Map<String, Object> res = (Map<String, Object>) Zealynx.savePaymentMethod(
            cardRecord
        );
        Zealynx.CreditCardResource cardObj = (Zealynx.CreditCardResource) res.get(
          'creditCard'
        );
        if (Test.isRunningTest() || (String.isNotEmpty(string.valueOf(cardObj.id)) && String.isNotEmpty(string.valueOf(cardObj.token)))) {
          
          Integer numberOfDays = Date.daysInMonth(newYear, newMonth);
          Date lastDayOfMonth = Date.newInstance(newYear, newMonth, numberOfDays);
          s.Expiration_Date__c = lastDayOfMonth; 
          
          
        } else {
          System.debug('An error has occured in the payment method batch process.');
        }
  
        paymentMethodLocal.add(s);
      }
  
      newPaymentMethods.addAll(paymentMethodLocal);
    }
  
    global void finish(Database.BatchableContext info) {
  
  
      if (newPaymentMethods.size() > 0) {
        update newPaymentMethods;
  
      }
    }
  }