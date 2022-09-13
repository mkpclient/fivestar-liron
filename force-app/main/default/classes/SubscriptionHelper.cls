public without sharing class SubscriptionHelper {
    public static final String SO_FIELDS = 'OrderDate__c,OrderName__c,Market__c,Opportunity__c,Account__c,Price_Book__c,ContactBilling__c,ContactBuying__c,ContactShipping__c,BillToName__c,BillToCity__c,BillToCountry__c,BillToStateProvince__c,BillToStreetLong__c,BillToZipPostalCode__c,ShipToCity__c,ShipToCountry__c,ShipToName__c,ShipToStateProvince__c,ShipToStreetLong__c,ShipToZipPostalCode__c';
    public static String SCHEDULED_SUBSCRIPTION = 'Subscription Copies';
    public static String MAG_TYPE_ESSENTIAL_LIVING = 'Essential Living';

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
            if(!s.Name.contains('-ADDON-') && !s.Name.contains('-DISC-')) {
                subscriptions.put(s.Original_Subscription_Boom_Order__c, s);
            } else {
                addons.add(s);
            } 
        }
        
        if(addons.size() > 0) {
            
            Map<Id, Subscription__c> forUpdate = new Map<Id,Subscription__c>([SELECT Id,End_Date__c,Name,Original_Subscription_Boom_Order__c,Parent_Subscription__c FROM Subscription__c WHERE Id IN :addons AND Parent_Subscription__c = null]);
            Map<Id,Subscription__c> subsToUpdate = new Map<Id,Subscription__c>();
            Map<Id, Subscription__c> forAssignment = new Map<Id,Subscription__c>();

            for(Subscription__c s : forUpdate.values()) {
                if(s.Parent_Subscription__c == null && subscriptions.containsKey(s.Original_Subscription_Boom_Order__c)) {
                    s.Parent_Subscription__c = subscriptions.get(s.Original_Subscription_Boom_Order__c).Id;
                    s.Renewal_Date_Day_of_Month__c = subscriptions.get(s.Original_Subscription_Boom_Order__c).Renewal_Date_Day_of_Month__c;
                    subsToUpdate.put(s.Id, s);
                } else if (s.Parent_Subscription__c == null && !subscriptions.containsKey(s.Original_Subscription_Boom_Order__c)) {
                    forAssignment.put(s.Id, s);
                }
            }

            if(forAssignment.size() > 0) {
                Map<Subscription__c, List<Subscription__c>> reassignedAddons = assignMissingParents(forAssignment);
                for(List<Subscription__c> subList : reassignedAddons.values()) {
                    for(Subscription__c s : subList) {
                        subsToUpdate.put(s.Id, s);
                    }
                }
            }

            if(subsToUpdate.size() > 0) {
               update subsToUpdate.values();
            }
        }
        

        if(subscriptions.size() > 0) {
            List<Subscription__c> newAddons = createRecurringAddon(subscriptions.values());
            if(newAddons.size() > 0) {
                insert newAddons;
                addons.addAll(newAddons);
            }
        }

        if(subscriptions.size() > 0 || addons.size() > 0) {
            createSubscriptionOrders(subscriptions.values(), addons);
            // createRecurringAddon(subscriptions.values());
        }
    }


    public static List<Subscription__c> createRecurringAddon(List<Subscription__c> subscriptions) {
        System.debug('createRecurringAddon run');
        List<Subscription__c> addOnList = new List<Subscription__c>();

        List<SalesOrderProductLine__c> prodLines = [
            SELECT Id,ListPrice__c,Quantity__c,Name,SalesOrder__c,SalesOrder__r.Release_Date__c,Product__c,
            SalesOrder__r.ContactBilling__c,SalesOrder__r.Name,Product__r.Recurring_Discount__c, Product__r.Discount_Frequency__c, Product__r.Discount_Occurences__c,
            (SELECT Id, AccountManager__c,Recipient__c FROM Order_Line_Recipients__r WHERE Primary__c = true LIMIT 1)
            FROM SalesOrderProductLine__c
            WHERE SalesOrder__c IN 
            (SELECT Original_Subscription_Boom_Order__c FROM Subscription__c WHERE Id IN : subscriptions) 
            AND Product__r.Recurring_Discount__c = true
        ];

        // select name, Original_Subscription_Boom_Order__c, id from subscription__c where parent_subscription__c in :subscriptions and name like '%-disc-%'
        // map<string,id> prodLineNamesToSoIdMap = new map<string, id>();
        // loop through the discount subscriptions we just queried 
        // string name = discSub.Name.substringAfter('-DISC-');
        // prodLineNamesToSoIdMap.put(name, discSub.Original_Subscription_Boom_Order__c)
        List<Subscription__c> discountSubscriptions = [
            SELECT Name, Original_Subscription_Boom_Order__c, Id 
            FROM Subscription__c 
            WHERE Parent_Subscription__c in :subscriptions AND Name LIKE '%-DISC-%'
        ];
        Map<String,Id> prodLineNamesToSoIdMap = new Map<String,Id>();
        for(Subscription__c discSub : discountSubscriptions) {
            String name = discSub.Name.substringAfter('-DISC-');
            prodLineNamesToSoIdMap.put(name, discSub.Original_Subscription_Boom_Order__c);
        }

        Map<Id, List<SalesOrderProductLine__c>> prodLineMap = new Map<Id, List<SalesOrderProductLine__c>>();

        for(SalesOrderProductLine__c line : prodLines) {
            // if (prodLineNamesToSoIdMap.containsKey(line.Name) && line.SalesOrder__c == prodLineNamesToSoIdMap.get(line.Name)) { continue; }
            if(prodLineNamesToSoIdMap.containsKey(line.Name) && line.SalesOrder__c == prodLineNamesToSoIdMap.get(line.Name)) {
                continue;
            }
            
            if(prodLineMap.containsKey(line.SalesOrder__c)) {
                List<SalesOrderProductLine__c> lines = prodLineMap.get(line.SalesOrder__c);
                lines.add(line);
                prodLineMap.put(line.SalesOrder__c, lines);
            }else {
                prodLineMap.put(line.SalesOrder__c, new List<SalesOrderProductLine__c>{line});
            }
            
        }


        for(Subscription__c sub : subscriptions) {
            if(prodLineMap.containsKey(sub.Original_Subscription_Boom_Order__c)) {

                Integer day = Integer.valueOf(sub.Renewal_Date_Day_of_Month__c);
      
                Integer month = System.today().month() < 12
                    ? System.today().month() + 1
                    : 1;
                
                if(day > System.today().day()) {
                    month = System.today().month();
                }

                Boolean hasSpecialSchedule =
                sub.Base_Product__c == SCHEDULED_SUBSCRIPTION &&
                ((sub.Start_Date__c.month() == System.today().month() && 
                sub.Start_Date__c.year() == System.today().year()));
            
                Boolean isEssentialLiving = sub.Magazine_Type__c == MAG_TYPE_ESSENTIAL_LIVING;
                // add logic to determine if the subscription is a special schedule
                Date startFullDate =  sub.Start_Date__c;
                Integer startMonth = startFullDate.month();
                Integer startDate = startFullDate.day();
                Integer startYear = startFullDate.year();
          
                if (hasSpecialSchedule && isEssentialLiving) {
                    Map<String,Order_Renewal_Schedule__mdt> schedules = Order_Renewal_Schedule__mdt.getAll();
            
                    for(Order_Renewal_Schedule__mdt sched : schedules.values()) {
                      Date schedStartDate = Date.newInstance(startYear, Integer.valueOf(sched.Start_Month__c), Integer.valueOf(sched.Start_Date__c));
                      Date schedEndDate = Date.newInstance(startYear, Integer.valueOf(sched.End_Month__c), Integer.valueOf(sched.End_Date__c));
                      if(sched.End_Month__c < sched.Start_Month__c) {
                        schedEndDate.addYears(1);
                      }

                      if(schedStartDate <= startFullDate && schedEndDate >= startFullDate) {
                        day = Integer.valueOf(sched.Renewal_Date__c);
                        month = Integer.valueOf(sched.Renewal_Month__c);
                      }
                    }
                  } else if (hasSpecialSchedule && !isEssentialLiving) {
                    Map<String, BiMonthly_Renewal_Schedule__mdt> schedules = BiMonthly_Renewal_Schedule__mdt.getAll();
                    // Map<DeveloperName, metadata values> 
                    for(BiMonthly_Renewal_Schedule__mdt sched : schedules.values()) {
                      Date schedStartDate = Date.newInstance(startYear, Integer.valueOf(sched.Start_Month__c), Integer.valueOf(sched.Start_Date__c));
                      Date schedEndDate = Date.newInstance(startYear, Integer.valueOf(sched.End_Month__c), Integer.valueOf(sched.End_Date__c));
                      if(sched.End_Month__c < sched.Start_Month__c) {
                        schedEndDate.addYears(1);
                      }

                      if(schedStartDate <= startFullDate && schedEndDate >= startFullDate) {
                        day = Integer.valueOf(sched.Renewal_Date__c);
                        month = Integer.valueOf(sched.Renewal_Month__c);
                      }
                    }
                  }

                Integer year = month < System.today().month()
                ? System.today().year() + 1
                : System.today().year();

                for(SalesOrderProductLine__c line : prodLineMap.get(sub.Original_Subscription_Boom_Order__c)) {
                    Subscription__c newSub = new Subscription__c();
                    Integer numOccurences = Integer.valueOf(line.Product__r.Discount_Occurences__c);
                    Date endDate = Date.newInstance(year, month, day).addMonths(numOccurences-1).addDays(-1);
                    // 21 -- July 21, 2022 
                    // 7 - July 7, 2022 - already released
                    // 7 - Aug 7, 2022
                    // Renewal_Date_Day_of_Month__c > current date ? Date.newInstance(current Year, current Month, Renewal_Date_Day_of_Month__c).addMonths(numOccurences-1).addDays(-1) : Date.newInstance(current Year, current Month, Renewal_Date_Day_of_Month__c).addMonths(numOccurences).addDays(-1);
                    newSub.End_Date__c = endDate;
                    newSub.Start_Date__c = sub.Start_Date__c; // for assigning missing parent, this will be today's date
                    String subName = sub.Name + '-DISC-' + line.Name;
                    newSub.Name = subName;
                    newSub.Parent_Subscription__c = sub.Id;
                    newSub.Original_Subscription_Boom_Order__c = sub.Original_Subscription_Boom_Order__c; // we don't reassign this when assigning missing parents
                    newSub.status__c = 'Active';
                    newSub.Payment_Method__c = sub.Payment_Method__c;
                    newSub.Account_Manager__c = line.Order_Line_Recipients__r[0].AccountManager__c;
                    newSub.Contact__c = line.Order_Line_Recipients__r[0].Recipient__c;
                    newSub.Renewal_Product__c = line.Product__c;
                    newSub.Renewal_Price__c = line.ListPrice__c;
                    newSub.Renewal_Frequency__c = sub.Renewal_Frequency__c;
                    newsub.Renewal_Quantity__c = line.Quantity__c;
                    newSub.Renewal_Date_Day_of_Month__c = sub.Renewal_Date_Day_of_Month__c;
                    addOnList.add(newSub);
                }   
            }
        }

        return addOnList;
    }
    

    public static void beforeUpdate(Map<Id,Subscription__c> oldMap, Map<Id,Subscription__c> newMap) {
        List<Subscription__c> forNewOrders = new List<Subscription__c>();
        List<Subscription__c> newAddons = new List<Subscription__c>();

        Set<Id> restartedSubs = new Set<Id>();

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
                n.Create_Next_Subscription__c = false;
                restartedSubs.add(n.Id);
            }
            
            if (o.Status__c != n.Status__c && n.Status__c == 'Cancelled') {
                n.Cancelled_Date__c = System.today();
            }

            if(o.Status__c != n.Status__c && n.Status__c == 'Paused') {
                n.Pause_Date__c = System.today();
            }

            
        }

        Map<Id,Subscription__c> restartedMap = new Map<Id,Subscription__c>([
            SELECT Id, (SELECT Id FROM Boom_Orders__r WHERE Status_Picklist__c = 'Pending Renewal' AND OrderDate__c >= TODAY LIMIT 1)
            FROM Subscription__c WHERE Id IN :restartedSubs OR Parent_Subscription__c IN :restartedSubs
        ]);

        for(Subscription__c n : newMap.values()) {
            Subscription__c fromMap = new Subscription__c();
            Id key = n.Id;
            if(n.Parent_Subscription__c != null) {
                key = n.Parent_Subscription__c;
            }
            if(restartedMap.containsKey(key)) {
                fromMap = restartedMap.get(key);
                if(fromMap.Boom_Orders__r == null || fromMap.Boom_Orders__r.size() == 0) {
                    if(n.Parent_Subscription__c != null) {
                        newAddons.add(n);
                    } else {
                        forNewOrders.add(n);
                    }
                }
            }
        }

        if(forNewOrders.size() > 0 || newAddons.size() > 0) {
            createSubscriptionOrders(forNewOrders, newAddons);
        }
    }

    public static void afterUpdate(Map<Id,Subscription__c> oldMap, Map<Id,Subscription__c> newMap) {
        List<Fulfillment__c> fulfillmentsForUpdate = new List<Fulfillment__c>();
        Set<Id> cancelledSubscriptions = new Set<Id>();
        Map<Id,Subscription__c> pausedSubscriptions = new Map<Id,Subscription__c>();
        Map<Id,Subscription__c> quantityChanged = new Map<Id,Subscription__c>();
        for(Subscription__c n : newMap.values()) {
            Subscription__c o = oldMap.get(n.Id);

            if(n.Renewal_Quantity__c != o.Renewal_Quantity__c) {
                quantityChanged.put(n.Id, n);
            }
            
            if(n.Status__c != o.Status__c && n.Status__c == 'Cancelled') {
                if(n.Subscription_Fulfillment__c != null) {
                    Fulfillment__c f = new Fulfillment__c(
                        Id = n.Subscription_Fulfillment__c,
                        Status__c = 'Subscription Cancelled'
                    );
                    fulfillmentsForUpdate.add(f);
                }

                if(n.Parent_Subscription__c == null) {
                    cancelledSubscriptions.add(n.Id);
                }

            }
            if(o.Re_Start_Date__c != n.Re_Start_Date__c && n.Status__c == 'Paused' && n.Parent_Subscription__c == null) {
                pausedSubscriptions.put(n.Id, n);
            }

        }

        if(fulfillmentsForUpdate.size() > 0) {
            update fulfillmentsForUpdate;
        }

        if (quantityChanged.size() > 0) {
            updateFulfillmentQuantity(quantityChanged);
        }

        if(pausedSubscriptions.size() > 0) {
            updatePausedOrdersAndAddons(pausedSubscriptions);
        }

        
        if(cancelledSubscriptions.size() > 0) {
            Approval.lock(new List<Id>(cancelledSubscriptions));
            cancelPendingOrders(cancelledSubscriptions);
            cancelChildrensubscriptions(cancelledSubscriptions);
        }
    }

    public static void updatePausedOrdersAndAddons(Map<Id,Subscription__c> subMap) {
        
        List<SalesOrder__c> ordersForUpdate = [
            SELECT Id, OrderDate__c, Subscription__c
            FROM SalesOrder__c
            WHERE Subscription__c IN :subMap.keySet()
            AND Status_Picklist__c = 'Pending Renewal'
            FOR UPDATE
        ];

        List<Subscription__c> addonsForUpdate = [
            SELECT Id, Parent_Subscription__c
            FROM Subscription__c
            WHERE Parent_Subscription__c IN :subMap.keySet()
            AND (Status__c != 'Paused' OR Status__c != 'Cancelled')
            FOR UPDATE
        ];

        if(addonsForUpdate.size() > 0) {
            for(Subscription__c s : addonsForUpdate) {
                s.Status__c = 'Paused';
                s.Re_Start_Date__c = subMap.get(s.Parent_Subscription__c).Re_Start_Date__c;
            }

            update addonsForUpdate;
        }

        if(ordersForUpdate.size() > 0) {
            for(SalesOrder__c s : ordersForUpdate) {
                Subscription__c sub = subMap.get(s.Subscription__c);
                Integer newDate = s.OrderDate__c.day();
                Integer newMonth = sub.Re_Start_Date__c.day() < newDate ? sub.Re_Start_Date__c.month() : sub.Re_Start_Date__c.month() + 1;
                Integer newYear = sub.Re_Start_Date__c.month() <= newMonth ? sub.Re_Start_Date__c.year() : sub.Re_Start_Date__c.year() + 1;
                Integer daysInMonth = date.daysInMonth(newYear, newMonth);

                if(newDate > daysInMonth) {
                    newDate = daysInMonth;
                }

                s.OrderDate__c = date.newInstance(newYear, newMonth, newDate);
            }

            update ordersForUpdate;
        }
        

    }
    
    public static void cancelPendingOrders(Set<Id> subIds) {
        List<String> statuses = new List<String>{
            'Pending Renewal',
            'Payment Update Needed'
        };
        List<SalesOrder__c> orders = [
            SELECT Id
            FROM SalesOrder__c
            WHERE Subscription__c IN :subIds
            AND Status_Picklist__c IN : statuses
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
    
    
    public static void cancelChildrensubscriptions(Set<Id> subIds) {
        List<Subscription__c> addonSubs = [
            SELECT Id, Status__c FROM Subscription__c WHERE Parent_Subscription__c IN:subIds AND Status__c != 'Cancelled' FOR UPDATE
        ];

        if(addonSubs.size() > 0) {
            for(Subscription__c s : addonSubs) {
                s.Status__c = 'Cancelled';
            }
            update addonSubs;
        }
    }

    public static void createSubscriptionOrders(List<Subscription__c> subscriptions, List<Subscription__c> addons) {
    System.enqueueJob(new BoomSubscriptionsQueuable(subscriptions, false, addons));
    }

    public static void updateFulfillmentQuantity(Map<Id,Subscription__c> subsMap) {
        

        Map<Id, SalesOrder__c> soMap = new Map<Id,SalesOrder__c>([
            SELECT Id, (SELECT Id, Renewal_Quantity__c,Name,Renewal_Product__r.Related_Fulfillment_Product__c FROM Subscriptions__r WHERE Id IN :subsMap.keySet())
            FROM SalesOrder__c
            WHERE Id IN (SELECT Original_Subscription_Boom_Order__c FROM Subscription__c WHERE Id IN :subsMap.keySet())
        ]);

        List<Fulfillment__c> fulfillments = [
            SELECT Id,EL_Quantity__c,Boom_Order__c,Boom_Order_Product_Line__c,Boom_Order_Product_Line__r.Product__c
            FROM Fulfillment__c
            WHERE Boom_Order__c IN :soMap.keySet()
        ];

        List<Fulfillment__c> forUpdate = new List<Fulfillment__c>();
        for(Fulfillment__c f : fulfillments) {
            SalesOrder__c so = soMap.get(f.Boom_Order__c);
            if(so.Subscriptions__r != null && so.Subscriptions__r.size() > 0 && so.Subscriptions__r[0].Renewal_Product__r.Related_Fulfillment_Product__c == f.Boom_Order_Product_Line__r.Product__c) {
                forUpdate.add(new Fulfillment__c(
                    Id= f.Id,
                    EL_Quantity__c = so.Subscriptions__r[0].Renewal_Quantity__c
                ));
            }
        }
        update forUpdate;
    }

    public static Map<Subscription__c, List<Subscription__c>> assignMissingParents(Map<Id,Subscription__c> subsMap) {
        List<SalesOrder__c> salesOrders = [
            SELECT Id, Opportunity__c,
            (SELECT Id, Name, End_Date__c, Original_Subscription_Boom_Order__r.Opportunity__c FROM Subscriptions__r WHERE Id IN :subsMap.keySet())
            FROM SalesOrder__c
            WHERE Id IN (
                SELECT Original_Subscription_Boom_Order__c FROM Subscription__c WHERE Id IN :subsMap.keySet()
            )
            AND Status_Picklist__c = 'Released'
        ];

        Map<Id, List<Subscription__c>> oppToSubMap = new Map<Id,List<Subscription__c>>();

        for(SalesOrder__c so : salesOrders) {
            List<Subscription__c> subs = so.Subscriptions__r;
            oppToSubMap.put(so.Opportunity__c, subs);
        }
        Set<Id> oppIds = oppToSubMap.keySet();

        Map<String, String> labelMap = new Map<String, String>();
        Schema.DescribeSObjectResult objectDescribe  = Subscription__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<String> fieldNames = new List<String>(fieldMap.keySet());
        String queryString = 'SELECT ' + String.join(fieldNames, ',') + ', Original_Subscription_Boom_Order__r.Opportunity__c,';
        queryString += '(SELECT Id, OrderDate__c FROM Boom_Orders__r WHERE Status_Picklist__c = \'Pending Renewal\' OR Status_Picklist__c = \'Payment Update Needed\' ORDER BY OrderDate__c ASC LIMIT 1)';
        queryString += ' FROM Subscription__c WHERE Original_Subscription_Boom_Order__r.Opportunity__c IN ';
        queryString += ' :oppIds AND Original_Subscription_Boom_Order__c NOT IN :salesOrders';
        queryString += ' AND Parent_Subscription__c = null AND (NOT NAME LIKE \'%addon%\') AND (NOT NAME LIKE \'%disc%\')';

        List<Subscription__c> parentSubs = database.query(queryString);
        Map<Subscription__c,List<Subscription__c>> forUpdate = new Map<Subscription__c,List<Subscription__c>>();

        for(Subscription__c sub : parentSubs) {
            if(oppToSubMap.containsKey(sub.Original_Subscription_Boom_Order__r.Opportunity__c)) {
                List<Subscription__c> children = new List<Subscription__c>();
                for(Subscription__c addon : oppToSubMap.get(sub.Original_Subscription_Boom_Order__r.Opportunity__c)) {
                    Subscription__c addonSub = new Subscription__c(
                        Id = addon.Id,
                        Renewal_Date_Day_of_Month__c = sub.Renewal_Date_Day_of_Month__c,
                        Parent_Subscription__c = sub.Id
                    );

                    if(addon.Name.containsIgnoreCase('-disc-')) {
                        // for end date, use sub.Boom_Orders__r[0].OrderDate__c  (then use same logic from the original method)
                        addonSub.Start_Date__c = System.today();
                        addonSub.Payment_Method__c = sub.Payment_Method__c;
                        System.debug(JSON.serializePretty(sub));
                        //Renewal_Date_Day_of_Month__c > current date ? Date.newInstance(current Year, current Month, Renewal_Date_Day_of_Month__c).addMonths(numOccurences-1).addDays(-1) : Date.newInstance(current Year, current Month, Renewal_Date_Day_of_Month__c).addMonths(numOccurences).addDays(-1);
                        Date oldEndDate = addon.End_Date__c;
                        Integer numOccurences = oldEndDate.month() - System.today().month() + 1;
                        Integer renewalDay = Integer.valueOf(sub.Renewal_Date_Day_of_Month__c);
                        Date nextRenewalDate = sub.Boom_Orders__r != null && sub.Boom_Orders__r.size() > 0 ? sub.Boom_Orders__r[0].OrderDate__c : Date.newInstance(System.today().year(), System.today().month(), renewalDay).addMonths(1);

                        addonSub.End_Date__c = renewalDay > System.today().day() ? Date.newInstance(nextRenewalDate.year(), nextRenewalDate.month(), renewalDay).addMonths(numOccurences).addDays(-1) : Date.newInstance(nextRenewalDate.year(), nextRenewalDate.month(), renewalDay).addMonths(numOccurences - 1).addDays(-1);
                        // other discount fields
                    }

                    children.add(addonSub);
                }
                forUpdate.put(sub, children);
            }
        }

        return forUpdate;

    }
    
}