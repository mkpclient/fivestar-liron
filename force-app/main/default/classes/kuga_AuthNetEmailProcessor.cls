/*****************************************************************************************
*    Class Name:        kuga_AuthNetEmailProcessor
*
*    Class Type:        Scheduleable Batch class
*    
*    Description:       This class processes Authorize.Net Summary of Automated Recurring Billing email
*
*   Test Methods:       kuga_AuthNetEmailProcessorTests and kuga_AuthNetEmailHandlerTests
*
*   Class History:      Created by Kiran Kurella Dec 7th 2017
*
*   Copyright 2017 Kugamon.  All rights reserved.
*****************************************************************************************/

global class kuga_AuthNetEmailProcessor implements Database.Batchable<kugo2p__PaymentX__c>, Database.Stateful {

	private static final Integer batchSize = 1;

	private map<String, kugo2p__PaymentX__c> mapPayments;
	private map<String, Database.SaveResult> mapSaveResults = new map<String, Database.SaveResult>();	

    public kuga_AuthNetEmailProcessor(map<String, kugo2p__PaymentX__c> pPayments) {
        this.mapPayments = (pPayments == null ? new map<String, kugo2p__PaymentX__c>() : pPayments);
        system.debug(' ### mapPayments in kuga_AuthNetEmailProcessor ' + mapPayments.size());	// + ' => ' + mapPayments
    }

	global Iterable<kugo2p__PaymentX__c> start(Database.BatchableContext BC) {
		return mapPayments.values();
	}

	global void execute(Database.BatchableContext BC, list<kugo2p__PaymentX__c> payments) {

		// batch size is set to 1
		if (payments != null && !payments.isEmpty()) mapSaveResults.put(payments[0].kugo2p__Transaction_Id__c, Database.insert(payments[0], false));
	}

	// Returns true if there are open batch queues
	public static Boolean canExecuteBatch {
		get {
			try {
				return ([Select count() from AsyncApexJob Where JobType = 'BatchApex' and Status IN ('Queued', 'Processing', 'Preparing')] < 5);
			} catch (Exception ex) {
				return false;
			}
		}
	}

	public static Id startJob(map<String, kugo2p__PaymentX__c> payments) {

		Id batchId;

		if (payments != null) system.debug(' ### payments in kuga_AuthNetEmailProcessor ' + payments.size());	// + ' => ' + payments

		if ( (system.isScheduled() || canExecuteBatch) && !system.isBatch() && !system.isFuture()) {

			kuga_AuthNetEmailProcessor blp = new kuga_AuthNetEmailProcessor(payments);

			batchId = Database.executeBatch(blp, batchSize);
		}

		return batchId;
	}

	private void ProcessBatchResults() {

		if (!mapSaveResults.isEmpty()) {

			String sucessMsg_FailedPayments = '';
			String sucessMsg_CompletedPayments = '';
			String errMsg = '';
			Integer errorCount = 0;
			String entityURL;
			String entityLink;
			String subject;
			String message = '';
			String baseURL = URL.getSalesforceBaseUrl().toExternalForm();

			// Iterate through each returned result
			//for (Database.SaveResult sr : mapSaveResults.values())
			for (String transId : mapSaveResults.keySet()) {

				Database.SaveResult sr = mapSaveResults.get(transId);
				kugo2p__PaymentX__c payment = mapPayments.get(transId);

				entityURL = baseURL + '/' + sr.getId();
				entityLink = '<a href='+entityURL+'>' + payment.Name + '</a>';

			    if (sr.isSuccess()) {
			        // Operation was successful, so get the ID of the record that was processed
			        //system.debug(' ### Successfully inserted Payment. Payment ID: ' + sr.getId());
			        if (payment.kugo2p__Status__c == 'Completed') {
			        	sucessMsg_CompletedPayments += entityLink + '<br/>';
			        } else {
			        	sucessMsg_FailedPayments += entityLink + '<br/>';
			        }	

			    } else {
			        // Operation failed, so get all errors
			        if (!sr.getErrors().isEmpty()) {
			        	errorCount+=1;
			        	errMsg += '<br/><br/>Error Number: ' + errorCount + '<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';

						errMsg += 'Payment failed for Transaction Id: ' + payment.kugo2p__Transaction_Id__c;
			        	for (Database.Error err : sr.getErrors()) {
			        		system.debug(' ### The following error has occurred ' + err.getStatusCode() + ': ' + err.getMessage());
				        	errMsg += '<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' + err.getMessage();
			        	}
			        }
			    }
			}

			message += 'The Authorize.Net \'Summary of Automated Recurring Billing\' email has been processed to create missing Recurring Payments.' + '<br/><br/>';

			if (errMsg != '') {
				message += '<b>Processing Failures</b><br/>' +
						   'An error occurred when creating the following missing Recurring Payment(s):' + errMsg + '<br/><br/>';
			}

			if (sucessMsg_CompletedPayments != '' || sucessMsg_FailedPayments != '') {
				message += '<b>Processing Success</b><br/>' +
						   'The following missing Recurring Payment(s) have been created successfully:' + '<br/><br/>' +
						   (sucessMsg_FailedPayments != '' ? ('Payment Status = Declined<br/>' + sucessMsg_FailedPayments + '<br/>') : '') +
						   (sucessMsg_CompletedPayments != '' ? 'Payment Status = Completed<br/>' : '') + sucessMsg_CompletedPayments;
			}

			subject = 'Summary of Automated Recurring Billing Process Notification';
    		kuga_Util.sendEmail(subject, message, ManageLinesController.Settings.kugo2p__Admin_User__c, null, true, false, true);
			system.debug(' ### after sending email');
		}
	}

    global void finish(Database.BatchableContext BC) {

    	ProcessBatchResults();

        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email, ExtendedStatus 
                          from AsyncApexJob where Id =:BC.getJobId()];

        if (a.NumberOfErrors > 0 || system.Test.isRunningTest()) {
            // handle errors
            kuga_Util.sendTextEmail(UserInfo.getOrganizationName() + ' - Batch Summary of Automated Recurring Billing job failed - OrgId: ' + UserInfo.getOrganizationId(),
            					'The batch job processed ' + a.TotalJobItems + ' batches with ' + a.NumberOfErrors + ' failures.\n\n' + a.ExtendedStatus);
        }
    }	
}