global class ProcessOppNextcallDateAndEmail implements Database.Batchable<sObject>{
   global ProcessOppNextcallDateAndEmail(){
         
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
       abortCompleteJobs();
       Datetime todayDT = system.now().addHours(1);//system.Today().addDays(1);
       Datetime nexthourDT = system.now().addHours(2);
       //String query = 'select id,Next_Call_Date_Time__c,Contact__c,createddate from opportunity where Next_Call_Date_Time__c >: todayDT  and Next_Call_Date_Time__c <: nextdayDT';
      String query = 'select id,Next_Call_Date_Time__c,createddate from opportunity where Next_Call_Date_Time__c >=: todayDT  and Next_Call_Date_Time__c <=: nexthourDT';
      
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<Opportunity> scope){
       Map<String,String> mapJobNameToJobId = getJobMap();
       
       Map<String,List<Opportunity>> mapNextTimeToOppId = new Map<String,List<Opportunity>>();
       for(Opportunity opp:scope)
        {
            
            if(opp.Next_Call_Date_Time__c != null && opp.Next_Call_Date_Time__c > system.now().addHours(1) )
            {              
                DateTime dt = opp.Next_Call_Date_Time__c;
                system.debug('dt=='+dt);                
                String day = string.valueOf(dt.day());
                String month = string.valueOf(dt.month());
                String hour = string.valueOf(dt.hour()-1);
                String minute = string.valueOf(dt.minute() + 1);
                String second = string.valueOf(dt.second());
                String year = string.valueOf(dt.year());
                String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
                system.debug('strSchedule=='+strSchedule );
                DateTime dt1 = system.now();
                if(mapJobNameToJobId != null && mapJobNameToJobId.ContainsKey(opp.Id))
                {
                    system.abortJob(mapJobNameToJobId.get(opp.Id));
                }
                String scheduleName = 'Send1hourpriorreminderEmail Job' + System.now().format('mm/dd/yyyy') + string.valueOf(dt1.second()) + '&'+ opp.Id;
                system.debug('scheduleName =='+scheduleName);
                System.schedule(scheduleName,strSchedule, new Send1hourpriorreminderEmail(new List<Id>{opp.Id}));
            }
                             
        }
        /*for(opportunity opp:scope)
        {
            if(mapJobNameToJobId != null && mapJobNameToJobId.ContainsKey(opp.Next_Call_Date_Time__c.format()))
            {
                system.abortJob(mapJobNameToJobId.get(opp.Next_Call_Date_Time__c.format()));
            }
            if(mapNextTimeToOppId.containskey(opp.Next_Call_Date_Time__c.format()))
            {
                mapNextTimeToOppId.get(opp.Next_Call_Date_Time__c.format()).add(opp);
            }
            else
            {
                mapNextTimeToOppId.put(opp.Next_Call_Date_Time__c.format(),new List<Opportunity>{opp});
            }
        }
        if(mapNextTimeToOppId.size()>0)
        {
            for(String nextdate : mapNextTimeToOppId.keySet())
            {
                Set<String> setOppIds = new Set<String>(); 
                List<Id> lstOppids = new List<Id>();
                List<Opportunity> lstOpps =  mapNextTimeToOppId.get(nextdate ); 
                if(lstOpps.size()>0)
                {
                    for(Opportunity opp : lstOpps ){
                        
                        lstOppids.add(opp.id); 
                    }
                    DateTime dt = lstOpps[0].Next_Call_Date_Time__c;
                    system.debug('dt=='+dt);                
                    String day = string.valueOf(dt.day());
                    String month = string.valueOf(dt.month());
                    String hour = string.valueOf(dt.hour()-1);
                    String minute = string.valueOf(dt.minute() + 1);
                    String second = string.valueOf(dt.second());
                    String year = string.valueOf(dt.year());
                    String strSchedule = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
                    system.debug('strSchedule=='+strSchedule );
                    DateTime dt1 = system.now();
                    if(mapJobNameToJobId != null && mapJobNameToJobId.ContainsKey(opp.Id))
                    {
                        system.abortJob(mapJobNameToJobId.get(opp.Id));
                    }
                    String scheduleName = 'Send1hourpriorreminderEmail Job' + System.now().format('mm/dd/yyyy') + string.valueOf(dt1.second()) + '&'+ lstOpps[0].Next_Call_Date_Time__c.format();
                    system.debug('scheduleName =='+scheduleName);
                    System.schedule(scheduleName,strSchedule, new Send1hourpriorreminderEmail(lstOppids));
                }         
                 
            }
             
        }*/
           
   }
   global void finish(Database.BatchableContext BC){

   }
   
   private void abortCompleteJobs()
   {
        String sendEmailJObName= 'Send1hourpriorreminder';
        String ProcessEmailJobName = 'ProcessOppNextcallDateAndEmail';
        for ( AsyncApexJob aJob : [ Select id ,Status, ApexClass.Name from AsyncApexJob where  Status = 'Completed' and (ApexClass.Name =:sendEmailJObName or  ApexClass.Name =:ProcessEmailJobName)] ){
            System.AbortJob(aJob.Id);
        }

   }
   private Map<String,String> getJobMap()
    {
        String sendEmailJObName= '%Send1hourpriorreminder%';
        String ProcessEmailJobName = '%Send1hourEmailSchedule%';
        List<CronTrigger> lstct  = [SELECT Id, CronJobDetail.Name,State, CronJobDetail.JobType FROM CronTrigger WHERE CronJobDetail.Name like :sendEmailJObName or CronJobDetail.Name like :ProcessEmailJobName ];
        Map<String,String> mapJobNameToJobId = new Map<String,String>();
        
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
            if(ct.CronJobDetail.Name != null && ct.CronJobDetail.Name.Contains('&'))
            {
                String OppId = ct.CronJobDetail.Name.Substring(ct.CronJobDetail.Name.indexOf('&')+1,ct.CronJobDetail.Name.length());
                mapJobNameToJobId.put(OppId,ct.id);
            }
        }
        return mapJobNameToJobId;
    } 

}