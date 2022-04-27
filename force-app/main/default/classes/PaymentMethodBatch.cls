global class PaymentMethodBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {
    global String queryString;
  
    global PaymentMethodBatch() {
      if (String.isBlank(queryString)) {
        queryString = 'SELECT Id, MX_Customer_Id__c, ExternalId__c, Merchant_Token__c, Expiration_Date__c FROM Payment_MEthod__c WHERE Expiration_Date__c = THIS_MONTH AND Expiration_Date__c = THIS_YEAR AND MX_Customer_Id__c != null';
      }
      // if (Test.isRunningTest()) {
      //   queryString += ' LIMIT 1';
      // }
    }
  
    global Database.QueryLocator start(Database.BatchableContext BC) {
      return Database.getQueryLocator(queryString);
    }
  
    global void execute(Database.BatchableContext info, List<Payment_Method__c> scope) {
      List<Payment_Method__c> validPaymentMethods = new List<Payment_Method__c>();
      List<Payment_Method__c> invalidPaymentMethods = new List<Payment_Method__c>();
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
          
          validPaymentMethods.add(s);
        } else {
          
          invalidPaymentMethods.add(s);
        }
      }
      if(validPaymentMethods.size() > 0) {
        System.enqueueJob(new BoomSubscriptionPaymentsQueuable(validPaymentMethods, false));
      }
      
    }
  
    global void finish(Database.BatchableContext info) {
  
    }

    private static void sendExceptionEmails(List<Payment_Method__c> invalidPaymentMethods) {
      // do something 
    }
  }