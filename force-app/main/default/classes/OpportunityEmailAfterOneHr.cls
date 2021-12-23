global class OpportunityEmailAfterOneHr Implements Schedulable
    {
        global List<Id> lstOppIds;
        global void execute(SchedulableContext sc)
        {
           sendEmail(lstOppIds);
        }

        public OpportunityEmailAfterOneHr(List<id> Oppsids)
        {
           if ( lstOppIds == null ) {
                lstOppIds = Oppsids;
            } else {
                lstOppIds.addAll(Oppsids);
            }
             
        }
        
         public static void sendEmail(List<Id> lstOppsids) {
              List < Opportunity > lstOppsToSendEmail = [select Id,Contact__c,EmailAddress__c, Name,StageName from Opportunity where Id in:lstOppsids];
             OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'allen.wardell@fivestarprofessional.com'];
               OrgWideEmailAddress[] owea1 = [select Id from OrgWideEmailAddress where Address = 'Dylan.campbell@fivestarprofessional.com'];
              List < EmailTemplate > et = new List < EmailTemplate > ();
             List < EmailTemplate > deadStageset = new List < EmailTemplate > ();
              if (Schema.sObjectType.EmailTemplate.isAccessible()) {
               et = [
                SELECT Id, HTMLValue
                FROM EmailTemplate
                WHERE DeveloperName = 'Buyer_No_Interest_Survey'
               ];
               deadStageset = [
                SELECT Id, HTMLValue
                FROM EmailTemplate
                WHERE DeveloperName = 'Buyer_Dead_Survey'
               ];
              }
            
              //loop through and build emails for the orders
              List < Messaging.SingleEmailMessage > emailList = new List < Messaging.SingleEmailMessage > ();            
              for (Opportunity opp: lstOppsToSendEmail) {            
                   //otherwise send 1 email per order
                   Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();               
                   List < String > recipients = new List < String > ();
                   recipients.add(opp.EmailAddress__c);
                   email.setToAddresses(recipients);
                   system.debug('To addresses are ' + recipients);
                   if(!Test.isRunningTest())
                       if((opp.StageName== 'Dead -- Cert Appt Target Calls Made' || opp.StageName == 'Dead - Connected but did not agree to Cert' || opp.StageName == 'Dead - Market Closed') && owea.size() > 0)  {
                            email.setTemplateId(deadStageset[0].Id);
                            email.setOrgWideEmailAddressId(owea1.get(0).Id);
                           
                        } else {
                            email.setTemplateId(et[0].Id);
                             email.setOrgWideEmailAddressId(owea.get(0).Id);
                          }
                   else {
                       email.setHtmlBody('Test');
                   }
                   email.setWhatId(opp.Id);
                   email.setTreatTargetObjectAsRecipient(false);
                   if (opp.Contact__c != null) {
                    email.setTargetObjectId(opp.Contact__c);              
                   }
                /*  if (owea.size() > 0) {
                        email.setOrgWideEmailAddressId(owea.get(0).Id);
                    } */
                   emailList.add(email);
              }
              system.debug('Emails==='+emailList);
              Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
            
            system.debug('results ==='+results );
    
    
     }

        
    }