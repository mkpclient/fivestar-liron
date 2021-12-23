global class Send1hourpriorreminderEmail implements Schedulable {
    global List<Id> oppIds;
    public Send1hourpriorreminderEmail( List<Id> aoppIds) {
        oppIds = aoppIds;
    }
    global void execute(SchedulableContext ctx) {        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        List<Opportunity> lstOpps = [select id,OwnerID,Next_Call_Date_Time__c, Contact__c, EmailAddress__c, Cert_Deck_Url__c from Opportunity where Id In:oppIds]; 
        for(Opportunity opp : lstOpps) 
        {
        User u = [select id,email,Title,FirstName,Phone from user where id=:opp.OwnerID];
        List<forcebrain__EventParticipant__c> lstforceBrain = [select id,Name,forcebrain__Add_to_Outlook_Text__c,forcebrain__Add_to_Google_Calendar_Text__c,forcebrain__Email_Signature_Formula__c,forcebrain__Appointment_Confirmation_Link_Text__c,forcebrain__Add_to_Google_Calendar__c,forcebrain__Add_to_Outlook__c,forcebrain__Event__r.forcebrain__User_web_conference_details__c,forcebrain__Event__r.forcebrain__Description__c,forcebrain__Event__r.forcebrain__Template_Detail__c,forcebrain__Event__r.Name,forcebrain__Event__r.forcebrain__Participant_Info__c,forcebrain__Location_Address__c,forcebrain__Location_Name__c,forcebrain__Duration__c,forcebrain__Event__r.forcebrain__Start_Date_Time_Text__c,forcebrain__Time_Zone__c,forcebrain__Customer__c,forcebrain__Name__c,forcebrain__Appointment_Confirmation_Link__c from forcebrain__EventParticipant__c where forcebrain__Customer__c =:opp.Contact__c and forcebrain__Appointment_Start_Date_Time__c =:opp.Next_Call_Date_Time__c];
        EmailTemplate et=[Select id,body,Subject,HTMLValue from EmailTemplate where Name=:'1 Hour Customers and Providers - Reminder Appointment'];
        String emailBody = et.HTMLValue;
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'scheduling@fivestarprofessional.com'];


        if(lstforceBrain != null && lstforceBrain.size()>0)
        {
            mail.setTargetObjectId(opp.Contact__c); 
            mail.setTreatTargetObjectAsRecipient(false);           
            mail.setWhatId(lstforceBrain[0].Id);
            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mail.setTemplateId(et.id);          
            String[] toAddresses  = new String[] {u.email};
             system.debug('opp.EmailAddress__c='+opp.EmailAddress__c);
            if(opp.EmailAddress__c != null)
                toAddresses.add(opp.EmailAddress__c);
                
             mail.setToAddresses(toAddresses);
             system.debug('mail.toAddresses='+mail.toAddresses);
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        }
        
    }    
   
}