/*****************************************************************************************
*    Class Name:        kuga_AuthNetEmailProcessorTests
*
*    Class Type:        Test class
*    
*    Description:       This class is a test class for kuga_AuthNetEmailProcessor
*
*   Test Methods:       kuga_AuthNetEmailProcessorTests
*
*   Class History:      Created by Kiran Kurella Dec 8th 2017
*
*   Copyright 2017 Kugamon.  All rights reserved.
*****************************************************************************************/

@isTest //(SeeAllData=true)
public class kuga_AuthNetEmailProcessorTests {

	static @isTest void test_MassEmailInvoiceBatcher_Test1() {

    	ManageLinesTests.DataSetup();

        // switch to test context
        Test.startTest();

		// Completed Payment with Recurring charge
		map<String, kugo2p__PaymentX__c> Payments = new map<String, kugo2p__PaymentX__c> {
											'123' => new kugo2p__PaymentX__c(Name = 'Test Payment 1', kugo2p__Payment_Profile__c = ManageLinesTests.RecurringCharge.Id, kugo2p__Amount__c = 125.00, 
																			kugo2p__Status__c = 'Completed', kugo2p__Payment_processor__c = 'Authorize.Net', kugo2p__Transaction_Id__c='123')
										};

    	// kick off the job
    	kuga_AuthNetEmailProcessor.startJob(Payments);

        // switch back to runtime context
        Test.stopTest();
    }

	static @isTest void test_MassEmailInvoiceBatcher_Test2() {

    	ManageLinesTests.DataSetup();

        // switch to test context
        Test.startTest();

		// Declined Payment with Recurring charge
		map<String, kugo2p__PaymentX__c> Payments = new map<String, kugo2p__PaymentX__c> {
											'123' => new kugo2p__PaymentX__c(Name = 'Test Payment 1', kugo2p__Payment_Profile__c = ManageLinesTests.RecurringCharge.Id, kugo2p__Amount__c = 125.00, 
																			kugo2p__Status__c = 'Declined', kugo2p__Payment_processor__c = 'Authorize.Net', kugo2p__Transaction_Id__c='123'
																			// throw an error - set Contact Id for Account field 
																			//, kugo2p__Account__c = ManageLinesTests.Contacts[0].Id
																			)
										};

    	// kick off the job
    	kuga_AuthNetEmailProcessor.startJob(Payments);

        // switch back to runtime context
        Test.stopTest();
    }    
}