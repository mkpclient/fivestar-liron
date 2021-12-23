trigger DSTaskActions3 on Task (after insert, before insert)
{
    if(trigger.isBefore)
    {
        for(Task t:trigger.new)
        {
            // If conditions are met then skipp
            if(t.dialforce__RD_Disposition__c == null || t.dialforce__RD_Disposition__c == '')continue;
            if(t.Subject != 'Refractive Dialer Automated Call')continue;
            //if(t.CallDurationInSeconds == null) continue;
            // If conditions are met then change subject line
            if((t.dialforce__RD_Disposition__c!= null && t.dialforce__RD_Disposition__c!='') || t.Description.contains('Description:'))
            {
                String ReqDes = t.dialforce__RD_Disposition__c + ': ' + t.Description.substringAfterLast('Description: ');
                if(ReqDes.length()>=255)
                    ReqDes = ReqDes.substring(0,254);
                t.Subject = ReqDes;
            }
        }
        
        String urlRegex = '(https://global\\.refractivedialer\\.com/GetRecording\\.php\\?remote_id=\\S*)';
        Pattern p = Pattern.compile(urlRegex);
        
        for(Task t:trigger.new)
        {
            if (t.dialforce__RD_Disposition__c == null || t.dialforce__RD_Disposition__c == '') continue;
            
            if(!(t.Description == null || t.Description == ''))
            {
                Matcher m = p.matcher(t.Description);
                
                if(m.find())
                {
                    t.DSRecordingURL__c = m.group();
                }
            }
        }
    }

    if(trigger.isAfter)
    {
        //Leads
        Map<Id, String> leadMap = new Map<Id, String>();
        Map<Id, String> leadCLMap = new Map<Id, String>();
        //Contacts
        Map<Id, String> contactMap = new Map<Id, String>();
        Map<Id, String> contactCLMap = new Map<Id, String>();
        //Accounts
        Map<Id, String> accountMap = new Map<Id, String>();
        Map<Id, String> accountCLMap = new Map<Id, String>();
        //Opps
        Map<Id, String> oppMap = new Map<Id, String>();
        Map<Id, String> oppCLMap = new Map<Id, String>();

        for(Task t:trigger.new)
        {
            //If the task has a WhoId execute the above actions
            if(t.WhoId != Null && t.dialforce__RD_Disposition__c != Null)
            {
                //Leads
                if(String.valueOf(t.WhoId).substring(0,3) == '00Q')
                {
                    leadMap.put(t.WhoId, t.dialforce__RD_Disposition__c);
                    leadCLMap.put(t.WhoId, t.dialforce__RD_CallListName__c);
                }
                //Contacts
                else if(String.valueOf(t.WhoId).substring(0,3) == '003')
                {
                    contactMap.put(t.WhoId, t.dialforce__RD_Disposition__c);
                    contactCLMap.put(t.WhoId, t.dialforce__RD_CallListName__c);
                }
            }
            
            //If task has a WhatId...
            else if(t.WhatId != Null && t.dialforce__RD_Disposition__c != Null)
            {
                //Accounts
                if(String.valueOf(t.WhatId).substring(0,3) == '001')
                {
                    accountMap.put(t.WhatId, t.dialforce__RD_Disposition__c);
                    accountCLMap.put(t.WhatId, t.dialforce__RD_CallListName__c);
                }
                //Opps
                else if(String.valueOf(t.WhatId).substring(0,3) == '006')
                {
                    oppMap.put(t.WhatId, t.dialforce__RD_Disposition__c);
                    oppCLMap.put(t.WhatId, t.dialforce__RD_CallListName__c);
                }
                //Cases
                //else if(String.valueOf(t.WhatId).substring(0,3) == '500')
                //{
                    //Nothing for now since DS does not support cases out of the box
                //}
            }
        }
        if(!system.isBatch() || !system.isFuture())
        {
            //Call Asynchronous class here
            if(!leadMap.isEmpty()) DSsObjectActions.DSUpdateLead(leadMap, leadCLMap);
            if(!contactMap.isEmpty()) DSsObjectActions.DSUpdateContact(contactMap, contactCLMap);
            if(!accountMap.isEmpty()) DSsObjectActions.DSUpdateAccount(accountMap, accountCLMap);
            if(!oppMap.isEmpty()) DSsObjectActions.DSUpdateOpportunity(oppMap, oppCLMap);
        }
        else
        {
            //@Future not used here
            if(!leadMap.isEmpty()) DSsObjectActions.DSUpdateLeadNotFuture(leadMap, leadCLMap);
            if(!contactMap.isEmpty()) DSsObjectActions.DSUpdateContactNotFuture(contactMap, contactCLMap);
            if(!accountMap.isEmpty()) DSsObjectActions.DSUpdateAccountNotFuture(accountMap, accountCLMap);
            if(!oppMap.isEmpty()) DSsObjectActions.DSUpdateOpportunityNotFuture(oppMap, oppCLMap);
        }
    }
}