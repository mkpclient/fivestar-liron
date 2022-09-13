global class ECommercePaymentQueueable implements Queueable, Database.AllowsCallouts {
  global class ECommercePaymentResource {
    global Contact contact;
    global Payment_Method__c paymentMethod;
    global SalesOrder__c salesOrder;
    global String city;
    global Decimal amount;
  }

  private List<ECommercePaymentResource> request;
  global ECommercePaymentQueueable(String request) {
    this.request = (List<ECommercePaymentResource>) JSON.deserialize(request, List<ECommercePaymentResource>.class);
  }


  global void execute(QueueableContext qCntxt) {
    if (this.request.size() > 0) {
        Set<Id> salesOrderIds = new Set<Id>();
        for(ECommercePaymentResource payment : this.request) {
            salesOrderIds.add(payment.salesOrder.Id);
        }
        Map<Id,SalesOrder__c> soNameMap = new Map<Id,SalesOrder__c>([
            SELECT Id, Name FROM SalesOrder__c WHERE Id IN :salesOrderIds
        ]);
        List<Payment__c> payments = new List<Payment__c>();
        for(ECommercePaymentResource r: request) {
            Contact existingContact = r.contact;
            Payment_Method__c paymentMethod = r.paymentMethod;
            SalesOrder__c so = r.salesOrder;
            String shipToCity = r.city;
            Decimal totalAmount = r.amount;
            String soName = soNameMap.get(so.Id).Name;
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
            zealynxPayment.reference = soName;
            zealynxPayment.invoice = soName;
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
            payment.Payment_Processor__c = 'MX Merchant';
            payment.Account__c = so.Account__c;
            payment.Ship_To_City__c = shipToCity;
            payment.Payment_Type__c = 'Credit Card';
            payment.Payment_Method__c = paymentMethod.Id;
            payment.Sales_Order__c = so.Id;
      
            payments.add(payment);
        }
        if(payments.size() > 0) {
            insert payments;
        }
    }
  }
}
