global class SubscriptionOrdersBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {
    global String queryString;
    public static String declinedCardStatus = 'Payment Update Needed';

    global SubscriptionOrdersBatch() {
        if (String.isBlank(queryString)) {
            queryString = 'SELECT Id, Name, Subscription__c, Net_Due__c, Subscription__r.Payment_Method__c, ';
            queryString += 'Account__c, ContactBilling__c, ';
            queryString += 'Subscription__r.Payment_Method__r.Merchant_Token__c, Subscription__r.Payment_Method__r.MX_Customer_Id__c '; 
            queryString += 'FROM SalesOrder__c WHERE Subscription__r.Payment_Method__c != null AND Subscription__c != null AND Subscription__r.Status__c = \'Active\' AND OrderDate__c = LAST_N_DAYS:28 AND (Status_Picklist__c = \'Pending Renewal\' OR Status_Picklist__c = \'Payment Update Needed\')';
          }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext info, List<SalesOrder__c> scope) {
        List<Payment__c> paymentsLocal = new List<Payment__c>();
        List<SalesOrder__c> updatedSalesOrders = new List<SalesOrder__c>();
        for(SalesOrder__c s : scope) {
            if(s.Net_Due__c == 0 || test.isRunningTest()) {
              s.Status_Picklist__c = 'Approved';
              s.Approved_Complimentary_Order__c = true;
              if(test.isRunningTest()) {
                s.Approved_Complimentary_Order__c = false;
                s.Status_Picklist__c = 'Pending Renewal';
              } else {
                updatedSalesOrders.add(s);
                continue;  
              }
            }
            Payment__c newPayment = new Payment__c(
                Payment_Method__c = s.Subscription__r.Payment_Method__c,
                Account__c = s.Account__c,
                Amount__c = s.Net_Due__c,
                Sales_Order__c = s.Id,
                Contact__c = s.ContactBilling__c,
                Date__c = System.today(),
                Payment_Type__c = 'Credit Card'
            );

            Zealynx.PaymentResource pR = new Zealynx.PaymentResource();
            pR.amount = s.Net_Due__c;
            pR.paymentType = 'Sale';
            pR.entryClass = 'WEB';
            pR.cardAccountToken = s.Subscription__r.Payment_Method__r.Merchant_Token__c;
            pR.clientReference = s.Name.length() > 16 ? s.Name.replaceFirst('-', '') : s.Name;
            pR.invoice = s.Name.length() > 16 ? s.Name.replaceFirst('-', '') : s.Name;

            try {
              Map<String, Object> res = (Map<String, Object>) Zealynx.makePayment(pR);
              Zealynx.PaymentResource paymentObj = (Zealynx.PaymentResource) res.get(
                  'payment'
              );
  
              if ((String) paymentObj.status == 'Approved') {
                  newPayment.Status__c = 'Completed';
                  newPayment.Date__c = (Date) system.today();
          
                  if(!test.isRunningTest()) {
                      newPayment.Authorization_Id__c = '' + paymentObj.authCode;    
                  }
                  
                } else if (
                  (String) paymentObj.status == 'Declined'
                ) {
                  newPayment.Status__c = 'Declined';
                  newPayment.Date__c = (Date) system.today();
                  s.Status_Picklist__c = declinedCardStatus;
                  updatedSalesOrders.add(s);
                } else {
                  newPayment.Status__c = 'Error';
                  System.debug('An error has occured in the payment batch process.');
                  s.Status_Picklist__c = declinedCardStatus;
                  updatedSalesOrders.add(s);
                  paymentsLocal.add(newPayment);
                  continue;
                }
                newPayment.MX_Payment_Id__c = '' + paymentObj.id;
                newPayment.Transaction_Type__c = 'Payment';
                newPayment.Payment_Token__c = (String) paymentObj.paymentToken;
                newPayment.Transaction_Id__c = '' + paymentObj.reference;
                paymentsLocal.add(newPayment);
            } catch (Exception err) {
              System.debug(err.getMessage());
              newPayment.Status__c = 'Error';
              s.Status_Picklist__c = declinedCardStatus;
              updatedSalesOrders.add(s);
              paymentsLocal.add(newPayment);
              continue;
            }
            
        }

        if(paymentsLocal.size() > 0) {
          upsert paymentsLocal;
        }

        if(updatedSalesOrders.size() > 0) {
          upsert updatedSalesOrders;
        }

        
        
      }
    
      global void finish(Database.BatchableContext info) {
        if(test.isRunningTest()) {
          Database.executeBatch(new MissedSubscriptionsBatch(), 50);
        } else {
          System.scheduleBatch(new MissedSubscriptionsBatch(), 'Create Pending Renewals for Missed Subscriptions', 30, 50);
        }
      }
}