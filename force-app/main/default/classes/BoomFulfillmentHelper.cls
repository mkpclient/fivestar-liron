public without sharing class BoomFulfillmentHelper {
    public static void afterInsert(Map<Id, Fulfillment__c> newMap) {
        Map<Id, Fulfillment__c> subscriptionFulfillments = new Map<Id, Fulfillment__c>();
        Set<Id> fulfillmentProductLines = new Set<Id>();
        for(Fulfillment__c f : newMap.values()) {
            if(f.Subscription__c == true) {
                subscriptionFulfillments.put(f.Id, f);
                fulfillmentProductLines.add(f.Boom_Order_Product_Line__c);
            }
        }

        if(subscriptionFulfillments.size() > 0) {
            createSubscriptions(subscriptionFulfillments, fulfillmentProductLines);
        }
    }

    public static void createSubscriptions(Map<Id, Fulfillment__c> ffMap, Set<Id> prodLineIds) {
        Map<Id, SalesOrderProductLine__c> prodLineMap = new Map<Id, SalesOrderProductLine__c>([
            SELECT Id,Product__c,Product__r.Renewal_Product__c,Product__r.Renewal_Frequency__c,
            SalesOrder__r.ContactBilling__c,
            (SELECT Id, AccountManager__c,Recipient__c FROM Order_Line_Recipients__r WHERE Primary__c = true LIMIT 1)
            FROM SalesOrderProductLine__c
            WHERE Id IN :prodLineIds
        ]);



        Map<Id, Id> paymentMethodMap = generatePaymentMethodMap(ffMap);

        List<Subscription__c> newSubscriptions = new List<Subscription__c>();
        Integer dayOfMonth = (System.today()).day();
        
        for(Fulfillment__c ff : ffMap.values()) {
            SalesOrderProductLine__c prodLine = prodLineMap.get(ff.Boom_Order_Product_Line__c);

            if(prodLine != null && prodLine.Order_Line_Recipients__r.size() > 0) {
                Subscription__c sub = new Subscription__c();
                sub.Account_Manager__c = prodLine.Order_Line_Recipients__r[0].AccountManager__c;
                sub.Contact__c = prodLine.Order_Line_Recipients__r[0].Recipient__c;
                sub.Original_Subscription_Boom_Order__c = ff.Boom_Order__c;
                sub.Payment_Method__c = paymentMethodMap.get(ff.Boom_Order__c);
                sub.Renewal_Date_Day_of_Month__c = '' + dayOfMonth;
                sub.Renewal_Frequency__c = prodLine.Product__r.Renewal_Frequency__c;
                sub.Renewal_Price__c = ff.Gross_Price__c;
                sub.Renewal_Product__c = prodLine.Product__r.Renewal_Product__c;
                sub.Renewal_Quantity__c = ff.Quantity__c;
                sub.Start_Date__c = System.today();
                sub.Status__c = 'Active';
                sub.Subscription_Fulfillment__c = ff.Id;
                newSubscriptions.add(sub);
            }
        }

        if(newSubscriptions.size() > 0) {
            insert newSubscriptions;
        }        
    }
    
    public static Map<Id,Id> generatePaymentMethodMap(Map<Id, Fulfillment__c> ffMap) {
        Map<Id,Id> finalMap = new Map<Id,Id>();

        for(Payment__c p : [
            SELECT Sales_Order__c, Payment_Method__c
            FROM Payment__c
            WHERE Payment_Method__c != null
            AND Status__c = 'Completed'
            AND Sales_Order__c IN (
                SELECT Boom_Order__c FROM Fulfillment__c
                WHERE Id IN :ffMap.keySet()
            )
        ]) {
            finalMap.put(p.Sales_Order__c, p.Payment_Method__c);
        }

        return  finalMap;
    }

}
