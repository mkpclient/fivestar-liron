@isTest
private class TestOpportunityEmailAfterOneHr
{

    static testmethod void schedulerTest() 
    {
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        Account acc = new Account();
       acc.Name ='Test';
       insert acc;
       
       Contact c = new Contact();
       c.AccountId = acc.Id;
       c.LastName = 'Test';
       c.Client_Type__c = 'BD';
       c.Email = 'test123@gmail.com';
       insert c;
        
       Market__c market = new Market__c();
       market.Name = 'Test';
       market.Sales_Close__c = Date.today().AddDays(1);
       market.Market_Close_Date__c = system.today().addDays(1);
       insert market; 
       string RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core - New Business').getRecordTypeId();

        
       Opportunity opp = new Opportunity();
       opp.RecordTypeId = RecordTypeId;
       opp.AccountId = acc.Id;
       opp.Contact__c= c.Id;
       opp.Name = 'Test1';
       opp.StageName = 'Gold';
       opp.CloseDate = Date.Today();
       opp.Market_Project__c = market.Id;
       opp.Next_call_date__c = Date.Today();
       opp.Next_Call_Date_Time__c= Date.Today();
    //    opp.Pardot_Campaign_Type__c = 'Core';
       
     //  opp.RecordTypeId = 
       insert opp; 
        
        Test.startTest();

        String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new OpportunityEmailAfterOneHr(new List<Id>{opp.Id}));
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();        
    }
}