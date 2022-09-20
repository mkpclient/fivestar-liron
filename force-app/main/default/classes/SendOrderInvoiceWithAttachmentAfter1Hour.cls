global with sharing class SendOrderInvoiceWithAttachmentAfter1Hour implements Schedulable {
    global List<Id> soIds;    
    public SendOrderInvoiceWithAttachmentAfter1Hour(List<id> listofSalesOrderIds) {
        soIds = listofSalesOrderIds;
    }
    global void execute(SchedulableContext ctx) {  
            system.debug('inside batch');    
        if(System.IsBatch() == false && System.isFuture() == false){       
          system.debug('inside batch1');   
            SendEmail(soIds);
            system.debug('inside batch2');   
        }
        
    }    
 
    public static void SendEmail(List<id> listofSalesOrderIds) {
        List<kugo2p__SalesOrder__c> lstOrders = [select id,kugo2p__ContactBilling__c, kugo2p__RecordStatus__c, kugo2p__ContactBuying__r.Email, Initial_Invoice_Sent__c, Email_To_Send__c, kugo2p__NetAmount__c  from kugo2p__SalesOrder__c where Id in:listofSalesOrderIds];
        List<kugo2p__SalesOrder__c> lstOrdersToSend = new List<kugo2p__SalesOrder__c>();
        for(kugo2p__SalesOrder__c so:lstOrders) {
        System.debug('status' + so.kugo2p__RecordStatus__c);
            if( (so.Email_To_Send__c == true &&  so.kugo2p__NetAmount__c > 0  && so.Initial_Invoice_Sent__c == false) || test.isrunningtest() ) {
                lstOrdersToSend.add(so);
                
            }
        }
          system.debug('listofSalesOrderIds=='+listofSalesOrderIds);
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        Map<String,Attachment> mapOrderIdToAttachment = new Map<String,Attachment>(); 
        for(kugo2p__SalesOrder__c order :lstOrdersToSend) {
            Attachment attach = new Attachment();
            attach.ParentId = order.Id;
            PageReference pref= page.New_FSP_Invoice;
            pref.getParameters().put('id',order.Id);
            pref.setRedirect(true);
            if(!test.isRunningTest()){
            Blob b = pref.getContentAsPDF();
            attach.Body = b;
            }
             if(test.isRunningTest()){
             Blob b = blob.valueof('Test error');
             attach.Body = b;
             }             
            attach.Name = 'test.pdf';
            mapOrderIdToAttachment.put(order.Id,attach);
        }
        system.debug('mapOrderIdToAttachment==='+ mapOrderIdToAttachment);
        if(mapOrderIdToAttachment.size()>0) {
            insert mapOrderIdToAttachment.values();
        }
        system.debug('After Insert mapOrderIdToAttachment==='+ mapOrderIdToAttachment);
           for(kugo2p__SalesOrder__c order :lstOrders) {
               String Orderid = order.Id;
               String emailTemplateName = 'FSP_Invoice_HTML';
                EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:emailTemplateName];
               system.debug('et=='+et);
                List<string> toAddress = new List<string>();
                List<string> cCAddress = New List<string>();
                OrgWideEmailAddress[] anOrgWideEmailAddress = [select Id from OrgWideEmailAddress where Address = 'accounts.receivable@fivestarprofessional.com'];                                  
                toAddress.add(order.kugo2p__ContactBuying__r.Email);
                //toAddress.add('sakethasfmc@gmail.com '); 
                cCAddress.add('billing@fivestarprofessional.com');                                                      
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(et.Id);
                if (anOrgWideEmailAddress != null && anOrgWideEmailAddress.size() > 0) {
                    mail.setOrgWideEmailAddressId(anOrgWideEmailAddress.get(0).Id);
                }  
                mail.setCCAddresses(cCAddress);          
                mail.setToAddresses(toAddress);                     
                mail.setTreatTargetObjectAsRecipient(false);
                mail.setTargetObjectId(order.kugo2p__ContactBilling__c);
                mail.setWhatId(Orderid);               
                Messaging.EmailFileAttachment attach= new Messaging.EmailFileAttachment();
                if(!test.isRunningTest()){
                    if(mapOrderIdToAttachment.containsKey(Orderid)) {                        
                        Blob b = mapOrderIdToAttachment.get(Orderid).Body;
                        system.debug('Blob b==='+ b);
                        attach.setBody(b);                        
                    }
                } else {
                   attach.setBody(Blob.valueOf('Test'));
               }
                attach.setFileName('Five star professional invoice.pdf');
                mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
                system.debug('mail=='+mail);
                
                allmsg.add(mail);                              
           }
        try {
            system.debug('Emails==='+allmsg);
             Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg);
             if (results.get(0).isSuccess()) {
                EmailSent(lstOrders);
            }
             
            system.debug('results ==='+results );
            //Messaging.sendEmail(allmsg);
            return;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
    public static void EmailSent(List<kugo2p__SalesOrder__c> lstOrders){
       // List<kugo2p__SalesOrder__c> lstOrders = [select id,kugo2p__ContactBilling__c, kugo2p__ContactBuying__r.Email, Initial_Invoice_Sent__c  from kugo2p__SalesOrder__c where Id in:listofSalesOrderIds];
        List<kugo2p__SalesOrder__c> lstOrdersToUpdate = new List<kugo2p__SalesOrder__c>();
        for(kugo2p__SalesOrder__c so:lstOrders) {
            if(so.Initial_Invoice_Sent__c == false) {
                so.Initial_Invoice_Sent__c = true;
                lstOrdersToUpdate.add(so);
            }
        }
          
        
        update lstOrdersToUpdate;
        
    }
}