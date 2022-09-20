public without sharing class BoomFulfillmentHelper {
    public static String SCHEDULED_SUBSCRIPTION = 'Subscription Copies';
    public static String MAG_TYPE_ESSENTIAL_LIVING = 'Essential Living';

    public static void afterInsert(Map<Id, Fulfillment__c> newMap) {
        Map<Id, Fulfillment__c> subscriptionFulfillments = new Map<Id, Fulfillment__c>();
        Set<Id> fulfillmentProductLines = new Set<Id>();
        Set<String> subscriptionProductIds = new Set<String>();
        for(Fulfillment__c f : newMap.values()) {
            if(f.Set_Up_Subscription__c == true) {
                subscriptionFulfillments.put(f.Id, f);
                fulfillmentProductLines.add(f.Boom_Order_Product_Line__c);
                if(String.isNotEmpty(f.Subscription_Product__c)) {
                    subscriptionProductIds.add(f.Subscription_Product__c);
                }
            }
        }

        if(subscriptionFulfillments.size() > 0) {
            createSubscriptions(subscriptionFulfillments, fulfillmentProductLines, subscriptionProductIds);
        }
    }

    public static void createSubscriptions(Map<Id, Fulfillment__c> ffMap, Set<Id> prodLineIds, Set<String> subscriptionProductIds) {
        Map<Id, SalesOrderProductLine__c> prodLineMap = new Map<Id, SalesOrderProductLine__c>([
            SELECT Id,SalesOrder__r.Opportunity__c, ListPrice__c,Quantity__c,Name,SalesOrder__r.Release_Date__c, SalesOrder__r.Subscription__c,SalesOrder__r.Subscription__r.Name,SalesOrder__r.Subscription__r.Renewal_Date_Day_of_Month__c,SalesOrder__r.Subscription__r.Original_Subscription_Boom_Order__c,Product__c,Product__r.Renewal_Product__c,Product__r.Renewal_Frequency__c,
            SalesOrder__r.ContactBilling__c,SalesOrder__r.Name,Product__r.Base_Product__c,Product__r.Is_Subscription_Addon__c,Product__r.Magazine_Type__c,
            (SELECT Id, AccountManager__c,Recipient__c FROM Order_Line_Recipients__r WHERE Primary__c = true LIMIT 1)
            FROM SalesOrderProductLine__c
            WHERE Id IN :prodLineIds
        ]);

        Map<String,SalesOrderProductLine__c> subsProdMap = generateSubscriptionProductsMap(subscriptionProductIds, ffMap.keySet());


        Map<Id, Id> paymentMethodMap = generatePaymentMethodMap(ffMap);

        Map<Id,Subscription__c> soMap = new Map<Id,Subscription__c>();

        List<Subscription__c> subs = [
            SELECT Id, Original_Subscription_Boom_Order__c, Renewal_Date_Day_of_Month__c
            FROM Subscription__c
            WHERE Original_Subscription_Boom_Order__c IN (SELECT Boom_Order__c FROM Fulfillment__c WHERE Id IN :ffMap.keySet())
        ];

        for(Subscription__c s : subs) {
            soMap.put(s.Original_Subscription_Boom_Order__c, s);
        }


        List<Subscription__c> newSubscriptions = new List<Subscription__c>();
        List<Subscription__c> newAddons = new List<Subscription__c>();
        Integer dayOfMonth = (System.today()).day();

        for(Fulfillment__c ff : ffMap.values()) {
            SalesOrderProductLine__c prodLine = 
                String.isNotEmpty(ff.Subscription_Product__c) && subsProdMap.containsKey(ff.Boom_Order__c + ff.Subscription_Product__c) ?
                subsProdMap.get(ff.Boom_Order__c + ff.Subscription_Product__c) :
                prodLineMap.get(ff.Boom_Order_Product_Line__c);

            if(prodLine != null && prodLine.Order_Line_Recipients__r.size() > 0 && prodLine.Product__r.Renewal_Product__c != null) {
                Boolean hasSpecialSchedule = (prodLine.Product__r.Base_Product__c == SCHEDULED_SUBSCRIPTION) || test.isRunningTest();
                Boolean isEssential = prodLine.Product__r.Magazine_Type__c == MAG_TYPE_ESSENTIAL_LIVING;
                // add logic to determine if the subscription is a special schedule
                if(hasSpecialSchedule) {
                    dayOfMonth = isEssential && Order_Renewal_Schedule__mdt.getInstance('Universal_Renewal_date') != null
                        ? Integer.valueOf(Order_Renewal_Schedule__mdt.getInstance('Universal_Renewal_date').Renewal_Date__c)
                        : !isEssential && BiMonthly_Renewal_Schedule__mdt.getInstance('Universal_Renewal_date') != null
                        ? Integer.valueOf(BiMonthly_Renewal_Schedule__mdt.getInstance('Universal_Renewal_date').Renewal_Date__c)
                        : dayOfMonth;
                }
                
                Subscription__c sub = new Subscription__c();
                
                String subName = prodLine.SalesOrder__r.Name.replace('SO', 'SUB');

                if(prodLine.Product__r.Is_Subscription_Addon__c == true) {
                    subName = subName + '-ADDON-' + prodLine.Name;
                } 

                if(prodLine.SalesOrder__r.Subscription__c != null) {
                    sub.Original_Subscription_Boom_Order__c = prodLine.SalesOrder__r.Subscription__r.Original_Subscription_Boom_Order__c;
                    subName = prodLine.SalesOrder__r.Subscription__r.Name + '-ADDON-' + prodLine.Name;
                    sub.Parent_Subscription__c = prodLine.SalesOrder__r.Subscription__c;
                    dayOfMonth = Integer.valueOf(prodLine.SalesOrder__r.Subscription__r.Renewal_Date_Day_of_Month__c);
                } else if (soMap.containsKey(ff.Boom_Order__c)) {
                    sub.Original_Subscription_Boom_Order__c = ff.Boom_Order__c;        
                    sub.Parent_Subscription__c = soMap.get(ff.Boom_Order__c).Id;
                    dayOfMonth = Integer.valueOf(soMap.get(ff.Boom_Order__c).Renewal_Date_Day_of_Month__c);
                } 
                else {
                    sub.Original_Subscription_Boom_Order__c = ff.Boom_Order__c;
                }

                switch on ff.Status__c {
                    when 'On Hold', 'Subscription Paused' {
                        sub.Status__c = 'Paused';
                    }
                    when else {
                        sub.Status__c = 'Active';
                    }
                }

                sub.Name = subName;
                sub.Account_Manager__c = prodLine.Order_Line_Recipients__r[0].AccountManager__c;
                sub.Contact__c = prodLine.Order_Line_Recipients__r[0].Recipient__c;
                sub.Opportunity__c = prodLine.SalesOrder__r.Opportunity__c;
                sub.Payment_Method__c = paymentMethodMap.get(ff.Boom_Order__c);
                sub.Renewal_Date_Day_of_Month__c = '' + dayOfMonth;
                sub.Renewal_Frequency__c = prodLine.Product__r.Renewal_Frequency__c;
                sub.Renewal_Price__c = prodLine.ListPrice__c;
                sub.Renewal_Product__c = prodLine.Product__r.Renewal_Product__c;
                sub.Renewal_Quantity__c = prodLine.Quantity__c;
                sub.Start_Date__c = prodLine.SalesOrder__r.Release_Date__c;
                sub.Subscription_Fulfillment__c = ff.Id;
                newSubscriptions.add(sub);
            }
        }

        if(newSubscriptions.size() > 0) {
            // insert newSubscriptions;
            // System.enqueueJob(new BoomSubscriptionsQueuable(newSubscriptions, true, false));
            createNewSubscriptions(newSubscriptions);
        }

    }

    public static Map<String,SalesOrderProductLine__c> generateSubscriptionProductsMap(Set<String> subsProdsIds, Set<Id> ffIds) {
        if(subsProdsIds.size() < 1) {
            return new Map<String,SalesOrderProductLine__c>();
        }

        Map<String,SalesOrderProductLine__c> subsProdMap = new Map<String,SalesOrderProductLine__c>();
        List<SalesOrderProductLine__c> prodLines = [
            SELECT Id,SalesOrder__c,SalesOrder__r.Opportunity__c, SalesOrder__r.Subscription__r.Renewal_Date_Day_of_Month__c,Quantity__c,ListPrice__c,Name,SalesOrder__r.Release_Date__c, SalesOrder__r.Subscription__c,SalesOrder__r.Subscription__r.Name,SalesOrder__r.Subscription__r.Original_Subscription_Boom_Order__c,Product__c,Product__r.Renewal_Product__c,Product__r.Renewal_Frequency__c,
            SalesOrder__r.ContactBilling__c,SalesOrder__r.Name,Product__r.Base_Product__c,Product__r.Is_Subscription_Addon__c,Product__r.Magazine_Type__c,
            (SELECT Id, AccountManager__c,Recipient__c FROM Order_Line_Recipients__r WHERE Primary__c = true LIMIT 1)
            FROM SalesOrderProductLine__c
            WHERE Product__c IN :subsProdsIds
            AND SalesOrder__C IN (SELECT Boom_Order__c FROM Fulfillment__c WHERE Id IN :ffIds)
        ];

        if(prodLines.size() > 0) {
            for(SalesOrderProductLine__c prodLine : prodLines) {
                subsProdMap.put('' + prodLine.SalesOrder__c + prodLine.Product__c, prodLine);
            }

            return subsProdMap;
        } else {
            return new Map<String,SalesOrderProductLine__c>();
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


  public static void createNewSubscriptions(List<Subscription__c> subs) {
    insert subs;
  }
}