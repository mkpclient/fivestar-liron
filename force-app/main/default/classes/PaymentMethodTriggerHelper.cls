public with sharing class PaymentMethodTriggerHelper {
    public static void beforeInsert(List<Payment_Method__c> newList) {
        for(Payment_Method__c pm : newList) {
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
    }
}