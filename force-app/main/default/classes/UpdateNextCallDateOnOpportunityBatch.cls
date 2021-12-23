global class UpdateNextCallDateOnOpportunityBatch implements Database.Batchable<sObject>{

   global final String Query;
   global final Map<Id,DateTime> mapConIdToStartDate;
   global set<Id> setContactIds;
   global final String year; 
  

   global UpdateNextCallDateOnOpportunityBatch(String q, Map<Id,DateTime> mapCIdToStartDate,set<Id> conIds,String y){

      Query=q; mapConIdToStartDate = mapCIdToStartDate;setContactIds = conIds;year = y;
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<Opportunity> scope){
     for(Opportunity s : scope){
           if(mapConIdToStartDate.containsKey(s.Contact__c))
           {
              DateTime dt = mapConIdToStartDate.get(s.Contact__c);  
              if(dt!=null )          
                  s.Next_call_date__c = date.newinstance(dT.year(), dT.month(), dT.day());
                  s.Next_Call_Date_Time__c = dt;
          }
     }
     update scope;
    }

   global void finish(Database.BatchableContext BC){
   }
}