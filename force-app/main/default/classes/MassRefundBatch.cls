global class MassRefundBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful {
    global String queryString;
    global List<Id> contactIds;
    
    global MassRefundBatch(List<Id> contactIds) {
        this.contactIds = contactIds;
        if (String.isBlank(queryString)) {
            queryString = 'SELECT Id, Order_Name__c, Billing_Name__c, Payment_Method__r.MX_Customer_Id__c, Payment_Method__c, Contact__c, Account__c, Amount__c, ';
            queryString += 'Sales_Order__c, Date__c, Payment_Token__c, MX_Payment_Id__c, Transaction_Id__c, Authorization_Id__c ';
            queryString += 'FROM Payment__c ';
            if(!test.isRunningTest()) {
                queryString += 'WHERE CreatedDate = N_DAYS_AGO:3 ';
            } else {
                queryString += 'WHERE CreatedDate = TODAY ';
            }
            queryString += 'AND Contact__c IN :contactIds ';
            queryString += 'AND Status__c = \'Completed\'';
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext info, List<Payment__c> scope) {
        List<Payment__c> newManualPayments = new List<Payment__c>();
        for(Payment__c p : scope) {
            Payment__c newPayment = new Payment__c(
                Payment_Method__c = p.Payment_Method__c,
                Account__c = p.Account__c,
                Amount__c = p.Amount__c,
                Sales_Order__c = p.Sales_Order__c,
                Contact__c = p.Contact__c,
                Date__c = p.Date__c,
                Payment_Type__c = 'Credit Card',
                Status__c = 'Completed',
                Payment_Processor__c = 'MX Merchant',
                Name = 'Payment for Sales Order ' + p.Order_Name__c,
                Billing_Name__c = p.Billing_Name__c
            );

            newManualPayments.add(newPayment);
            Zealynx.PaymentResource pr = new Zealynx.PaymentResource();
            pr.paymentToken = p.Payment_Token__c;
            pr.amount = 0 - p.Amount__c;
            pr.customerId = long.valueOf(p.Payment_Method__r.MX_Customer_Id__c);
            Map<String,Object> res = Zealynx.refundPayment(pr);

            Zealynx.PaymentResource retPr = (Zealynx.PaymentResource)res.get('payment');
            if(retPr.status != 'Approved') {
                continue;
            }

            Payment__c refundRecord = new Payment__c(
                Sales_Order__c = p.Sales_Order__c,
                Status__c = 'Completed',
                Amount__c = retPr.amount,
                Contact__c = p.Contact__c,
                Account__c = p.Account__c,
                Date__c = System.today(),
                Payment_Method__c = p.Payment_Method__c,
                Payment_Token__c = retPr.paymentToken,
                Transaction_Type__c = 'Refund',
                Payment_Type__c = 'Credit Card',
                MX_Payment_Id__c = String.valueOf(retPr.id),
                Transaction_Id__c = String.valueOf(retPr.reference),
                Authorization_Id__c = String.valueOf(retPr.authCode),
                // RelatedPayment__c = p.Id,
                Payment_Processor__c = 'MX Merchant',
                Name = 'Payment for Sales Order ' + p.Order_Name__c,
                Billing_Name__c = p.Billing_Name__c
            );
            newManualPayments.add(refundRecord);
        }

        System.enqueueJob(new BoomSubscriptionPaymentsQueuable(newManualPayments, false));
    }

    global void finish(Database.BatchableContext info) {

    }


}
