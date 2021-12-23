@isTest
private class OppContactDataTriggerTest {
  static testMethod void TestAccount() {
    Account acc = new Account();
    acc.Name = 'Test';
    insert acc;

    Contact c = new Contact();
    c.AccountId = acc.Id;
    c.LastName = 'Test';
    c.Client_Type__c = 'BD';
    insert c;

    Market__c market = new Market__c();
    market.Name = 'Test';
    market.Sales_Close__c = Date.today().AddDays(1);
    market.Market_Close_Date__c = Date.today().AddDays(1);
    insert market;
    string RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
      .get('Core - New Business')
      .getRecordTypeId();

    Opportunity opp = new Opportunity();
    opp.RecordTypeId = RecordTypeId;
    opp.AccountId = acc.Id;
    opp.Contact__c = c.Id;
    opp.Name = 'Test1';
    opp.StageName = 'Gold';
    opp.CloseDate = Date.Today();
    opp.Market_Project__c = market.Id;
    opp.Next_call_date__c = Date.Today();
    opp.Next_Call_Date_Time__c = Date.Today();
    // opp.Pardot_Campaign_Type__c = 'Core';
    //  opp.RecordTypeId =
    insert opp;
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
    test.starttest();
    // opp.Pardot_Campaign_Type__c = 'Post-market';
    opp.Next_Call_Date_Time__c = system.now().AddDays(1);
    update opp;
    event.forcebrain__StartDateTime__c = Date.today() + 1;
    update event;
    opp.Next_Call_Date_Time__c = null;
    update opp;
    opp.Next_Call_Date_Time__c = system.today().addDays(1);
    update opp;
    opp.StageName = 'NON PURCHASER - No Response';
    //opp.Client_Type__c = 'BD';
    opp.Sent_Buyer_No_Interest_Survey__c = false;
    //opp.Market_Sales_Stop_Date__c = system.today().addDays(1);
    update opp;
    delete opp;

    test.stoptest();
  }
}