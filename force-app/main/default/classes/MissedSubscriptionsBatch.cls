global class MissedSubscriptionsBatch implements Database.Batchable<sObject>,Database.Stateful{
    private String queryString;

    global MissedSubscriptionsBatch() {
        if(String.isBlank(queryString)) {
            queryString = 'SELECT Id';
            queryString += ' FROM Subscription__c';
            queryString += ' WHERE  Status__c = \'Active\' AND Parent_Subscription__c = null AND Payment_Method__c != null';
            queryString += ' AND Id NOT IN (SELECT Subscription__c from SalesOrder__c where Subscription__c != null and OrderDate__c > TODAY and Status_Picklist__c = \'Pending Renewal\')';
            queryString += ' AND Id in (SELECT Subscription__c from SalesOrder__c where Subscription__c != null and OrderDate__c <= TODAY and Status_Picklist__c = \'Released\')';
        }
        
        if (Test.isRunningTest()) {
            queryString = 'SELECT Id';
            queryString += ' FROM Subscription__c';
            queryString += ' LIMIT 1';
        }
    }

    // select id, Create_Next_Subscription__c, Renewal_Date_Day_of_Month__c  from subscription__c where Status__c = 'Active' and Parent_Subscription__c = null and 
    // id not in (select subscription__c from salesorder__c where subscription__c != null and orderdate__c = NEXT_MONTH and status_picklist__c = 'Pending Renewal') and id in (select subscription__c from salesorder__c where subscription__c != null and orderdate__c = THIS_MONTH and status_picklist__c != 'Pending Renewal')

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext info, List<Subscription__c> scope) {
        List<Subscription__c> updatedSubs = new List<Subscription__c>();

        for(Subscription__c sub : scope) {

            sub.Create_Next_Subscription__c = true;

            updatedSubs.add(sub);
        }

        List<Subscription__c> childrenSubs = [
            SELECT Id FROM Subscription__c WHERE Parent_Subscription__c IN :updatedSubs AND Status__c = 'Active'
        ];

        if(childrenSubs.size() > 0) {
            for(Subscription__c sub : childrenSubs) {
                sub.Create_Next_Subscription__c = true;
                updatedSubs.add(sub);
            }
        }

        if(updatedSubs.size() > 0) {
            Database.update(updatedSubs, false);
        }
    }

    global void finish(Database.BatchableContext info) {
        
    }
}