/*****************************************************************************************
*    Class Name:        kuga_AuthNetEmailHandler
*
*    Class Type:        Batch
*    
*    Description:       This class is kicked off from "Authorize.Net Subscription Email Handler" Service
*
*   Test Methods:       kuga_AuthNetEmailHandlerTests
*
*   Class History:      Created by Kiran Kurella Nov 20th 2017
*
*   Copyright 2017 Kugamon.  All rights reserved.
*****************************************************************************************/

global class kuga_AuthNetEmailHandler implements Messaging.InboundEmailHandler {

	private static map<String, kugo2p__PaymentX__c> payments_To_Insert = new map<String, kugo2p__PaymentX__c>();

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        system.debug(' ### email.subject: ' + email.subject);
        //system.debug(' ### email.plainTextBody: ' + email.plainTextBody);

		//Summary of Automated Recurring Billing
		String emailSubject = email.subject;

        // used to capture email forwarding
        if ( (emailSubject != null && emailSubject.contains('Forwarding Confirmation')) || (email.plainTextBody != null && email.plainTextBody.contains('automatically forward')) ) {
        	kuga_Util.sendTextEmail(emailSubject, email.plainTextBody, new String[] {ManageLinesController.Settings.kugo2p__Admin_User__r.Email, 'error@kugamon.com'});
        }

		// process Summary report only
        if (emailSubject != null && emailSubject.containsIgnoreCase('Summary of Automated Recurring Billing')) {

			if ((email.binaryAttachments == null || email.binaryAttachments.isEmpty()) && (email.textAttachments == null || email.textAttachments.isEmpty())) {
				system.debug(' ### there are no attachments in the email.');
				return SetInboundEmailResult(result, false, 'There are no attachments in the email: ' + emailSubject);
			}

			String emailCommentsPrefix = ProcessEmailAttachments(email);
			//kuga_Util.sendTextEmail('status', emailCommentsPrefix, new String[] {ManageLinesController.Settings.kugo2p__Admin_User__r.Email, 'error@kugamon.com'});
        }

		return result;	
	}

    public static Messaging.InboundEmailResult SetInboundEmailResult(Messaging.InboundEmailResult eResult, boolean isSuccess, String message) {

    	// un-comment the following two lines to notify the sender
		//eResult.success = isSuccess;
		//eResult.message = message;
		if (!isSuccess) kuga_Util.sendTextEmail('Summary of Automated Recurring Billing Process failed', message, new String[] {ManageLinesController.Settings.kugo2p__Admin_User__r.Email, 'error@kugamon.com'});

		system.debug(' ### message in SetInboundEmailResult ' + message);
		return eResult;
    }

    public static Id DefaultProcessorConnectionId {
    	get {
    		if (DefaultProcessorConnectionId == null) {
    			//DefaultProcessorConnectionId = [Select Id from kugo2p__Processor_Connection__c where kugo2p__Default_Connection__c = true].Id;	//and kugo2p__Processor_Id__c = 'Authorize.Net'
    			list<kugo2p__Processor_Connection__c> connections = [Select Id from kugo2p__Processor_Connection__c where kugo2p__Default_Connection__c = true];
    			if (!connections.isEmpty()) DefaultProcessorConnectionId = connections[0].Id;
    		}
    		return DefaultProcessorConnectionId;
    	}
    	private set;
    }

 	/*  capture attachments in the incoming email into SF System  */
	public static String ProcessEmailAttachments(Messaging.InboundEmail email) {

		list<Attachment> attachments = new list<Attachment>();
        //Messaging.InboundEmail.TextAttachment[] tAttachments = email.textAttachments;
        Messaging.InboundEmail.BinaryAttachment[] bAttachments = email.binaryAttachments;
        String attachmentsToReturn = '';
        
        //if (tAttachments != null) system.debug(' ### text Attachments size ' + tAttachments.size());

        if (bAttachments != null) {
        	system.debug(' ### bAttachments size ' + bAttachments.size());
        	
        	// create a new Closed Task and add the attachments
        	Task newTask = new Task( Subject = 'AuthNet ARB Summary Email Notification',	//Summary of Automated Recurring Billing
		                             Status = 'Completed',
		                             ActivityDate = Date.today(),
		                             //event_code__c = getEventCode(eventName),
		                             Description = 'Summary of Automated Recurring Billing',
		                             //WhoId = whoId,
		                             WhatId = DefaultProcessorConnectionId,
		                             OwnerId = ManageLinesController.Settings.kugo2p__Admin_User__c
        							);
			insert newTask;        							

            for (Messaging.InboundEmail.BinaryAttachment mailAttach : bAttachments) {
            	system.debug(' ### mailAttach.mimeTypeSubType ' + mailAttach.mimeTypeSubType);

                if (attachmentsToReturn != '') attachmentsToReturn += ', ';
                attachmentsToReturn += mailAttach.fileName;

                Attachment attach = new Attachment(Name     = mailAttach.fileName,
									               Body     = mailAttach.body,
									               ParentId = newTask.Id,
									               OwnerId  = ManageLinesController.Settings.kugo2p__Admin_User__c);

                attachments.add(attach);
                system.debug(' ### adding Text Attachment  -> ' + mailAttach.fileName + ' to Processor Connection Task = ' + newTask.Id);

				// process Successful.csv
                if (mailAttach.fileName.containsIgnoreCase('Success')) {
                	processSubscription(mailAttach.body.toString(), true);
                }

				// process Failed.csv
                if (mailAttach.fileName.containsIgnoreCase('Fail')) {
                	processSubscription(mailAttach.body.toString(), false);
                }
            }

			system.debug(' ### payments_To_Insert ' + payments_To_Insert.size());	// + ' => ' + payments_To_Insert
			if (!payments_To_Insert.isEmpty()) {
				//insert payments_To_Insert.values();
				kuga_AuthNetEmailProcessor.startJob(payments_To_Insert);
			}
        }

		system.debug(' ### attachments ' + attachments.size());
		if (!attachments.isEmpty()) insert attachments;

		system.debug(' ### attachmentsToReturn ' + attachmentsToReturn);
		return attachmentsToReturn;
	}

	public final static map<String, String> mapAuthNetSubscriptionStatus_To_KugamonStatus = 
						new map<String, String> {
							'Active' 	=> 	'Active',
							'Expired'	=>	'Ended',
							'Suspended' =>  'Suspended',
							'Canceled'	=>	'Cancelled',
							'Terminated'=>	'Cancelled'
						};

	public static void processSubscription(String fileContent, boolean isSuccessFile) {

    	list<list<String>> filelines = kuga_ImportHelper.parseCSV(fileContent);
    	list<String> fileHeader;
    	map<String, Integer> mapColumnPosition = new map<String, Integer>();
    	map<Integer, String> mapRowSubs = new map<Integer, String>();

    	if (!filelines.isEmpty()) {
	    	fileHeader = filelines[0];
	    	filelines.remove(0);
    	}
    	//system.debug(' ### fileHeader ' + fileHeader.size() + ' => ' + fileHeader);

    	if (!filelines.isEmpty()) {

			String subscriptionIDLabel = 'SubscriptionID';
			String subscriptionStatusLabel = 'SubscriptionStatus';
			String paymentNoLabel = 'Payment#';
			String totalRecurrencesLabel = 'TotalRecurrences';
			String transactionIDLabel = 'TransactionID';
			String amountLabel = 'Amount';
			String currencyLabel = 'Currency';
			String methodLabel = 'Method';
			String custFirstNameLabel = 'CustFirstName';
			String custLastNameLabel = 'CustLastName';
			String respCodeLabel = 'RespCode';
			String respTextLabel = 'RespText';

			list<String> headerDefinition = new list<String>{subscriptionIDLabel, subscriptionStatusLabel, paymentNoLabel, totalRecurrencesLabel, transactionIDLabel, amountLabel, currencyLabel, methodLabel, 
																custFirstNameLabel, custLastNameLabel, respCodeLabel, respTextLabel};

			//system.debug(' ### headerDefinition ' + headerDefinition.size() + ' => ' + headerDefinition);

			for (Integer i = 0; i < fileHeader.size(); i++) {
				if (fileHeader.size() != headerDefinition.size() || headerDefinition[i] != fileHeader[i].trim()) {
					system.debug(' ### non matching columns headerDefinition[i] ' + headerDefinition[i] + ' fileHeader[i] ' + fileHeader[i]);
					kuga_Util.sendTextEmail('Summary of Automated Recurring Billing Process failed', '### non matching columns headerDefinition ' + headerDefinition[i] + ' fileHeader ' + fileHeader[i], new string[]{ManageLinesController.Settings.kugo2p__Admin_User__r.Email, 'error@kugamon.com'});
					//ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'CSV column headers must match the template file. Please correct the file and try again.'));
					return;
				}
				mapColumnPosition.put(fileHeader[i].trim(), i);
			}

			String fieldValue;
			//set<String> subscriptionIds = new set<String>();
			map<String, String> mapSubId_To_NewStatus = new map<String, String>();
			map<String, kugo2p__Payment_Profile__c> mapSubId_To_RecurringCharge = new map<String, kugo2p__Payment_Profile__c>();
			map<String, kugo2p__PaymentX__c> mapTransId_To_Payment = new map<String, kugo2p__PaymentX__c>();
			map<Id, kugo2p__Payment_Profile__c> mapSubscriptions_To_Update = new map<Id, kugo2p__Payment_Profile__c>();

			system.debug(' ### filelines ' + filelines.size());
			for (list<String> fieldValues : filelines) {

				// capture Subscription Ids
				fieldValue = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(subscriptionIDLabel));
				if (String.isNotBlank(fieldValue)) mapSubId_To_RecurringCharge.put(fieldValue, null);

				// capture Subscription Status
				mapSubId_To_NewStatus.put(fieldValue, kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(subscriptionStatusLabel)));

				// capture Transaction Ids
				fieldValue = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(transactionIDLabel));
				if (String.isNotBlank(fieldValue)) mapTransId_To_Payment.put(fieldValue, null);
			}

			// retrieve Subscriptions
			system.debug(' ### mapSubId_To_RecurringCharge ' + mapSubId_To_RecurringCharge.size());	// + ' => ' + mapSubId_To_RecurringCharge
			if (!mapSubId_To_RecurringCharge.isEmpty()) {
				for (kugo2p__Payment_Profile__c pp : [Select 	kugo2p__Contact__c, kugo2p__Account__c, kugo2p__SalesOrder__c, kugo2p__SalesOrder__r.Name,
																kugo2p__Processor_Connection__c, kugo2p__AuthNet_Subscription_Id__c, kugo2p__Subscription_Status__c
														from 	kugo2p__Payment_Profile__c
														where 	kugo2p__AuthNet_Subscription_Id__c in : mapSubId_To_RecurringCharge.keySet()]) {

					mapSubId_To_RecurringCharge.put(pp.kugo2p__AuthNet_Subscription_Id__c, pp);

					String newStatus = mapSubId_To_NewStatus.get(pp.kugo2p__AuthNet_Subscription_Id__c);
					if (mapAuthNetSubscriptionStatus_To_KugamonStatus.containsKey(newStatus)) newStatus = mapAuthNetSubscriptionStatus_To_KugamonStatus.get(newStatus);

					if (pp.kugo2p__Subscription_Status__c != newStatus) {
						pp.kugo2p__Subscription_Status__c = newStatus;

						mapSubscriptions_To_Update.put(pp.Id, pp);
					}
				}
			}

			system.debug(' ### mapSubscriptions_To_Update ' + mapSubscriptions_To_Update.size() + ' => ' + mapSubscriptions_To_Update);
			if (!mapSubscriptions_To_Update.isEmpty()) {
				//update mapSubscriptions_To_Update.values();
				Database.update(mapSubscriptions_To_Update.values(), false);
			}

			// retrieve Payments
			system.debug(' ### mapTransId_To_Payment ' + mapTransId_To_Payment.size() + ' => ' + mapTransId_To_Payment);
			if (!mapTransId_To_Payment.isEmpty()) {
				for (kugo2p__PaymentX__c pmt : [Select	kugo2p__SalesOrder__c, kugo2p__Contact__c, kugo2p__Processor_Connection__c, kugo2p__Payment_Profile__c,
														kugo2p__Transaction_Id__c, kugo2p__Scheduled_Payment_Number__c, kugo2p__Payment_Type__c, kugo2p__Amount__c,
														kugo2p__Currency_ISO_Code__c
												  from	kugo2p__PaymentX__c
												 where  kugo2p__Transaction_Id__c in : mapTransId_To_Payment.keySet()]) {

					mapTransId_To_Payment.put(pmt.kugo2p__Transaction_Id__c, pmt);

				}

				for (list<String> fieldValues : filelines) {

					// get Transaction Id
					fieldValue = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(transactionIDLabel));

					// capture missing payment record
					if (mapTransId_To_Payment.get(fieldValue) == null) {

						/*
						Transaction Id = 40233029492
						Subscription Id = 32428042
						Response Reason = (Resp Codes: 1) This transaction has been approved. 
						Amount = 36.00
						Currency = USD
						Method = Credit Card
						First Name = Kiran
						Last Name = Kurella
						Subscription Status = Active
						Subscription Payment Number = 6
						Subscription Total Recurrences = 11
						*/

						String logEntry = String.valueOf(System.now()) + ' ++++ Transaction response from Authorize.Net Summary of Automated Recurring Billing email:\n' +
										  	'Transaction Id = ' + fieldValue + '\n' +
										  	'Subscription Id = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(SubscriptionIDLabel)) + '\n' +
											'Response Reason = (Resp Codes: ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(respCodeLabel)) + ') ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(respTextLabel)) + '\n' +  
											'Amount = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(amountLabel)) + '\n' +
											'Currency = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(currencyLabel)) + '\n' +
											'Method = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(methodLabel)) + '\n' +
											'First Name = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(custFirstNameLabel)) + '\n' +
											'Last Name = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(custLastNameLabel)) + '\n' +
											'Subscription Status = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(subscriptionStatusLabel)) + '\n' +
											'Subscription Payment Number = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(paymentNoLabel)) + '\n' +
											'Subscription Total Recurrences = ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(totalRecurrencesLabel));

						// get Subscription Id
						fieldValue = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(subscriptionIDLabel));

						kugo2p__Payment_Profile__c pp = mapSubId_To_RecurringCharge.get(fieldValue);

						/*	Subscription Id is in Kugamon & Status = Completed

							Payment Name = Recurring Payment 5 for Order SO-170531-0018254 (standard format)
							Transaction Type = Payment
							Payment Type = Method
							Amount = Amount
							Currency ISO = Currency
							Payment Date = Today
							Status = Completed
							Transaction Id = Transaction Id
							Account Name = Recurring Charge Account
							Contact Billing = Recurring Charge Contact Billing
							Order Number = Recurring Charge Order
							Recurring Charge Profile = Map to Subscription Id
							Processor Connection = Recurring Charge Process Connection
							Authorization Amount = Amount
							Last Response Status = Status
						*/

						//system.debug(' ### amount ' + kuga_ImportHelper.convert(kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(amountLabel)), 0));
						payments_To_Insert.put(kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(transactionIDLabel)),
												new kugo2p__PaymentX__c(Name = 'Recurring Payment ' + kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(paymentNoLabel)) + (pp==null ? '' : (' for Order ' + pp.kugo2p__SalesOrder__r.Name)),
																	   kugo2p__Transaction_Type__c = 'Payment',
																	   kugo2p__Payment_Type__c = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(methodLabel)),
																	   kugo2p__Amount__c = kuga_ImportHelper.convert(kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(amountLabel)), 0),
																	   kugo2p__Auth_Amount__c = kuga_ImportHelper.convert(kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(amountLabel)), 0),
																	   kugo2p__Currency_ISO_Code__c = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(currencyLabel)),
																	   kugo2p__Date__c = system.today(),
																		 kugo2p__Subscription_Id__c = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(subscriptionIDLabel)),
																	   kugo2p__Status__c = (isSuccessFile ? 'Completed' : 'Declined'),
																	   kugo2p__Transaction_Id__c = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(transactionIDLabel)),
																	   kugo2p__Account__c = (pp==null ? null : pp.kugo2p__Account__c),
																	   kugo2p__Contact__c = (pp==null ? null : pp.kugo2p__Contact__c),
																	   kugo2p__SalesOrder__c = (pp==null ? null : pp.kugo2p__SalesOrder__c),
																	   kugo2p__Payment_Processor__c = 'Authorize.Net',
																	   kugo2p__Payment_Profile__c = (pp==null ? null : pp.Id),
																	   kugo2p__Processor_Connection__c = (pp==null ? null : pp.kugo2p__Processor_Connection__c),
																	   kugo2p__Last_Response_Status__c = kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(subscriptionStatusLabel)),
																	   kugo2p__Memo__c = (isSuccessFile ? null : responseReasonText(kuga_ImportHelper.convertInt(kuga_ImportHelper.getFieldValue(fieldValues, mapColumnPosition.get(respCodeLabel)), 0))),
																	   kugo2p__Log__c = logEntry));

					}
				}
			}

    	}

	}

	public static String responseReasonText(Integer code) {
	    return responseReasonText(code, 'Detailed');    
	}

	public static String responseReasonText(Integer code, String detailLevel) {
	    // Authorize.Net response code reasons (extracted from the AIM Developer's guide v2.0
	    // Extended reason/notes have been appended with a | delimiter.
	    Map<Integer,String> reasonStrings = new Map<Integer,String>{
	        1=>'This transaction has been approved.',
	        2=>'This transaction has been declined.',
	        3=>'This transaction has been declined.',
	        4=>'This transaction has been declined.|The code returned from the processor indicating that the card used needs to be picked up.',
	        5=>'A valid amount is required.|The value submitted in the amount field did not pass validation for a number.',
	        6=>'The credit card number is invalid.',
	        7=>'The credit card expiration date is invalid.|The format of the date submitted was incorrect.',
	        8=>'The credit card has expired.',
	        9=>'The ABA code is invalid.|The value submitted in the x_bank_aba_code field did not pass validation or was not for a valid financial institution.',
	        10=>'The account number is invalid.|The value submitted in the x_bank_acct_num field did not pass validation.',
	        11=>'A duplicate transaction has been submitted.|A transaction with identical amount and credit card information was submitted two minutes prior.',
	        12=>'An authorization code is required but not present.|A transaction that required x_auth_code to be present was submitted without a value.',
	        13=>'The merchant API Login ID is invalid or the account is inactive.',
	        14=>'The Referrer or Relay Response URL is invalid.|The Relay Response or Referrer URL does not match the merchant?s configured value(s) or is absent. Applicable only to SIM and WebLink APIs.',
	        15=>'The transaction ID is invalid.|The transaction ID value is non-numeric or was not present for a transaction that requires it (i.e. VOID, PRIOR_AUTH_CAPTURE, and CREDIT).',
	        16=>'The transaction was not found.|The transaction ID sent in was properly formatted but the gateway had no record of the transaction.',
	        17=>'The merchant does not accept this type of credit card.|The merchant was not configured to accept the credit card submitted in the transaction.',
	        18=>'ACH transactions are not accepted by this merchant.|The merchant does not accept electronic checks.',
	        19=>'An error occurred during processing. Please try again in 5 minutes.',
	        20=>'An error occurred during processing. Please try again in 5 minutes.',
	        21=>'An error occurred during processing. Please try again in 5 minutes.',
	        22=>'An error occurred during processing. Please try again in 5 minutes.',
	        23=>'An error occurred during processing. Please try again in 5 minutes.',
	        24=>'The Nova Bank Number or Terminal ID is incorrect. Call Merchant Service Provider.',
	        25=>'An error occurred during processing. Please try again in 5 minutes.',
	        26=>'An error occurred during processing. Please try again in 5 minutes.',
	        27=>'The transaction resulted in an AVS mismatch. The address provided does not match billing address of cardholder.',
	        28=>'The merchant does not accept this type of credit card.|The Merchant ID at the processor was not configured to accept this card type.',
	        29=>'The Paymentech identification numbers are incorrect. Call Merchant Service Provider.',
	        30=>'The configuration with the processor is invalid. Call Merchant Service Provider.',
	        31=>'The FDC Merchant ID or Terminal ID is incorrect. Call Merchant Service Provider.|The merchant was incorrectly set up at the processor.',
	        32=>'This reason code is reserved or not applicable to this API.',
	        33=>'FIELD cannot be left blank.|The word FIELD will be replaced by an actual field name. This error indicates that a field the merchant specified as required was not filled in.',
	        34=>'The VITAL identification numbers are incorrect. Call Merchant Service Provider.|The merchant was incorrectly set up at the processor.',
	        35=>'An error occurred during processing. Call Merchant Service Provider.|The merchant was incorrectly set up at the processor.',
	        36=>'The authorization was approved, but settlement failed.',
	        37=>'The credit card number is invalid.',
	        38=>'The Global Payment System identification numbers are incorrect. Call Merchant Service Provider.|The merchant was incorrectly set up at the processor.',
	        39=>'The supplied currency code is either invalid, not supported, not allowed for this merchant or doesn?t have an exchange rate.',
	        40=>'This transaction must be encrypted.',
	        41=>'This transaction has been declined.|Only merchants set up for the FraudScreen.Net service would receive this decline. This code will be returned if a given transaction?s fraud score is higher than the threshold set by the merchant.',
	        42=>'There is missing or invalid information in a required field.|This is applicable only to merchants processing through the Wells Fargo SecureSource product who have requirements for transaction submission that are different from merchants not processing through Wells Fargo.',
	        43=>'The merchant was incorrectly set up at the processor. Call your Merchant Service Provider.|The merchant was incorrectly set up at the processor.',
	        44=>'This transaction has been declined.|The card code submitted with the transaction did not match the card code on file at the card issuing bank and the transaction was declined.',
	        45=>'This transaction has been declined.|This error would be returned if the transaction received a code from the processor that matched the rejection criteria set by the merchant for both the AVS and Card Code filters.',
	        46=>'Your session has expired or does not exist. You must log in to continue working.',
	        47=>'The amount requested for settlement may not be greater than the original amount authorized.|This occurs if the merchant tries to capture funds greater than the amount of the original authorization-only transaction.',
	        48=>'This processor does not accept partial reversals.|The merchant attempted to settle for less than the originally authorized amount.',
	        49=>'A transaction amount greater than $[amount] will not be accepted.|The transaction amount submitted was greater than the maximum amount allowed. ',
	        50=>'This transaction is awaiting settlement and cannot be refunded.|Credits or refunds may only be performed against settled transactions. The transaction against which the credit/refund was submitted has not been settled, so a credit cannot be issued.',
	        51=>'The sum of all credits against this transaction is greater than the original transaction amount.',
	        52=>'The transaction was authorized, but the client could not be notified; the transaction will not be settled.',
	        53=>'The transaction type was invalid for ACH transactions.|If x_method = ECHECK, x_type cannot be set to CAPTURE_ONLY.',
	        54=>'The referenced transaction does not meet the criteria for issuing a credit.',
	        55=>'The sum of credits against the referenced transaction would exceed the original debit amount.|The transaction is rejected if the sum of this credit and prior credits exceeds the original debit amount',
	        56=>'This merchant accepts ACH transactions only; no credit card transactions are accepted.|The merchant processes eCheck.Net transactions only and does not accept credit cards.',
	        57=>'An error occurred in processing. Please try again in 5 minutes.',
	        58=>'An error occurred in processing. Please try again in 5 minutes.',
	        59=>'An error occurred in processing. Please try again in 5 minutes.',
	        60=>'An error occurred in processing. Please try again in 5 minutes.',
	        61=>'An error occurred in processing. Please try again in 5 minutes.',
	        62=>'An error occurred in processing. Please try again in 5 minutes.',
	        63=>'An error occurred in processing. Please try again in 5 minutes.',
	        64=>'The referenced transaction was not approved.|This error is applicable to Wells Fargo SecureSource merchants only. Credits or refunds cannot be issued against transactions that were not authorized.',
	        65=>'This transaction has been declined.|The transaction was declined because the merchant configured their account through the Merchant Interface to reject transactions with certain values for a Card Code mismatch.',
	        66=>'This transaction cannot be accepted for processing.|The transaction did not meet gateway security guidelines.',
	        67=>'The given transaction type is not supported for this merchant.|This error code is applicable to merchants using the Wells Fargo SecureSource product only. This product does not allow transactions of type CAPTURE_ONLY.',
	        68=>'The version parameter is invalid.|The value submitted in x_version was invalid.',
	        69=>'The transaction type is invalid.|The value submitted in x_type was invalid.',
	        70=>'The transaction method is invalid.|The value submitted in x_method was invalid.',
	        71=>'The bank account type is invalid.|The value submitted in x_bank_acct_type was invalid.',
	        72=>'The authorization code is invalid.|The value submitted in x_auth_code was more than six characters in length.',
	        73=>'The drivers license date of birth is invalid.|The format of the value submitted in x_drivers_license_dob was invalid.',
	        74=>'The duty amount is invalid.|The value submitted in x_duty failed format validation.',
	        75=>'The freight amount is invalid.|The value submitted in x_freight failed format validation.',
	        76=>'The tax amount is invalid.|The value submitted in x_tax failed format validation.',
	        77=>'The SSN or tax ID is invalid.|The value submitted in x_customer_tax_id failed validation.',
	        78=>'The Card Code (CVV2/CVC2/CID) is invalid.|The value submitted in x_card_code failed format validation.',
	        79=>'The driver`s license number is invalid.|The value submitted in x_drivers_license_num failed format validation.',
	        80=>'The driver`s license state is invalid.|The value submitted in x_drivers_license_state failed format validation.',
	        81=>'The requested form type is invalid.|The merchant requested an integration method not compatible with the AIM API.',
	        82=>'Scripts are only supported in version 2.5.|The system no longer supports version 2.5; requests cannot be posted to scripts.',
	        83=>'The requested script is either invalid or no longer supported.|The system no longer supports version 2.5; requests cannot be posted to scripts.',
	        84=>'This reason code is reserved or not applicable to this API.',
	        85=>'This reason code is reserved or not applicable to this API.',
	        86=>'This reason code is reserved or not applicable to this API.',
	        87=>'This reason code is reserved or not applicable to this API.',
	        88=>'This reason code is reserved or not applicable to this API.',
	        89=>'This reason code is reserved or not applicable to this API.',
	        90=>'This reason code is reserved or not applicable to this API.',
	        91=>'Version 2.5 is no longer supported.',
	        92=>'The gateway no longer supports the requested method of integration.',
	        93=>'A valid country is required.|This code is applicable to Wells Fargo SecureSource merchants only. Country is a required field and must contain the value of a supported country.',
	        94=>'The shipping state or country is invalid.|This code is applicable to Wells Fargo SecureSource merchants only.',
	        95=>'A valid state is required.|This code is applicable to Wells Fargo SecureSource merchants only.',
	        96=>'This country is not authorized for buyers.|This code is applicable to Wells Fargo SecureSource merchants only. Country is a required field and must contain the value of a supported country.',
	        97=>'This transaction cannot be accepted.|Applicable only to SIM API.|Fingerprints are only valid for a short period of time. This code indicates that the transaction fingerprint has expired.',
	        98=>'This transaction cannot be accepted.|Applicable only to SIM API. The transaction fingerprint has already been used.',
	        99=>'This transaction cannot be accepted.|Applicable only to SIM API. The server-generated fingerprint does not match the merchant-specified fingerprint in the x_fp_hash field.',
	        100=>'The eCheck.Net type is invalid.|Applicable only to eCheck.Net. The value specified in the x_echeck_type field is invalid.',
	        101=>'The given name on the account and/or the account type does not match the actual account.|Applicable only to eCheck.Net. The specified name on the account and/or the account type do not match the NOC record for this account.',
	        102=>'This request cannot be accepted.|A password or Transaction Key was submitted with this WebLink request. This is a high security risk.',
	        103=>'This transaction cannot be accepted.|A valid fingerprint, Transaction Key, or password is required for this transaction.',
	        104=>'This transaction is currently under review.|Applicable only to eCheck.Net. The value submitted for country failed validation.',
	        105=>'This transaction is currently under review.|Applicable only to eCheck.Net. The values submitted for city and country failed validation.',
	        106=>'This transaction is currently under review.|Applicable only to eCheck.Net. The value submitted for company failed validation.',
	        107=>'This transaction is currently under review.|Applicable only to eCheck.Net. The value submitted for bank account name failed validation.',
	        108=>'This transaction is currently under review.|Applicable only to eCheck.Net. The values submitted for first name and last name failed validation.',
	        109=>'This transaction is currently under review.|Applicable only to eCheck.Net. The values submitted for first name and last name failed validation.',
	        110=>'This transaction is currently under review.|Applicable only to eCheck.Net. The value submitted for bank account name does not contain valid characters.',
	        111=>'A valid billing country is required.|This code is applicable to Wells Fargo SecureSource merchants only.',
	        112=>'A valid billing state/province is required.|This code is applicable to Wells Fargo SecureSource merchants only.',
	        116=>'The authentication indicator is invalid.|This error is only applicable to Verified by Visa and MasterCard SecureCode transactions. The ECI value for a Visa transaction; or the UCAF indicator for a MasterCard transaction submitted in the x_authentication_indicator field is invalid.',
	        117=>'The cardholder authentication value is invalid.|This error is only applicable to Verified by Visa and MasterCard SecureCode transactions. The CAVV for a Visa transaction; or the AVV/UCAF for a MasterCard transaction is invalid.',
	        118=>'The combination of authentication indicator and cardholder authentication value is invalid.|This error is only applicable to Verified by Visa and MasterCard SecureCode transactions. The combination of authentication indicator and cardholder authentication value for a Visa or MasterCard transaction is invalid. For more information, see the ?Cardholder Authentication? section of this document.',
	        119=>'Transactions having cardholder authentication values cannot be marked as recurring.|This error is only applicable to Verified by Visa and MasterCard SecureCode transactions. Transactions submitted with a value in x_authentication_indicator and x_recurring_billing=YES will be rejected.',
	        120=>'An error occurred during processing. Please try again.|The system-generated void for the original timed-out transaction failed. (The original transaction timed out while waiting for a response from the authorizer.)',
	        121=>'An error occurred during processing. Please try again.|The system-generated void for the original errored transaction failed. (The original transaction experienced a database error.)',
	        122=>'An error occurred during processing. Please try again.|The system-generated void for the original errored transaction failed. (The original transaction experienced a processing error.)',
	        123=>'This account has not been given the permission(s) required for this request.|The transaction request must include the API Login ID associated with the payment gateway account.',
	        127=>'The transaction resulted in an AVS mismatch. The address provided does not match billing address of cardholder.|The system-generated void for the original AVS-rejected transaction failed.',
	        128=>'This transaction cannot be processed.|The customer`s financial institution does not currently allow transactions for this account.',
	        130=>'This payment gateway account has been closed.|IFT: The payment gateway account status is Blacklisted.',
	        131=>'This transaction cannot be accepted at this time.|IFT: The payment gateway account status is Suspended-STA.',
	        132=>'This transaction cannot be accepted at this time.|IFT: The payment gateway account status is Suspended-Blacklist.',
	        141=>'This transaction has been declined.|The system-generated void for the original FraudScreen-rejected transaction failed.',
	        145=>'This transaction has been declined.|The system-generated void for the original card code-rejected and AVS-rejected transaction failed. ',
	        152=>'The transaction was authorized, but the client could not be notified; the transaction will not be settled.|The system-generated void for the original transaction failed. The response for the original transaction could not be communicated to the client.',
	        165=>'This transaction has been declined.|The system-generated void for the original card code-rejected transaction failed.',
	        170=>'An error occurred during processing. Please contact the merchant.|Concord EFS - Provisioning at the processor has not been completed.',
	        171=>'An error occurred during processing. Please contact the merchant.|Concord EFS - This request is invalid.',
	        172=>'An error occurred during processing. Please contact the merchant.|Concord EFS - The store ID is invalid.',
	        173=>'An error occurred during processing. Please contact the merchant.|Concord EFS - The store key is invalid.',
	        174=>'The transaction type is invalid. Please contact the merchant.|Concord EFS - This transaction type is not accepted by the processor.',
	        175=>'The processor does not allow voiding of credits.|Concord EFS - This transaction is not allowed. The Concord EFS processing platform does not support voiding credit transactions. Please debit the credit card instead of voiding the credit.',
	        180=>'An error occurred during processing. Please try again.|The processor response format is invalid.',
	        181=>'An error occurred during processing. Please try again.|The system-generated void for the original invalid transaction failed. (The original transaction included an invalid processor response format.)',
	        185=>'This reason code is reserved or not applicable to this API.',
	        193=>'The transaction is currently under review.|The transaction was placed under review by the risk management system.',
	        200=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The credit card number is invalid.',
	        201=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The expiration date is invalid.',
	        202=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The transaction type is invalid.',
	        203=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The value submitted in the amount field is invalid.',
	        204=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The department code is invalid.',
	        205=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The value submitted in the merchant number field is invalid.',
	        206=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The merchant is not on file.',
	        207=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The merchant account is closed.',
	        208=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The merchant is not on file.',
	        209=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. Communication with the processor could not be established.',
	        210=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The merchant type is incorrect.',
	        211=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The cardholder is not on file.',
	        212=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The bank configuration is not on file',
	        213=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The merchant assessment code is incorrect.',
	        214=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. This function is currently unavailable.',
	        215=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The encrypted PIN field format is invalid.',
	        216=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The ATM term ID is invalid.',
	        217=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. This transaction experienced a general message format problem.',
	        218=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The PIN block format or PIN availability value is invalid.',
	        219=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The ETC void is unmatched.',
	        220=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The primary CPU is not available.',
	        221=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. The SE number is invalid.',
	        222=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. Duplicate auth request (from INAS).',
	        223=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. This transaction experienced an unspecified error.',
	        224=>'This transaction has been declined.|This error code applies only to merchants on FDC Omaha. Please re-enter the transaction.',
	        243=>'Recurring billing is not allowed for this eCheck.Net type.|The combination of values submitted for x_recurring_billing and x_echeck_type is not allowed.',
	        244=>'This eCheck.Net type is not allowed for this Bank Account Type.|The combination of values submitted for x_bank_acct_type and x_echeck_type is not allowed.',
	        245=>'This eCheck.Net type is not allowed when using the payment gateway hosted payment form.|The value submitted for x_echeck_type is not allowed when using the payment gateway hosted payment form.',
	        246=>'This eCheck.Net type is not allowed.|The merchant`s payment gateway account is not enabled to submit the eCheck.Net type.',
	        247=>'This eCheck.Net type is not allowed.|The combination of values submitted for x_type and x_echeck_type is not allowed.',
	        248=>'The check number is invalid.|Invalid check number. Check number can only consist of letters and numbers and not more than 15 characters.',
	        250=>'This transaction has been declined.|This transaction was submitted from a blocked IP address.',
	        251=>'This transaction has been declined.|The transaction was declined as a result of triggering a Fraud Detection Suite filter.',
	        252=>'Your order has been received. Thank you for your business!|The transaction was accepted, but is being held for merchant review. The merchant may customize the customer response in the Merchant Interface.',
	        253=>'Your order has been received. Thank you for your business!|The transaction was accepted and was authorized, but is being held for merchant review. The merchant may customize the customer response in the Merchant Interface.',
	        254=>'Your transaction has been declined.|The transaction was declined after manual review.',
	        261=>'An error occurred during processing. Please try again.|The transaction experienced an error during sensitive data encryption and was not processed. Please try again.',
	        270=>'The line item [item number] is invalid.|A value submitted in x_line_item for the item referenced is invalid.',
	        271=>'The number of line items submitted is not allowed. A maximum of 30 line items can be submitted.|The number of line items submitted exceeds the allowed maximum of 30.'        
	    };

	    if (reasonStrings.containsKey(code)) {
	        String result;
	        if (detailLevel.equalsIgnoreCase('Detailed')) { // return long version
	            result = reasonStrings.get(code).replace('|', ' '); // hide the brief/detailed response divider.
	        } else { // return brief version
	            result = reasonStrings.get(code).split('|')[0];  // return only text preceding the brief/detailed response divider.
	        }
	        return result;
	    } else return 'Reason code not recognized.';
	}	
}