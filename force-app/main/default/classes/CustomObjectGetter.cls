public class CustomObjectGetter{
    public List<Research_Call__c> getResearch_Call() {
        String account_id = ApexPages.currentPage().getParameters().
        get('AccountId');
        return [SELECT Id, Name, Due_Date__c, Research_Rep__c, Call_Type__c, Call_Result__c, Comments__c FROM Research_Call__c
        WHERE Candidate__c = :account_id LIMIT 100];
    }
}