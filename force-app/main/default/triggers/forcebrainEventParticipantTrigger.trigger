trigger forcebrainEventParticipantTrigger on forcebrain__EventParticipant__c(after insert,after update) {
  System.debug('force brain event participant trigger.');
  //system.debug('checkRecursive.isfromOpp==='+checkRecursive.isfromOpp);
  List<String> serviceTypes = new List<String>{ 'Five Star Certification Appointment', 'Five Star RE/MP/HA/RS Certification Appointment', 'Five Star WM/IP Certification Appointment' };
  if(!checkRecursive.isfromOpp)
  {
      system.debug('forcebrainEventParticipantTrigger>>trigger.New.size()>> '   + trigger.New.size()) ;
      system.debug('forcebrainEventParticipantTrigger ===='+trigger.New);
      Set<Id> setContactIds = new Set<Id>();
      Map<Id,DateTime> mapConIdToStartDate = new Map<Id,DateTime>();
      Map<Id,String> mapConIdToStatus = new Map<Id,String>();
      for(forcebrain__EventParticipant__c appPart:Trigger.New)
      {
          system.debug('Trigger.oldMap=='+Trigger.oldMap);
          if(Trigger.oldMap != null){
            forcebrain__EventParticipant__c oldevent = Trigger.oldMap.get(appPart.Id);
              if(oldevent.Cert_Deck_Url__c != appPart.Cert_Deck_Url__c){
                  continue;
              }
          }
          if(appPart.forcebrain__Customer__c != null) {
              setContactIds.add(appPart.forcebrain__Customer__c);
          }
        //   if(appPart.forcebrain__Start__c != null && appPart.forcebrain__Service_Name__c == 'Five Star Certification Appointment') { // mkp edit to include numerous different types
            if(appPart.forcebrain__Start__c != null && serviceTypes.contains(appPart.forcebrain__Service_Name__c)) {
              mapConIdToStartDate.put(appPart.forcebrain__Customer__c,appPart.forcebrain__Start__c);
              mapConIdToStatus.put(appPart.forcebrain__Customer__c,appPart.Status__c); 
           }
      }
      system.debug('mapConIdToStartDate=='+mapConIdToStartDate);
       system.debug('mapConIdToStatus=='+mapConIdToStatus);
      system.debug('setContactIds=='+setContactIds);  
      if(mapConIdToStartDate != null && mapConIdToStartDate.size()>0)
      {
          system.debug('mapConIdToStartDate=='+mapConIdToStartDate);  
          string RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core - New Business').getRecordTypeId();
          date d = date.today(); 
          String year = String.ValueOf(d.Year());
          String query = 'select id,Next_call_date__c, Next_Call_Date_Time__c ,Contact__c, Market_Project__r.Publication_Year__c from Opportunity where Contact__c In : setContactIds';
          List<Opportunity> lstOpp = [select id,Next_call_date__c, Next_Call_Date_Time__c, Cert_Deck_Url__c,Contact__c, Market_Project__r.Publication_Year__c from Opportunity where Contact__c In : setContactIds and RecordTypeId =: RecordTypeId ORDER BY CreatedDate DESC LIMIT 1];
         // and Market_Project__r.Publication_Year__c =:year, and RecordTypeId == RecordTypeId
          system.debug('lstOpp=='+lstOpp);  
          for(Opportunity opp:lstOpp)
          {
              if(mapConIdToStartDate.containsKey(opp.Contact__c))
               {
                   String status = mapConIdToStatus.get(opp.Contact__c); 
                   system.debug('status =='+status );
                    DateTime dt = mapConIdToStartDate.get(opp.Contact__c);
                  /*  Timezone tz = Timezone.getTimeZone('America/Chicago');
                      integer offset = tz.getOffset(dt);
                      system.debug(tz.getOffset(dt));   //offset value in milliseconds
                      Datetime cstDatetime = dt.addSeconds(offset/1000);  */
                    if(dt!=null )          
                       //  opp.Next_call_date__c = date.newinstance(cstDatetime.year(), cstDatetime.month(), cstDatetime.day());
                        opp.Next_call_date__c = date.newinstance(dt.year(), dt.month(), dt.day());
                      //  opp.Next_Call_Date_Time__c = cstDatetime;
                       //reverting back the 1 hour email reminder code
                        opp.Next_Call_Date_Time__c = dt; 
                    if(status == 'Canceled')
                    {
                        opp.Next_Call_Date_Time__c = null;
                    }
                    
              }
          }
          if(lstOpp.size()>0)
            forcebrain.SumoProvider.disableForcebrainTriggerForSObject(Opportunity.sObjectType, true);
             update lstOpp;  
            forcebrain.SumoProvider.disableForcebrainTriggerForSObject(Opportunity.sObjectType, false);
          //UpdateNextCallDateOnOpportunityBatch oppNextCallDateBatch = new UpdateNextCallDateOnOpportunityBatch(query,mapConIdToStartDate,setContactIds,year);
          //string batchId = Database.executeBatch(oppNextCallDateBatch,1);
      }
 }

}