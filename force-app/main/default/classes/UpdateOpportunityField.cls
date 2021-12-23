global class UpdateOpportunityField implements Database.Batchable<sObject> {
  public String query;
  global set<string> setOppIds;

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<sObject> scope) {
    List<Opportunity> lstOpp = new List<Opportunity>();
    for (SObject s : scope) {
      Opportunity opp = (Opportunity) s;
      if (!String.isBlank(opp.Market_Project__c)) {
        // opp.Pardot_Campaign_Type__c = 'Core';
        lstOpp.add(opp);
      }
      //s.put('Market_Project__c', s.get('Market_Project__c'));
      //s.put('Pardot_Campaign_Type__c','Core');
    }
    if (!Test.isRunningTest() && lstOpp.size() > 0) {
      update lstOpp;
    }
  }

  global void finish(Database.BatchableContext BC) {
  }
}