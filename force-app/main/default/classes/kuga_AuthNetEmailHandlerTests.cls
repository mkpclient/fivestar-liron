/*****************************************************************************************
*    Class Name:        kuga_AuthNetEmailHandlerTests
*
*    Class Type:        Test class
*    
*    Description:       This class is a test class for kuga_AuthNetEmailHandler
*
*   Test Methods:       kuga_AuthNetEmailHandlerTests
*
*   Class History:      Created by Kiran Kurella Dec 8th 2017
*
*   Copyright 2017 Kugamon.  All rights reserved.
*****************************************************************************************/

@isTest //(SeeAllData=true)
public class kuga_AuthNetEmailHandlerTests {

    static @isTest void test_AuthNetEmailHandler_Success() {

		ManageLinesTests.DataSetup();

        // Switch to test context
        Test.startTest();

		test_AuthNetEmailHandler(true);

 		// Switch back to runtime context
        Test.stopTest();

    }

    static @isTest void test_AuthNetEmailHandler_Failure() {

		ManageLinesTests.DataSetup();

        // Switch to test context
        Test.startTest();

		test_AuthNetEmailHandler(false);

 		// Switch back to runtime context
        Test.stopTest();

    }    

	private static void test_AuthNetEmailHandler(boolean isSuccess) {

        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment successBinAtt = new Messaging.InboundEmail.BinaryAttachment();
        Messaging.InboundEmail.BinaryAttachment failureBinAtt = new Messaging.InboundEmail.BinaryAttachment();

        kuga_AuthNetEmailHandler ieh = new kuga_AuthNetEmailHandler();
        ieh.handleInboundEmail(email, env);

        string emailBody = 'Summary of Automated Recurring Billing';

        email.subject = 'Forwarding Confirmation';
        email.plainTextBody = emailBody;
        env.fromAddress = 'kiran@kugamon.com';

        ieh.handleInboundEmail(email, env);

        // process email with no attachments
        email.subject = 'Summary of Automated Recurring Billing';
        ieh.handleInboundEmail(email, env);

		// success text
		if (isSuccess) {
			emailBody = '"SubscriptionID","SubscriptionStatus","Payment#","TotalRecurrences ","TransactionID","Amount","Currency","Method","CustFirstName","CustLastName","RespCode","RespText"\n' +
							//'"33427664","Active","6","11","40231101380","60.00","USD","Credit Card","Jerry","Grosenick","1","This transaction has been approved."\n' +
							ManageLinesTests.RecurringCharge.kugo2p__AuthNet_Subscription_Id__c + ',"Active","6","11","40231101734","16.00","USD","Credit Card","Jack","Morse","1","This transaction has been approved."';
	
	        // set the body of the attachment
	        successBinAtt.body = Blob.valueOf(emailBody);
	        successBinAtt.fileName = 'Successful.csv';
	        
	        email.BinaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {successBinAtt};

		} else {

			// failure text
			emailBody = '"SubscriptionID","SubscriptionStatus","Payment#","TotalRecurrences ","TransactionID","Amount","Currency","Method","CustFirstName","CustLastName","RespCode","RespText"\n' +
							//'"33511274","Suspended","2","5","402311249845","391.66","USD","Credit Card","Kim","Bryant","2","This transaction has been declined."\n' +
							ManageLinesTests.RecurringCharge.kugo2p__AuthNet_Subscription_Id__c + ',"Active","6","11","402311204012","36.00","USD","Credit Card","Bob","Pollard","200"," This transaction has been declined"';
	
	        failureBinAtt.body = Blob.valueOf(emailBody);
	        failureBinAtt.fileName = 'Failed.csv';

			email.BinaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {failureBinAtt};	
		}

        ieh.handleInboundEmail(email, env);

        //email.subject = 'Summary of Automated Recurring Billing';
        ieh.handleInboundEmail(email, env);

		// success text - extra column
		emailBody = '"SubscriptionID","SubscriptionStatus","Payment#","TotalRecurrences ","TransactionID","Amount","Currency","Method","CustFirstName","CustLastName","RespCode","RespText","Dummy Column"\n' +
						'"33427664","Active","6","11","40231101380","60.00","USD","Credit Card","Jerry","Grosenick","1","This transaction has been approved."\n' +
						ManageLinesTests.RecurringCharge.kugo2p__AuthNet_Subscription_Id__c + ',"Active","6","11","40231101734","16.00","USD","Credit Card","Jack","Morse","1","This transaction has been approved."';

        successBinAtt.body = Blob.valueOf(emailBody);
        successBinAtt.fileName = 'Successful.csv';
		//email.BinaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {successBinAtt, failureBinAtt};
		email.BinaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {successBinAtt};

		ieh.handleInboundEmail(email, env);

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        kuga_AuthNetEmailHandler.SetInboundEmailResult(Result, true, 'Email notification processed successfully.');

        system.assertNotEquals(kuga_AuthNetEmailHandler.responseReasonText(2), null);
        system.assertNotEquals(kuga_AuthNetEmailHandler.responseReasonText(2342432), null);
        system.assertNotEquals(kuga_AuthNetEmailHandler.responseReasonText(248, 'Non Detailed'), null);

        system.assertEquals(kuga_ImportHelper.getFieldValue(new list<String>(), 10), null);
        system.assertEquals(kuga_ImportHelper.convert('abcd', 0), null);
        system.assertEquals(kuga_ImportHelper.convertInt('abcd', 0), null);
        system.assertEquals(kuga_ImportHelper.convertInt('111', 0), 111);		
	}

}