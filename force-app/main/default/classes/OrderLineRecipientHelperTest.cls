@isTest
public with sharing class OrderLineRecipientHelperTest {
    @isTest
    private static void testBeforeInsert() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Product2 testPrd = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(testPrd.Id);
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        Test.startTest();
        SalesOrderProductLine__c testSoPrdLn = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        Order_Line_Recipient__c testRecipient = BoomTestHelpers.generateTestLineRecipient(testSo.Id, testSoPrdLn.Id, testCtc.Id, true);
        Order_Line_Recipient__c queriedRecipient = [SELECT Id, Market__c, AccountManager__c FROM Order_Line_Recipient__c WHERE Id = :testRecipient.Id LIMIT 1];
        Id accOwner = [SELECT OwnerId FROM Account WHERE Id = :testAcc.Id LIMIT 1].OwnerId;
        System.assertEquals(accOwner, queriedRecipient.AccountManager__c, 'Account owner should be set to the account manager');
        System.assertEquals(queriedRecipient.Market__c, testMkt.Id, 'Market should be set to the market of the sales order');
        Test.stopTest();
    }

    @isTest
    private static void testAfterInsertAndDelete() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Account testAcc2 = BoomTestHelpers.generateAccount();

        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Contact testCtc2 = BoomTestHelpers.generateContact(testAcc.Id);

        Product2 testPrd = BoomTestHelpers.generateProduct();
        Product2 testPrd2 = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(testPrd.Id);
        PricebookEntry testPbe2 = BoomTestHelpers.generatePricebookEntry(testPrd2.Id);
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        Kit_Bundle_Member__c testKbm = BoomTestHelpers.generateTestKitBundle(testPrd.Id, testPrd2.Id);
        SalesOrderProductLine__c testSoPrdLn = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        Order_Line_Recipient__c testRecipient = BoomTestHelpers.generateTestLineRecipient(testSo.Id, testSoPrdLn.Id, testCtc.Id, true);
        Order_Line_Recipient__c testRecipient2 = BoomTestHelpers.generateTestLineRecipient(testSo.Id, testSoPrdLn.Id, testCtc2.Id, false);

        List<Order_Line_Recipient__c> queriedRecipients = [SELECT Id FROM Order_Line_Recipient__c WHERE Order__c = :testSo.Id];
        List<Order_Line_Recipient__c> queriedRecipientsForSopl = [SELECT Id FROM Order_Line_Recipient__c WHERE OrderProductLine__c = :testSoPrdLn.Id];
        SalesOrderProductLine__c queriedSoPrdLn = [SELECT Id, Recipient_Count__c FROM SalesOrderProductLine__c WHERE Id = :testSoPrdLn.Id];
        System.assertEquals(queriedRecipients.size() > 0, true, 'There should be more than one recipient for the sales order');
        System.assertEquals(queriedSoPrdLn.Recipient_Count__c, queriedRecipientsForSopl.size(), 'The recipient count for the sales order product line should be equal to the number of recipients');
        Test.startTest();
        delete queriedRecipientsForSopl;
        Test.stopTest();
        SalesOrderProductLine__c queriedSoPrdLn2 = [SELECT Id, Recipient_Count__c FROM SalesOrderProductLine__c WHERE Id = :testSoPrdLn.Id];
        System.assertEquals(queriedSoPrdLn2.Recipient_Count__c, 0, 'The recipient count for the sales order product line should be zero after the recipient is deleted');
    }

    @isTest
    private static void testAfterUpdate() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Product2 testPrd = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(testPrd.Id);
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        Test.startTest();
        SalesOrderProductLine__c testSoPrdLn = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        Order_Line_Recipient__c testRecipient = BoomTestHelpers.generateTestLineRecipient(testSo.Id, testSoPrdLn.Id, testCtc.Id, true);
        SalesOrderProductLine__c testSoPrdLn2 = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        testRecipient.OrderProductLine__c = testSoPrdLn2.Id;
        update testRecipient;
        List<Order_Line_Recipient__c> queriedRecipients = [SELECT Id FROM Order_Line_Recipient__c WHERE OrderProductLine__c = :testSoPrdLn.Id AND Id = :testRecipient.Id];
        System.assertEquals(queriedRecipients.size() == 0, true, 'The recipient should not be in the list of recipients for the old sales order product line');
        Test.stopTest();
    }
}