@isTest
public with sharing class SubscriptionTests {
    @TestSetup
    static void makeData(){
        Product2 renewalProduct = BoomTestHelpers.generateProduct();
        Product2 subscriptionProd = BoomTestHelpers.createSubscriptionProduct(renewalProduct);
        Product2 addonProd = BoomTestHelpers.createAddonProduct();
        PricebookEntry pbE1 = BoomTestHelpers.generatePriceBookEntry(renewalProduct.Id);
        PricebookEntry pbE2 = BoomTestHelpers.generatePriceBookEntry(subscriptionProd.Id);
        PricebookEntry pbE3 = BoomTestHelpers.generatePriceBookEntry(addonProd.Id);
        Market__c mkt = BoomTestHelpers.generateMarket(pbe1.Pricebook2Id, true);
        Account a = BoomTestHelpers.generateAccount();
        Contact c = BoomTestHelpers.generateContact(a.Id);
        Opportunity o = BoomTestHelpers.generateOpportunity(a.Id, mkt.Id, c.Id);
        SalesOrder__c so = BoomTestHelpers.generateTestBoomOrder(o.Id);
        SalesOrderProductLine__c sopl = BoomTestHelpers.generateBoomProductLine(so.Id, pbE2);
        SalesOrderProductLine__c sopl2 = BoomTestHelpers.generateBoomProductLine(so.Id, pbE3);

        so.Status_Picklist__c = 'Approved';

        update so;

        Payment_Method__c pm = BoomTestHelpers.generateTestPmtMethod(c.Id, true);
    }
    @isTest
    public static void testSubscriptionMethod() {
      Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
        SalesOrder__c so = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c LIMIT 1];
        Payment_Method__c pm = [SELECT Id FROM Payment_Method__c LIMIT 1];
        Test.startTest();
        Payment__c testPmt = BoomTestHelpers.generateTestPayment(so.Id, so.Account__c, so.ContactBilling__c, pm.Id, 100, 'Completed');
        Test.stopTest();

        List<Subscription__c> subs = [SELECT Id,Subscription_Fulfillment__c FROM Subscription__c];
        System.assertEquals(true, subs.size() > 0, 'Subscription__c records were not created');

        subs[0].Status__c = 'Cancelled';
        update subs[0];

        Fulfillment__c f = [SELECT Id, Status__c FROM Fulfillment__c WHERE Id = :subs[0].Subscription_Fulfillment__c LIMIT 1];

        System.assertEquals('Subscription Cancelled', f.Status__c, 'Fulfillment status was not set to Subscription Cancelled');
    }

    @isTest
    public static void testSubscriptionSchedule() {
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

        String cronExpr = '0 0 0 15 3 ? 2060';
        List<AsyncApexJob> jobsBefore = [
          SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
          FROM AsyncApexJob
        ];
        System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');
        Test.startTest();
        String jobId = System.schedule(
          'myJobTestJobName',
          cronExpr,
          new SubscriptionBatchSchedule()
        );
        Test.stopTest();
    
        List<AsyncApexJob> jobsScheduled = [
          SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
          FROM AsyncApexJob
          WHERE JobType = 'ScheduledApex'
        ];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals(
          'SubscriptionBatchSchedule',
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
          2,
          jobsApexBatch.size(),
          'expecting two apex batch jobs'
        );

    }

    @isTest
    public static void testSubscriptionBatch() {
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
        
        SalesOrder__c so = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c LIMIT 1];
        Payment_Method__c pm = [SELECT Id FROM Payment_Method__c LIMIT 1];

        Test.startTest();
        Payment__c testPmt = BoomTestHelpers.generateTestPayment(so.Id, so.Account__c, so.ContactBilling__c, pm.Id, 100, 'Completed');
        Test.stopTest();
        SalesOrder__c renewalOrder = [SELECT Id FROM SalesOrder__c WHERE Status_Picklist__c = 'Pending Renewal' LIMIT 1];
        renewalOrder.OrderDate__c = System.today();
        update renewalOrder;
        Database.executeBatch(new SubscriptionOrdersBatch(), 1);
    }

    @isTest
    public static void testSubscriptionBatchDeclined() {
      Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGeneratorDeclined());
      SalesOrder__c so = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c LIMIT 1];
      Payment_Method__c pm = [SELECT Id FROM Payment_Method__c LIMIT 1];

      Test.startTest();
      Payment__c testPmt = BoomTestHelpers.generateTestPayment(so.Id, so.Account__c, so.ContactBilling__c, pm.Id, 100, 'Completed');
      Test.stopTest();
      SalesOrder__c renewalOrder = [SELECT Id FROM SalesOrder__c WHERE Status_Picklist__c = 'Pending Renewal' LIMIT 1];
      renewalOrder.OrderDate__c = System.today();
      update renewalOrder;
      Database.executeBatch(new SubscriptionOrdersBatch(), 1);

    }

    @isTest
    public static void testSubscriptionStatusBatch() {
        
        SalesOrder__c so = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c LIMIT 1];
        Payment_Method__c pm = [SELECT Id FROM Payment_Method__c LIMIT 1];

        Test.startTest();
        Payment__c testPmt = BoomTestHelpers.generateTestPayment(so.Id, so.Account__c, so.ContactBilling__c, pm.Id, 100, 'Completed');
        Test.stopTest();
        Subscription__c generatedSub = [SELECT Id FROM Subscription__c LIMIT 1];
        generatedSub.End_Date__c = System.today();
        update generatedSub;
        Database.executeBatch(new SubscriptionStatusBatch(), 1);
    }

    @isTest
    public static void testChainedQueue() { 
      List<SalesOrder__c> so = [SELECT Id, Account__c, ContactBilling__c FROM SalesOrder__c];
      List<Payment_Method__c> pm = [SELECT Id FROM Payment_Method__c];
      Test.startTest();
      System.enqueueJob(new BoomSubscriptionPaymentsQueuable(so, pm));
      Test.stopTest();
      
    }
}