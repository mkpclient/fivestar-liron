public without sharing class ContactTriggerForTaxesHelper {

    public static void afterUpdate(Map<Id, Contact> oldMap, Map<Id, Contact> newMap) {
        Map<Id, Contact> contactsWithNewStates = new Map<Id, Contact>();

        for(Contact c : newMap.values()) {
            if(oldMap.get(c.Id).MailingState != c.MailingState) {
                contactsWithNewStates.put(c.Id, c);
            }
        }
        
        if(contactsWithNewStates.size() > 0) {
            updateSoplStateTaxes(contactsWithNewStates);
        }
    }

    public static void updateSoplStateTaxes(Map<Id, Contact> ctMap) {
        List<SalesOrderProductLine__c> sopls = [
            SELECT Id,ContactShipping__c
            FROM SalesOrderProductLine__c
            WHERE ContactShipping__c IN :ctMap.keySet()
        ];

        for(SalesOrderProductLine__c sopl : sopls) {
            Contact c = ctMap.get(sopl.ContactShipping__c);
            if(c != null) {
                if(Sales_Tax__mdt.getInstance(c.MailingState) != null) {
                    sopl.State_Tax_Rate__c = Sales_Tax__mdt.getInstance(c.MailingState).Rate__c;
                } else {
                    sopl.State_Tax_Rate__c = 0;
                }
            }
        }

        update sopls;
    }
}
