/*****************************************************************************************
*    Class Name:        kuga_Util
*
*    Class Type:        Utility class
*    
*    Description:       This class performs contains various utility methods
*
*   Test Methods:       kuga_AuthNetEmailProcessorTests and kuga_AuthNetEmailHandlerTests
*
*   Class History:      Created by Kiran Kurella Nov 20th 2017
*
*   Copyright 2017 Kugamon.  All rights reserved.
*****************************************************************************************/

public with sharing class kuga_Util {
 
    public static void sendTextEmail(String emailSubject, String textBody) {
    	sendTextEmail(emailSubject, textBody, null);
    }

    public static void sendTextEmail(String emailSubject, String textBody, list<String> recipients) {
    	// TO DO - move recipients to a custom settings record
    	//if (recipients == null || recipients.isEmpty()) recipients = new string[] {kuga_sub_ManageLinesController.Settings.kugo2p__Admin_User__r.Email};	//'kiran@kugamon.com'
        sendEmail(emailSubject, textBody, recipients, new String[] {ManageLinesController.Settings.kugo2p__Admin_User__c, 'error@kugamon.com'}, null, 'FiveStar Professional Automation', 'noreply@kugamon.com', false, null, false, true);
    }

    public static Messaging.SingleEmailMessage sendEmail(String emailSubject, String body, list<String> recipients, list<String> recipientsCC, list<String> recipientsBCC, 
    														String senderDisplayName, String replyTo, Boolean useHTML, list<Messaging.EmailFileAttachment> fileAttachments, boolean saveAsActivity, boolean send) {

        if( (recipients == null || recipients.isEmpty()) && (recipientsCC == null || recipientsCC.isEmpty()) && (recipientsBCC == null || recipientsBCC.isEmpty())) return null;

        // Create a new single email message object
        // that will send out a single email to the addresses in the To, CC & BCC list.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        

        // Assign the addresses for the To lists to the mail object.
        if (recipients != null && !recipients.isEmpty()) mail.setToAddresses(recipients);
        if (recipientsCC != null && !recipientsCC.isEmpty()) mail.setCCAddresses(recipientsCC);
        if (recipientsBCC != null && !recipientsBCC.isEmpty()) mail.setBCCAddresses(recipientsBCC);

        if (senderDisplayName != null) mail.setSenderDisplayName(senderDisplayName);

        //the email is not saved as an activity.
        //mail.setSaveAsActivity(false);
        mail.setSaveAsActivity(saveAsActivity==null ? false : saveAsActivity);

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);

        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

        if (String.isNotBlank(replyTo)) mail.setReplyTo(replyTo);

        // Specify the subject line for your email address.        
        mail.setSubject(emailSubject);

        //mail.setPlainTextBody(body);        
        if (useHTML) {
            // Specify the html content of the email.
            mail.setHtmlBody(body);
        } else {
            // Specify the text content of the email.
            mail.setPlainTextBody(body);
        }

        // Specify File Attachments
        if(fileAttachments != null && !fileAttachments.isEmpty()) mail.setFileAttachments(fileAttachments);

        system.debug(' ### sending email ' + mail);

        // Send the email you have created.
        if (send) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        return mail;
    }

    public static Messaging.SingleEmailMessage sendEmail(String emailSubject, String body, //list<String> recipients, list<String> recipientsCC, list<String> recipientsBCC, 
    														//String senderDisplayName, String replyTo,
    														Id targetObjectId, String orgWideEmailAddress,
    														Boolean useHTML, //list<Messaging.EmailFileAttachment> fileAttachments, 
    														boolean saveAsActivity, boolean send) {

        // Create a new single email message object
        // that will send out a single email to the addresses in the To, CC & BCC list.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        

    	//Id orgWideId = getOrgWideEmailAddressId(orgWideEmailAddress);
    	//if (orgWideId != null) mail.setOrgWideEmailAddressId(orgWideId);

    	mail.setTargetObjectId(targetObjectId);

        //the email is not saved as an activity.
        mail.setSaveAsActivity(saveAsActivity==null ? false : saveAsActivity);

        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);

        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

        // Specify the subject line for your email address.        
        mail.setSubject(emailSubject);

        //mail.setPlainTextBody(body);        
        if (useHTML) {
            // Specify the html content of the email.
            mail.setHtmlBody(body);
        } else {
            // Specify the text content of the email.
            mail.setPlainTextBody(body);
        }

        //system.debug(' ### sending email ' + mail);

        // Send the email you have created.
        if (send) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        return mail;
    }    
}