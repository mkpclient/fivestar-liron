global class SubscriptionStatusBatch implements Database.Batchable<sObject>,Database.Stateful{
    private String queryString;

    global SubscriptionStatusBatch() {
        if(String.isBlank(queryString)) {
            queryString = 'SELECT Id, End_Date__c, Re_Start_Date__c ';
            queryString += 'FROM Subscription__c ';
            queryString += 'WHERE (End_Date__c  <= TODAY AND Status__c != \'Cancelled\') ';
            queryString += 'OR (Re_Start_Date__c <= TODAY AND Status__c != \'Active\')';
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext info, List<Subscription__c> scope) {
        List<Subscription__c> updatedSubs = new List<Subscription__c>();

        for(Subscription__c sub : scope) {
            Date today = System.today();

            if(sub.End_Date__c <= today) {
                sub.Status__c = 'Cancelled';
            } else if(sub.Re_Start_Date__c <= today) {
                sub.Status__c = 'Active';
            }

            updatedSubs.add(sub);
        }

        if(updatedSubs.size() > 0) {
            Database.update(updatedSubs, false);
        }
    }

    global void finish(Database.BatchableContext info) {
        
    }
}