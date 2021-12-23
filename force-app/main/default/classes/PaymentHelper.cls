public with sharing class PaymentHelper {
    public static void afterInsert(List<kugo2p__PaymentX__c> newList) {
        System.debug('after insert');
        updatePaymentsIfApproved(newList);
    }
    
    /*
        method will touch payment records in order to force an update on it's parent order
        fixes the error that orders are not refelcting the released status after a payment is made
    */
    public static void updatePaymentsIfApproved(List<kugo2p__PaymentX__c> newList) {
        List<kugo2p__PaymentX__c> paymentsToUpdate = new List<kugo2p__PaymentX__c>();
    
        Set<Id> orderIds = new Set<Id>();
    
        for (Integer i = 0; i < newList.size(); i++) {
            if (newList[i].kugo2p__SalesOrder__c != null) {
                orderIds.add(newList[i].kugo2p__SalesOrder__c);
            }
        }
    
        Map<Id, kugo2p__SalesOrder__c> orderMap = new Map<Id, kugo2p__SalesOrder__c>([SELECT Id, AM_Status__c FROM kugo2p__SalesOrder__c WHERE Id IN :orderIds]);

        List<kugo2p__PaymentX__c> firstUpdate = new List<kugo2p__PaymentX__c>();

        Map<String, String> paymentToOrder = new Map<String, String>();
        for (kugo2p__PaymentX__c p : newList) {
            if (p.kugo2p__SalesOrder__c != null) {
                paymentToOrder.put(p.id, orderMap.get(p.kugo2p__SalesOrder__c).Id);
               kugo2p__PaymentX__c wipedPayment = new kugo2p__PaymentX__c();
                wipedPayment.Id = p.id;
                wipedPayment.kugo2p__SalesOrder__c = null;
                firstUpdate.add(wipedPayment);
            }
        }

        if (firstUpdate.size() > 0) {
            update firstUpdate;
            
            for (kugo2p__PaymentX__c p : firstUpdate) {
                if (paymentToOrder.containsKey(p.Id)) {
                    p.kugo2p__SalesOrder__c = paymentToOrder.get(p.Id);
                }
            }
    
            update firstUpdate;
        }


        // for (kugo2p__PaymentX__c p : newList) {
        //     if (orderMap.containsKey(p.kugo2p__SalesOrder__c) && orderMap.get(p.kugo2p__SalesOrder__c).AM_Status__c == 'Approved') {
        //         kugo2p__PaymentX__c newPayment = new kugo2p__PaymentX__c();
        //         newPayment.id = p.id;

        //         paymentsToUpdate.add(newPayment);
        //     }
        // }
    
        // if (paymentsToUpdate.size() > 0) {
        //     System.debug('updating payments');
        //     update paymentsToUpdate;
        // }

        String x = 'a';
        String y = 'a';
        String z = 'a';
        String a = 'a';
    }
}