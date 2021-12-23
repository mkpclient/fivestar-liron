@isTest
private class Send1hourpriorreminderEmailTest {
  static testMethod void TestAccount() {
    Account acc = new Account();
    acc.Name = 'Test';
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
    opp.Contact__c = c.Id;
    opp.Name = 'Test1';
    opp.StageName = 'Gold';
    opp.CloseDate = Date.Today();
    opp.Market_Project__c = market.Id;
    opp.Next_call_date__c = Date.Today();
    // opp.Pardot_Campaign_Type__c = 'Core';
    opp.Next_Call_Date_Time__c = Date.Today();
    insert opp;

    forcebrain__Event__c event = new forcebrain__Event__c();
    event.forcebrain__StartDateTime__c = Date.today();
    event.forcebrain__EndDateTime__c = Date.today() + 2;
    insert event;

    forcebrain__EventParticipant__c ab = new forcebrain__EventParticipant__c();
    ab.forcebrain__Customer__c = c.Id;
    ab.forcebrain__Event__c = event.Id;
    ab.forcebrain__Appointment_Start_Date_Time__c = Date.today();
    insert ab;

    test.starttest();
    // opp.Pardot_Campaign_Type__c = 'Post-market';
    //opp.Next_Call_Date_Time__c = system.now().AddDays(1);
    //update opp;
    Send1hourpriorreminderEmail sendemail = new Send1hourpriorreminderEmail(
      new List<Id>{ opp.Id }
    );
    String sch = '0 0 2 * * ?';

    System.schedule(
      'Test Territory Check',
      sch,
      new Send1hourpriorreminderEmail(new List<Id>{ opp.Id })
    );
    
    test.stoptest();
  }
}