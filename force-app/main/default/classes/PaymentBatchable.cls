global class PaymentBatchable implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {
  global String queryString;
  global List<Payment__c> newPayments;

  global paymentBatchable() {
    if(newPayments == null) {
      newPayments = new List<Payment__c>();
    }
    if (String.isBlank(queryString)) {
      queryString = 'SELECT Id, Sales_Order__r.Name, Sales_Order__r.Alternate_Contact_Email__c, Sales_Order__r.Send_Invoice_to_Alternate_Contact__c, Sales_Order__c, Contact__c, Contact__r.Email, Payment_Method__r.Merchant_Token__c, Amount__c FROM Payment__c WHERE Id NOT IN :newPayments AND Status__c = \'Scheduled\' AND Scheduled_Payment_Date__c <= TODAY AND Payment_Method__c != null';
    }
    // if (Test.isRunningTest()) {
    //   queryString += ' LIMIT 1';
    // }
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(queryString);
  }

  global void execute(Database.BatchableContext info, List<Payment__c> scope) {
    System.debug('New payments count: ' + newPayments.size());
    List<Payment__c> paymentsLocal = new List<Payment__c>();
    for (Payment__c s : scope) {
      Zealynx.PaymentResource paymentRecord = new Zealynx.PaymentResource();
      paymentRecord.amount = s.Amount__c;
      paymentRecord.paymentType = 'Sale';
      paymentRecord.entryClass = 'WEB';
      paymentRecord.cardAccountToken = s.Payment_Method__r.Merchant_Token__c;

      paymentRecord.clientReference = s.Sales_Order__r.Name;
      paymentRecord.invoice = s.Sales_Order__r.Name;

      System.debug(paymentRecord);
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
    }

    newPayments.addAll(paymentsLocal);
  }

  global void finish(Database.BatchableContext info) {
    System.debug('New payments complete count: ' + newPayments.size());

    System.debug('Finished batch process.');
    System.debug(JSON.serializePretty(newPayments));

    if (newPayments.size() > 0) {
      update newPayments;

      PaymentBatchableHelper.processEmails(newPayments);
    }
  }
}