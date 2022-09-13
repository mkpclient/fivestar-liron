public without sharing class PaymentMethodTriggerHelper {
    private static final Map<Id,User> GUEST_USERS = new Map<Id,User>([
        SELECT Id FROM User WHERE Name LIKE '%Guest User%'
    ]);
    public static void beforeInsert(List<Payment_Method__c> newList) {
        for(Payment_Method__c pm : newList) {
            if(GUEST_USERS.keySet().contains(pm.CreatedById)) {
                pm.Default__c = true;
            }
            if(String.isEmpty(pm.Payment_Processor__c)) {
                pm.Payment_Processor__c = 'MX Merchant';
            }
        }
    }


    public static void afterInsert(List<Payment_Method__c> newList) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> triggerIds = new Set<Id>();

        for(Payment_Method__c pm : newList) {
            if(pm.Default__c == true) {
                contactIds.add(pm.Contact__c);
                triggerIds.add(pm.Id);
            }
        }
        unsetDefaults(contactIds, triggerIds);
    }

    public static void afterUpdate(Map<Id, Payment_Method__c> oldMap, Map<Id, Payment_Method__c> newMap) {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> triggerIds = new Set<Id>();


        for(Id key: newMap.keySet()) {
            Payment_Method__c oldPm = oldMap.get(key);
            Payment_Method__c newPm = newMap.get(key);
            if(newPm.Default__c != oldPm.Default__c && newPm.Default__c == true) {
                contactIds.add(newPm.Contact__c);
                triggerIds.add(newPm.Id);
            }
        }

        unsetDefaults(contactIds, triggerIds);
    }

    public static void afterDelete(List<Payment_Method__c> oldList) {
       
    }

    static void unsetDefaults(Set<Id> contactIds, Set<Id> triggerIds) {
        List<Payment_Method__c> existingPms = [
            SELECT Id, Default__c 
            FROM Payment_Method__c 
            WHERE Id NOT IN :triggerIds
            AND Contact__c IN :contactIds 
            AND Default__c=true
        ];

        if(existingPms.size() > 0) {
            for(Payment_Method__c pm : existingPms) {
                pm.Default__c = false;
            }

            update existingPms;
            
            
        }
        updatePaymentMethods(contactIds);
    }

    @future
    public static void updatePaymentMethods(Set<Id> contactIds) {
        Map<Id,Contact> contactMap = new Map<Id,Contact>([
            SELECT Id, (SELECT Id FROM Payment_Methods__r WHERE Default__c = true ORDER BY CreatedDate DESC LIMIT 1)
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        List<Subscription__c> subscriptions = [
            SELECT Id, Payment_Method__r.Contact__c
            FROM Subscription__c
            WHERE Payment_Method__r.Contact__c IN :contactIds
            AND Override_Default_Payment_Method__c = false
            AND Status__c != 'Cancelled'
            AND Payment_Method__r.Default__c = false
        ];

        List<Payment__c> payments = [
            SELECT Id, Payment_Method__c, Payment_Method__r.Contact__c
            FROM Payment__c
            WHERE Payment_Method__r.Contact__c IN :contactIds
            AND Status__c = 'Scheduled'
            AND Payment_Method__r.Default__c = false
        ];

        List<Payment__c> updatedPayments = new List<Payment__c>();
        List<Subscription__c> updatedSubscriptions = new List<Subscription__c>();

        for(Subscription__c sub : subscriptions) {
            Contact c = contactMap.get(sub.Payment_Method__r.Contact__c);
            if(c.Payment_Methods__r != null && c.Payment_Methods__r.size() > 0) {
                updatedSubscriptions.add(new Subscription__c(
                    Id = sub.Id,
                    Payment_Method__c =  c.Payment_Methods__r[0].Id
                ));
            }
        }

        for(Payment__c pay : payments) {
            Contact c = contactMap.get(pay.Payment_Method__r.Contact__c);
            if(c.Payment_Methods__r != null && c.Payment_Methods__r.size() > 0) {
                updatedPayments.add(new Payment__c(
                    Id = pay.Id,
                    Payment_Method__c =  c.Payment_Methods__r[0].Id
                ));
            }
        }

        if(updatedPayments.size() > 0) {
            update updatedPayments;
        }

        if(updatedSubscriptions.size() > 0) {
            update updatedSubscriptions;
        }

    }
    
}