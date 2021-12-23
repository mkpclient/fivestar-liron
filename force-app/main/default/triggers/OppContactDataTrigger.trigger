trigger OppContactDataTrigger on Opportunity (before insert,before update,after insert ,after update,before delete) {
    //system.debug('OppContactDataTrigger>>trigger.New.size()>> '   + trigger.New.size()) ; 
    Map<String, Object> params = new Map<String, Object>();
    if(trigger.IsBefore && Trigger.IsDelete)
    {
        Map<String,String> mapJobNameToJobId = getJobMap();
        system.debug('mapJobNameToJobId=='+mapJobNameToJobId);

        for(Opportunity opp:trigger.old)
        {
            //System.debug('mapJobNameToJobId.ContainsKey(opp.Id)=='+mapJobNameToJobId.ContainsKey(opp.Id));
                       
            if(opp.Next_Call_Date_Time__c !=null && mapJobNameToJobId != null &&  mapJobNameToJobId.ContainsKey(opp.Next_Call_Date_Time__c.format()))
            {
                system.abortJob(mapJobNameToJobId.get(opp.Next_Call_Date_Time__c.format()));
            }
        }
    }
    if(trigger.IsBefore && !Trigger.IsDelete)
    {
        string RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Core - New Business').getRecordTypeId();

        Map<String,String> mapJobNameToJobId = getJobMap();
        //system.debug('mapJobNameToJobId=='+mapJobNameToJobId);
        Set<DateTime> setNextCallDate = new Set<DateTime>();
        List<Opportunity> lstCoreOpps = new List<Opportunity>();
        List<Opportunity> lstOppsToSendEmail = new List<Opportunity>();
        List<Id> lstoppIds = new List<id>();
        for(Opportunity opp:trigger.New)
        {
            
            System.debug('opp.StageName==' + opp.StageName);
            System.debug('opp.Pardot_Campaign_Type__c==' + opp.Pardot_Campaign_Type__c);
            System.debug('opp.Sent_Buyer_No_Interest_Survey__c ==' + opp.Sent_Buyer_No_Interest_Survey__c );
            System.debug('opp.Market_Sales_Stop_Date__c ==' + opp.Market_Sales_Stop_Date__c );
            System.debug('opp.Date==' + (opp.Market_Sales_Stop_Date__c >= date.Today()) );
         
           /* if(((opp.StageName== 'NON PURCHASER - No Response' || opp.StageName == 'NON PURCHASER - Not Interested' || opp.StageName== 'Dead -- Cert Appt Target Calls Made' || opp.StageName == 'Dead - Connected but did not agree to Cert') && (opp.Client_Type__c== 'BD' || opp.Client_Type__c== 'BDP' || opp.Client_Type__c== 'BP') 
            && opp.Sent_Buyer_No_Interest_Survey__c == false && (opp.Market_Sales_Stop_Date__c >= date.Today())  && (Opp.RecordTypeId == RecordTypeId)) || (opp.StageName== 'Dead - Market Closed' && opp.Market_Sales_Stop_Date__c < date.Today() && (opp.Client_Type__c== 'BD' || opp.Client_Type__c== 'BDP' || opp.Client_Type__c== 'BP')  && opp.Sent_Buyer_No_Interest_Survey__c == false) */
            if(((opp.StageName== 'NON PURCHASER - No Response' || opp.StageName == 'NON PURCHASER - Not Interested' || opp.StageName== 'Dead -- Cert Appt Target Calls Made' || opp.StageName == 'Dead - Connected but did not agree to Cert') 
            && (opp.Client_Type__c== 'BD' || opp.Client_Type__c== 'BDP' || opp.Client_Type__c== 'BP') 
            && (opp.Sent_Buyer_No_Interest_Survey__c == false) && (opp.Market_Sales_Stop_Date__c >= date.Today()) && (Opp.RecordTypeId == RecordTypeId))                    
            || ((opp.StageName== 'Dead - Market Closed') && (opp.Market_Sales_Stop_Date__c < date.Today())
            && (opp.Client_Type__c== 'BD' || opp.Client_Type__c== 'BDP' || opp.Client_Type__c== 'BP')  
            && (opp.Sent_Buyer_No_Interest_Survey__c == false) && (Opp.RecordTypeId == RecordTypeId))) {
                opp.Sent_Buyer_No_Interest_Survey__c = true;
                System.Debug('Sent Buyer Flag ===' + opp.Sent_Buyer_No_Interest_Survey__c);
                lstoppIds.add(opp.Id); 
                lstOppsToSendEmail.add(opp); 
            } 
            params = new Map<String, Object>();   
            if(trigger.IsBefore && opp.Pardot_Campaign_Type__c != null && opp.Pardot_Campaign_Type__c != 'Core' && opp.Pardot_Campaign_Type__c != 'Post-market')
            {
               params.put('originatingOpp', opp);
               //TriggerHandler.OppContactFlow(params);  
               //Flow.Interview.Opp_Contact_Data oppContactData= new Flow.Interview.Opp_Contact_Data(params);
                //oppContactData.start();  
            }
            else
            {
                lstCoreOpps.add(opp); 
            }
            if(Trigger.isUpdate)
            {
                Opportunity oldOpp = trigger.oldMap.get(opp.Id);
                if(opp.Next_Call_Date_Time__c == null && oldOpp.Next_Call_Date_Time__c != null)
                {
                    if(mapJobNameToJobId != null && mapJobNameToJobId.ContainsKey(oldOpp.Next_Call_Date_Time__c.format()))
                    {
                        system.abortJob(mapJobNameToJobId.get(oldOpp.Next_Call_Date_Time__c.format()));
                        
                        //setNextCallDate.add(opp.Next_Call_Date_Time__c);                        
                    }  
                }
            }               
        }
        if(lstCoreOpps.size()>0)
        {
            OppContactDataTriggerHelper.updateContactFromOpp(lstCoreOpps);
        }
        if(lstOppsToSendEmail.size()>0)
        {
            abortOpportunitySendEmailCompetedJobs();
            DateTime todayDate = Datetime.now().addHours(1);
            String scheduleName = 'OpportunitySendEmail ' + System.now().format('mm/dd/yyyy') + string.valueOf(todayDate.second()) + '&'+ lstoppIds[0];
           
            String sch = todayDate.second() + ' ' + todayDate.minute() + ' '+ todayDate.hour() + ' ' + todayDate.day() + ' ' + todayDate.month() + ' ? ' + '  ' + todayDate.year();
             //String sch = todayDate.second() + ' ' +  todayDate.minute() +  ' ' + todayDate.hour()  + ' ? * * *';
            String jobID = System.schedule(scheduleName, sch,new OpportunityEmailAfterOneHr(lstoppIds));
           // OppContactDataTriggerHelper.sendEmail(lstOppsToSendEmail(lstoppIds));
        }
        
      
         
    }
    if(trigger.IsAfter)
    {
        Map<String,Opportunity> mapConIdToOpportunity = new Map<String,Opportunity>();        
        for(Opportunity opp:trigger.New)
        {
            if(opp.Next_Call_Date_Time__c != null)
            {
               mapConIdToOpportunity.put(opp.Contact__c,opp); 
            }
                 
        }
        
        List<forcebrain__EventParticipant__c> lstForceBrain = [select id,forcebrain__Appointment_Start_Date_Time__c,Cert_Deck_Url__c,forcebrain__Customer__c from forcebrain__EventParticipant__c where forcebrain__Customer__c =:mapConIdToOpportunity.keySet()];
        List<forcebrain__EventParticipant__c> lstForceBrainToUpdate = new List<forcebrain__EventParticipant__c>();
        system.debug('lstForceBrain =='+lstForceBrain );
        for(forcebrain__EventParticipant__c forceBrain : lstForceBrain)
        {
            if(mapConIdToOpportunity.ContainsKey(forceBrain.forcebrain__Customer__c))
            {
                Opportunity opp = mapConIdToOpportunity.get(forceBrain.forcebrain__Customer__c);
                if(opp.Next_Call_Date_Time__c == forceBrain.forcebrain__Appointment_Start_Date_Time__c && opp.Cert_Deck_Url__c !=null && forceBrain.Cert_Deck_Url__c != opp.Cert_Deck_Url__c)
                {
                    forceBrain.Cert_Deck_Url__c = opp.Cert_Deck_Url__c;
                    lstForceBrainToUpdate.add(forceBrain);
                }
            }
        }
        system.debug('lstForceBrainToUpdate=='+lstForceBrainToUpdate);
        if(lstForceBrainToUpdate.size()>0)
        {
            checkRecursive.isfromOpp = true;
            update lstForceBrainToUpdate; 
        }
    }
    
    private Map<String,String> getJobMap()
    {
        String j= '%Send1hourpriorreminder%';
        List<CronTrigger> lstct  = [SELECT Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger WHERE CronJobDetail.Name like :j];
        Map<String,String> mapJobNameToJobId = new Map<String,String>();
        for(CronTrigger ct:lstct)
        {
            System.debug('ct.CronJobDetail.Name=='+ct.CronJobDetail.Name);
            if(ct.CronJobDetail.Name != null && ct.CronJobDetail.Name.Contains('&'))
            {
                String OppId = ct.CronJobDetail.Name.Substring(ct.CronJobDetail.Name.indexOf('&')+1,ct.CronJobDetail.Name.length());
                mapJobNameToJobId.put(OppId,ct.id);
            }
        }
        return mapJobNameToJobId;
    }
    private void abortOpportunitySendEmailCompetedJobs()
    {
        String sendEmailJObName= '%OpportunitySendEmail%';
        List<CronTrigger> lstct  = [SELECT Id, CronJobDetail.Name,State, CronJobDetail.JobType FROM CronTrigger WHERE CronJobDetail.Name like :sendEmailJObName];
         
        for(CronTrigger ct:lstct)
        {
            
            System.debug('ct.CronJobDetail.Name=='+ct.CronJobDetail.Name);
            if(ct.CronJobDetail.Name != null)
            {
                if(ct.State == 'COMPLETE')
                {
                    system.abortJob(ct.Id);
                }                
            }            
        }        
    }
   
}