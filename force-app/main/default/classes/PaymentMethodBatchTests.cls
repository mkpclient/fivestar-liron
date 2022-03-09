@isTest
private with sharing class PaymentMethodBatchTests {
  static testMethod void testSchedule() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
    Account testacct = BoomTestHelpers.generateAccount();
    Contact testContact = BoomTestHelpers.generateContact(testacct.Id);
    Payment_Method__c testPm = BoomTestHelpers.generateTestPmtMethod(
      testContact.Id,
      false
    );
    testPm.Expiration_Date__c = System.today();
    update testPm;

    String cronExpr = '0 0 0 15 3 ? 2022';
    List<AsyncApexJob> jobsBefore = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
    ];
    System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
    Test.startTest();
    String jobId = System.schedule(
      'myJobTestJobName',
      cronExpr,
      new PaymentMethodSchedule()
    );
    Test.stopTest();

    List<AsyncApexJob> jobsScheduled = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'ScheduledApex'
    ];
    System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
    System.assertEquals(
      'PaymentMethodSchedule',
      jobsScheduled[0].ApexClass.Name,
      'expecting specific scheduled job'
    );

    // check apex batch is in the job list
    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex'
    ];
    System.assertEquals(
      1,
      jobsApexBatch.size(),
      'expecting one apex batch job'
    );
    System.assertEquals(
      'PaymentMethodBatch',
      jobsApexBatch[0].ApexClass.Name,
      'expecting specific batch job'
    );
    
  }

  static testMethod void testBatch() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
    List<Account> testAccts = new List<Account>();
    for(Integer i = 0; i < 50; i++) {
        Account account = new Account(
            Name = 'Test Account ' + i,
            Type = 'Customer - Direct',
            BillingStreet = '555 Jacobs Street',
            BillingState = 'PA',
            BillingPostalCode = '15219',
            BillingCity = 'Pittsburgh',
            BillingCountry = 'United States',
            ShippingStreet = '555 Jacobs Street',
            ShippingCity = 'Pittsburgh',
            ShippingState = 'PA',
            ShippingPostalCode = '15219',
            ShippingCountry = 'United States',
            Phone = '(412) 338-1168',
            Fax = '(412) 338-1168',
            AccountNumber = 'Test Account ' + i,
            Industry = 'Apparel',
            AnnualRevenue = 350000000,
            NumberOfEmployees = 9000,
            Ownership = 'Public',
            TickerSymbol = 'BTXT',
            Description = 'Test Account',
            Site = ''
        );
        testAccts.add(account);
    }

    insert testAccts;

    List<Contact> testContacts = new List<Contact>();
    for(Account a : testAccts) {
        testContacts.add(new Contact(
            AccountId = a.Id,
            FirstName = 'Jane',
            LastName = 'Doe ' + a.Id,
            Email = 'jdoe@testmail.com.ua',
            Phone = '(123) 456-7890',
            MailingStreet = '555 Jacobs Street',
            MailingState = 'PA',
            MailingCity = 'Pittsburgh',
            MailingPostalCode = '15219',
            MailingCountry = 'United States',
            MX_Customer_Id__c = '2222222'
          ));
    }

    insert testContacts;

    List<Payment_Method__c> testPms = new List<Payment_Method__c>();
    for(Contact c : testContacts) {
        testPms.add(new Payment_Method__c(
            Billing_Street__c = '555 Jacobs Street',
            Billing_City__c = 'Pittsburgh',
            Billing_Last_Name__c = 'Doe',
            Billing_First_Name__c = 'Jane',
            Last_4_Digits_of_Card__c = '1234',
            Billing_Country__c = 'United States',
            Billing_State__c = 'PA',
            Billing_Postal_Code__c = '15219',
            Card_Type__c = 'Visa',
            Payment_Processor__c = 'MX Merchant',
            Contact__c = c.Id,
            Expiration_Date__c = System.today(),
            Default__c = false,
            Merchant_Token__c = 'test',
            ExternalId__c = '1234'
            ));
        }

    insert testPms;

    Test.startTest();
    Database.executeBatch(new PaymentMethodBatch(), 50);
    Test.stopTest();
    List<Payment_Method__c> updatedPms = [SELECT Id, Expiration_Date__c FROM Payment_Method__c WHERE Expiration_Date__c = THIS_YEAR];

    System.assertEquals(0, updatedPms.size(), 'should have no more Pms with expiration date this year');
  }
}