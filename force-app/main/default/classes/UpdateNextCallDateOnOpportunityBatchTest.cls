@isTest(SeeAllData=true)
private class UpdateNextCallDateOnOpportunityBatchTest {
  static testMethod void TestUpdateNextCallDateOnOpportunityBatch() {
    Account acc = new Account();
    acc.Name = 'Test';
    insert acc;

    Contact c = new Contact();
    c.AccountId = acc.Id;
    c.LastName = 'Test';
    insert c;

    Market__c market = new Market__c();
    market.Name = 'Test';
    date d = date.today();
    market.Market_Close_Date__c = System.today().addDays(30);
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
    //  opp.Next_Call_Date_Time__c  = Date.Today();
    insert opp;
    test.starttest();
    String query = 'select id,Next_call_date__c, AG_link_no_price_MS__c,Market_Project__c, Contact__c from Opportunity where Contact__c In : setContactIds and Market_Project__r.Publication_Year__c =:year';
    Set<Id> setContactIds = new Set<Id>{ c.id };
    Map<Id, DateTime> mapConIdToStartDate = new Map<Id, DateTime>();
    mapConIdToStartDate.put(c.id, dateTime.now());
    UpdateNextCallDateOnOpportunityBatch oppNextCallDateBatch = new UpdateNextCallDateOnOpportunityBatch(
      query,
      mapConIdToStartDate,
      setContactIds,
      year
    );
    string batchId = Database.executeBatch(oppNextCallDateBatch);
    test.stoptest();
  }
}