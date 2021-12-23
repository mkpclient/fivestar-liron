@isTest
private class forcebrainEventParticipantTriggerTest {
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
    market.Market_Close_Date__c = Date.today().AddDays(1);

    date d = date.today();
    String year = String.ValueOf(d.Year());
    market.Publication_Year__c = year;
    insert market;

    Opportunity opp = new Opportunity();
    opp.AccountId = acc.Id;
    opp.Contact__c = c.Id;
    opp.Name = 'Test1';
    opp.StageName = 'Gold';
    opp.CloseDate = Date.Today();
    opp.Market_Project__c = market.Id;
    opp.Next_call_date__c = Date.Today();
    opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core - New Business').getRecordTypeId();

    insert opp;

    System.debug('opportunity stage name before we query it fresh => ' + opp.StageName);

    forcebrain__Event__c event = new forcebrain__Event__c();
    event.forcebrain__StartDateTime__c = Date.today();
    event.forcebrain__EndDateTime__c = Date.today() + 2;
    event.forcebrain__Service_Text__c = 'Five Star Certification Appointment';
    insert event;
    
    forcebrain__EventParticipant__c ab = new forcebrain__EventParticipant__c();
    ab.forcebrain__Customer__c = c.Id;
    ab.forcebrain__Event__c = event.Id;
    ab.forcebrain__Appointment_Start_Date_Time__c = Date.today();
    insert ab;

    ab.forcebrain__Appointment_Start_Date_Time__c = Date.today() + 1;
    update ab;
    test.starttest();
    opp.Next_call_date__c = Date.Today() + 2;
    update opp;

    test.stoptest();
  }
}