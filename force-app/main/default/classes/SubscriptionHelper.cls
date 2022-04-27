public without sharing class SubscriptionHelper {
    public static final String SO_FIELDS = 'OrderDate__c,OrderName__c,Market__c,Opportunity__c,Account__c,Price_Book__c,ContactBilling__c,ContactBuying__c,ContactShipping__c,BillToName__c,BillToCity__c,BillToCountry__c,BillToStateProvince__c,BillToStreetLong__c,BillToZipPostalCode__c,ShipToCity__c,ShipToCountry__c,ShipToName__c,ShipToStateProvince__c,ShipToStreetLong__c,ShipToZipPostalCode__c';
    
    public static void beforeInsert(List<Subscription__c> newList) {
        Map<String,Integer> subNames = new Map<String,Integer>();

        for(Subscription__c s : newList) {
            if(subNames.containsKey(s.Name)) {
                Integer currentCount = subNames.get(s.Name);
                String oldName = s.Name;
                currentCount++;
                s.Name = s.Name + '-' + currentCount;
                subNames.put(oldName, currentCount);
            } else {
                subNames.put(s.Name, 0);
            }
        }
    }
    
    public static void afterInsert(Map<Id, Subscription__c> newMap) {
        Map<Id,Subscription__c> subscriptions = new Map<Id, Subscription__c>();
        List<Subscription__c> addons = new List<Subscription__c>();

        for(Subscription__c s : newMap.values()) {
            if(!s.Name.contains('-ADDON-')) {
                subscriptions.put(s.Original_Subscription_Boom_Order__c, s);
            } else {
                addons.add(s);
            } 
        }
        
        if(addons.size() > 0) {
            
            Map<Id, Subscription__c> forUpdate = new Map<Id,Subscription__c>([SELECT Id,Original_Subscription_Boom_Order__c,Parent_Subscription__c FROM Subscription__c WHERE Id IN :addons]);
            for(Subscription__c s : forUpdate.values()) {
                if(s.Parent_Subscription__c == null && subscriptions.containsKey(s.Original_Subscription_Boom_Order__c)) {
                    s.Parent_Subscription__c = subscriptions.get(s.Original_Subscription_Boom_Order__c).Id;
                }
                forUpdate.put(s.Id, s);
            }

            if(forUpdate.size() > 0) {
               update forUpdate.values();
            }
        }

        if(subscriptions.size() > 0 || addons.size() > 0) {
            createSubscriptionOrders(subscriptions.values(), addons);
        }
    }

    public static void beforeUpdate(Map<Id,Subscription__c> oldMap, Map<Id,Subscription__c> newMap) {
        List<Subscription__c> forNewOrders = new List<Subscription__c>();
        List<Subscription__c> newAddons = new List<Subscription__c>();
        for(Id key : newMap.keySet()) {
            Subscription__c n = newMap.get(key);
            Subscription__c o = oldMap.get(key);
            if(n.Create_Next_Subscription__c && n.Create_Next_Subscription__c != o.Create_Next_Subscription__c && n.Status__c == 'Active') {
                if(n.Parent_Subscription__c != null) {
                    newAddons.add(n);
                } else {
                    forNewOrders.add(n);
                }
                n.Create_Next_Subscription__c = false;
            } else if (n.Create_Next_Subscription__c && n.Status__c != 'Active') {
                n.Create_Next_Subscription__c = false;
            }
             
            if (o.Status__c == 'Paused' && n.Status__c =='Active') {
                n.Re_Start_Date__c = System.today();
                if(n.Parent_Subscription__c != null) {
                    newAddons.add(n);
                } else {
                    forNewOrders.add(n);
                }
                n.Create_Next_Subscription__c = false;
            }
            
            if (o.Status__c != n.Status__c && n.Status__c == 'Cancelled') {
                n.Cancelled_Date__c = System.today();
            }

            if(o.Status__c != n.Status__c && n.Status__c == 'Paused') {
                n.Pause_Date__c = System.today();
            }

            
        }

        if(forNewOrders.size() > 0 || newAddons.size() > 0) {
            createSubscriptionOrders(forNewOrders, newAddons);
        }
    }

    public static void afterUpdate(Map<Id,Subscription__c> oldMap, Map<Id,Subscription__c> newMap) {
        List<Fulfillment__c> fulfillmentsForUpdate = new List<Fulfillment__c>();
        Set<Id> cancelledSubscriptions = new Set<Id>();
        for(Subscription__c n : newMap.values()) {
            Subscription__c o = oldMap.get(n.Id);
            
            if(n.Status__c != o.Status__c && n.Status__c == 'Cancelled') {
                if(n.Subscription_Fulfillment__c != null) {
                    Fulfillment__c f = new Fulfillment__c(
                        Id = n.Subscription_Fulfillment__c,
                        Status__c = 'Subscription Cancelled'
                    );
                    fulfillmentsForUpdate.add(f);
                }
                cancelledSubscriptions.add(n.Id);
            }
        }

        if(fulfillmentsForUpdate.size() > 0) {
            update fulfillmentsForUpdate;
        }

        
        if(cancelledSubscriptions.size() > 0) {
            Approval.lock(new List<Id>(cancelledSubscriptions));
            cancelPendingOrders(cancelledSubscriptions);
        }
    }
    
    public static void cancelPendingOrders(Set<Id> subIds) {
        List<SalesOrder__c> orders = [
            SELECT Id
            FROM SalesOrder__c
            WHERE Subscription__c IN :subIds
            AND Status_Picklist__c = 'Pending Renewal'
            FOR UPDATE
        ];

        if(orders.size() > 0) {
            for(SalesOrder__c o : orders) {
                o.Status_Picklist__c = 'Subscription Cancelled';
            }
            update orders;
            Approval.lock(orders);
        }
    }

    public static void createSubscriptionOrders(List<Subscription__c> subscriptions, List<Subscription__c> addons) {
    System.enqueueJob(new BoomSubscriptionsQueuable(subscriptions, false, addons));
    }

    // public static void createSubscriptionOrders(List<Subscription__c> subscriptions) {
    //     String queryString = 'SELECT ' + SO_FIELDS + ' FROM SalesOrder__c WHERE Id IN (SELECT Original_Subscription_Boom_Order__c FROM Subscription__c WHERE Id IN :subscriptions)';
    //     Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>((List<SalesOrder__c>) Database.query(queryString));
    //     Map<Id, SalesOrder__c> newSalesOrders = new Map<Id, SalesOrder__c>();
    //     Map<Id, SalesOrderProductLine__c> newSalesOrderProductLines = new Map<Id, SalesOrderProductLine__c>();
    //     Map<Id, Order_Line_Recipient__c> newOrderLineRecipients = new Map<Id, Order_Line_Recipient__c>();

    //     for(Subscription__c sub : subscriptions) {
    //         Integer day = Integer.valueOf(sub.Renewal_Date_Day_of_Month__c);
    //         Integer month = System.today().month() + 1;
    //         Integer year = System.today().year();
    //         if(sub.Renewal_Frequency__c == 'Annual') {
    //             month = System.today().month();
    //             year = System.today().year() + 1;
    //         }
    //         Date orderDate = date.newInstance(year, month, day);
    //         SalesOrder__c newSo = generateSubscriptionOrder(salesOrderMap.get(sub.Original_Subscription_Boom_Order__c), sub, orderDate);
    //         SalesOrderProductLine__c sopl = generateSubscriptionProductLine(sub,orderDate,newSo);
    //         Order_Line_Recipient__c recipient = generateSubscriptionLineRecipient(sub, newSo);
    //         newSalesOrders.put(sub.Id, newSo);
    //         newSalesOrderProductLines.put(sub.Id, sopl);
    //         newOrderLineRecipients.put(sub.Id, recipient);
    //     }

    //     insert newSalesOrders.values();

    //     for(Id subId : newSalesOrders.keySet()) {
    //         SalesOrder__c so = newSalesOrders.get(subId);
    //         SalesOrderProductLine__c sopl = newSalesOrderProductLines.get(subId);
    //         Order_Line_Recipient__c olr = newOrderLineRecipients.get(subId);
    //         sopl.SalesOrder__c = so.Id;
    //         newSalesOrderProductLines.put(subId, sopl);
    //         newOrderLineRecipients.put(subId, olr);
    //     }

    //     insert newSalesOrderProductLines.values();

    //     List<Order_Line_Recipient__c> recipients = [
    //         SELECT Id, Order__r.Subscription__c FROM Order_Line_Recipient__c WHERE Order__r.Subscription__c IN :subscriptions
    //     ];

    //     for(Order_Line_Recipient__c r : recipients) {
    //         String key = r.Order__r.Subscription__c;
    //         Order_Line_Recipient__c olr = newOrderLineRecipients.get(key);
    //         olr.Id = r.Id;
    //         newOrderLineRecipients.put(key, olr);
    //     }

    //     update newOrderLineRecipients.values();
    // }

    // public static SalesOrder__c generateSubscriptionOrder(SalesOrder__c so, Subscription__c sub, Date orderDate) {
    //     SalesOrder__c newSo = so.clone(false, true, false, false);
    //     newSo.Id = null;
    //     newSo.Subscription__c = sub.Id;
    //     newSo.OrderDate__c = orderDate;
    //     newSo.Status_Picklist__c = 'Pending Renewal';
    //     return newSo;
    // }

    // public static SalesOrderProductLine__c generateSubscriptionProductLine(Subscription__c sub, Date orderDate, SalesOrder__c so) {
    //     SalesOrderProductLine__c sopl = new SalesOrderProductLine__c();
    //     sopl.Quantity__c = sub.Renewal_Quantity__c;
    //     sopl.SalesPrice__c = sub.Renewal_Price__c;
    //     sopl.ListPrice__c = sub.Renewal_Price__c;
    //     sopl.DateRequired__c = orderDate;
    //     sopl.Product__c = sub.Renewal_Product__c;
    //     sopl.ContactShipping__c = so.ContactShipping__c;
    //     sopl.DateAvailableToPromise__c = orderDate;
    //     return sopl;
    // }

    // public static Order_Line_Recipient__c generateSubscriptionLineRecipient(Subscription__c sub, SalesOrder__c so) {
    //     Order_Line_Recipient__c olr = new Order_Line_Recipient__c();
    //     olr.AccountManager__c = sub.Account_Manager__c;
    //     olr.Market__c = so.Market__c;
    //     olr.Primary__c = true;
    //     olr.Recipient__c = sub.Contact__c;
    //     return olr;
    // }
    
}