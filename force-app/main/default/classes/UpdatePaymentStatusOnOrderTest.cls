/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class UpdatePaymentStatusOnOrderTest
{
/*
    @IsTest
    private static void testTrigger()
    {
        
         ntact();
       c.AccountId = acc.Id;
       c.LastName = 'Test';
       c.Client_Type__c = 'BD';Account acc = new Account();
       acc.Name ='Test';
       insert acc;
       
       Contact c = new Contact();
       insert c;
        
       Market__c market = new Market__c();
       market.Name = 'Test';
       market.Sales_Close__c = Date.today().AddDays(1);
       market.Market_Close_Date__c = Date.today().AddDays(1);
       insert market; 
       string RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core - New Business').getRecordTypeId();

      Test.startTest();        
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
       opp.Pardot_Campaign_Type__c = 'Core'; 
       insert opp; 
        
      kugo2p__SalesOrder__c ord = new kugo2p__SalesOrder__c();
        ord.kugo2p__Account__c = acc.Id;
        ord.kugo2p__Opportunity__c = opp.Id;
        insert ord;
        ord.Payment_Status__c = 'Completed';
        update ord;
      kugo2p__PaymentX__c pay =new kugo2p__PaymentX__c();  
       pay.kugo2p__Account__c = acc.Id;  
       pay.kugo2p__SalesOrder__c = ord.Id;
       pay.kugo2p__Status__c = 'Completed';
       insert pay;
       // pay.kugo2p__Status__c = 'Completed';
       // Update pay;  
       
        Test.stopTest();
        
    }*/
    
   @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_kugo2p_PaymentXTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new kugo2p__PaymentX__c());
    }         
}