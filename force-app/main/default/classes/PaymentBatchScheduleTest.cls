@isTest
private with sharing class PaymentBatchScheduleTest {
  @testSetup
  static void setup() {
    Account testacct = BoomTestHelpers.generateAccount();
    Contact testContact = BoomTestHelpers.generateContact(testacct.Id);
    Payment_Method__c testPm = BoomTestHelpers.generateTestPmtMethod(
      testContact.Id,
      false
    );
    Product2 testProd = BoomTestHelpers.generateProduct();
    PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(
      testProd.Id
    );
    Market__c testMkt = BoomTestHelpers.generateMarket(
      testPbe.Pricebook2Id,
      true
    );
    Opportunity testOpp = BoomTestHelpers.generateOpportunity(
      testacct.Id,
      testMkt.Id,
      testContact.Id
    );
    SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
    SalesOrderProductLine__c testSoProd = BoomTestHelpers.generateBoomProductLine(
      testSo.Id,
      testPbe
    );
    testSo.Status_Picklist__c = 'Approved';

    update testSo;

    Payment__c testPayment = BoomTestHelpers.generateTestPayment(
      testSo.Id,
      testacct.Id,
      testContact.Id,
      testPm.Id,
      1,
      'Scheduled'
    );

    testPayment.Scheduled_Payment_Date__c = Date.today();

    update testPayment;
  }
  static testMethod void testSchedule() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

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
      new PaymentBatchSchedule()
    );
    Test.stopTest();

    List<AsyncApexJob> jobsScheduled = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'ScheduledApex'
    ];
    System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
    System.assertEquals(
      'PaymentBatchSchedule',
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
      'PaymentBatchable',
      jobsApexBatch[0].ApexClass.Name,
      'expecting specific batch job'
    );
  }
  static testMethod void testBatch() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

    Test.startTest();

    String queryString = 'SELECT Id, Sales_Order__c, Contact__c, Contact__r.Email, Payment_Method__r.Merchant_Token__c, Amount__c FROM Payment__c WHERE Status__c = \'Scheduled\' AND Scheduled_Payment_Date__c <= TODAY LIMIT 1';

    Payment__c samplePayment = Database.query(queryString);
    PaymentBatchableHelper.sendEmail('Declined', samplePayment.Id, samplePayment.Contact__c, samplePayment.Contact__r.Email, samplePayment.Sales_Order__c, true);
    EmailTemplate e = new EmailTemplate(
      developerName = 'test',
      FolderId = UserInfo.getUserId(),
      TemplateType = 'Text',
      Name = 'New_Credit_Card_Declined'
    );
    insert e;
    Database.executeBatch(new PaymentBatchable());
    Test.stopTest();
  }

  static testMethod void testBatch2() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

    Test.startTest();

    String queryString = 'SELECT Id, Sales_Order__c, Contact__c, Contact__r.Email, Payment_Method__r.Merchant_Token__c, Amount__c FROM Payment__c WHERE Status__c = \'Scheduled\' AND Scheduled_Payment_Date__c <= TODAY LIMIT 1';
    
    Payment__c samplePayment = Database.query(queryString);
    SalesOrder__c testOrder = [SELECT Id FROM SalesOrder__c WHERE Id = :samplePayment.Sales_Order__c];
    testOrder.Send_Invoice_to_Alternate_Contact__c = true;
    testOrder.Alternate_Contact_Email__c = 'test@email.ua';

    update testOrder;

    PaymentBatchableHelper.sendEmail('Approved', samplePayment.Id, samplePayment.Contact__c, samplePayment.Contact__r.Email, samplePayment.Sales_Order__c, true);
    
    Database.executeBatch(new PaymentBatchable());
    Test.stopTest();
  }
}