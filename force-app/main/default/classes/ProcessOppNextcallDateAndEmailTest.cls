@isTest
Private class ProcessOppNextcallDateAndEmailTest {

static testMethod void TestProcessOppNextcallDateAndEmail ()
    {
       Account acc = new Account();
       acc.Name ='Test';
       insert acc;
       
       Contact c = new Contact();
       c.AccountId = acc.Id;
       c.LastName = 'Test';
       insert c;
        
       Market__c market = new Market__c();
       market.Name = 'Test';
       market.Market_Close_Date__c = System.today().addDays(30);
       insert market; 
        
       Opportunity opp = new Opportunity();
       opp.AccountId = acc.Id;
       opp.Contact__c= c.Id;
       opp.Name = 'Test1';
       opp.StageName = 'Gold';
       opp.CloseDate = Date.Today();
       opp.Market_Project__c = market.Id;
       opp.Next_call_date__c = Date.Today();
    //    opp.Pardot_Campaign_Type__c = 'Core'; 
       opp.Next_Call_Date_Time__c =  system.now().addHours(2);
       insert opp; 
        
       
        
         test.starttest();
        Send1hourEmailSchedule sendemail = new Send1hourEmailSchedule();
        
		System.schedule('Send1hourEmailSchedule' + System.now().getTime(), '0 0 * * * ?', new Send1hourEmailSchedule() );
      
        ProcessOppNextcallDateAndEmail b = new ProcessOppNextcallDateAndEmail(); 
        database.executebatch(b);
        test.stoptest();
        
      
    }
}