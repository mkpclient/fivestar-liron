global class PaymentBatchable implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {
  global String queryString;

  global paymentBatchable() {
    if (String.isBlank(queryString)) {
      queryString = 'SELECT Id, Sales_Order__r.Name, Sales_Order__r.Alternate_Contact_Email__c, Sales_Order__r.Send_Invoice_to_Alternate_Contact__c, Sales_Order__r.Price_Book__r.Business_Unit__c, Sales_Order__c, Contact__c, Contact__r.Email, Payment_Method__r.Merchant_Token__c, Amount__c FROM Payment__c WHERE Status__c = \'Scheduled\' AND Scheduled_Payment_Date__c <= TODAY AND Payment_Method__c != null AND Sales_Order__r.BalanceDueAmount__c > 0';
    }
    // if (Test.isRunningTest()) {
    //   queryString += ' LIMIT 1';
    // }
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(queryString);
  }

  global void execute(Database.BatchableContext info, List<Payment__c> scope) {
    List<Payment__c> paymentsLocal = new List<Payment__c>();
    for (Payment__c s : scope) {
      Zealynx.PaymentResource paymentRecord = new Zealynx.PaymentResource();
      paymentRecord.amount = s.Amount__c;
      paymentRecord.paymentType = 'Sale';
      paymentRecord.entryClass = 'WEB';
      paymentRecord.cardAccountToken = s.Payment_Method__r.Merchant_Token__c;

      paymentRecord.clientReference = s.Sales_Order__r.Name.length() > 16 ? s.Sales_Order__r.Name.replaceFirst('-', '') : s.Sales_Order__r.Name;
      paymentRecord.invoice = s.Sales_Order__r.Name.length() > 16 ? s.Sales_Order__r.Name.replaceFirst('-', '') : s.Sales_Order__r.Name;

      System.debug(paymentRecord);
      try {
        Map<String, Object> res = (Map<String, Object>) Zealynx.makePayment(
          paymentRecord
        );
        Zealynx.PaymentResource paymentObj = (Zealynx.PaymentResource) res.get(
          'payment'
        );
        if ((String) paymentObj.status == 'Approved') {
          s.Status__c = 'Completed';
          s.Date__c = (Date) system.today();
  
          if(!test.isRunningTest()) {
            s.Authorization_Id__c = '' + paymentObj.authCode;    
          }
          
        } else if (
          (String) paymentObj.status == 'Declined'
        ) {
          s.Status__c = 'Declined';
          s.Date__c = (Date) system.today();
        } else {
          s.Status__c = 'Error';
          System.debug('An error has occured in the payment batch process.');
        }
        s.MX_Payment_Id__c = '' + paymentObj.id;
        s.Transaction_Type__c = 'Payment';
        s.Payment_Token__c = (String) paymentObj.paymentToken;
        s.Transaction_Id__c = '' + paymentObj.reference;
  
        paymentsLocal.add(s);
      } catch (Exception err) {
        System.debug(err.getMessage());
        s.Status__c = 'Error';
        s.Memo__c = 'Error: ' + err.getMessage();
        paymentsLocal.add(s);
        continue;
      }
    }

    System.enqueueJob(new BoomSubscriptionPaymentsQueuable(paymentsLocal, true));
  }

  global void finish(Database.BatchableContext info) {
    
  }
}