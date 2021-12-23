@isTest
public with sharing class Payment2ReceiptTest {
    @isTest
    private static void testMethod1() {
        Account testAcc = BoomTestHelpers.generateAccount();
        Contact testCtc = BoomTestHelpers.generateContact(testAcc.Id);
        Product2 testPdc = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePriceBookEntry(testPdc.Id);
        Market__c testMkt = BoomTestHelpers.generateMarket(testPbe.Pricebook2Id, true);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(testAcc.Id, testMkt.Id, testCtc.Id);
        SalesOrder__c testSo = BoomTestHelpers.generateTestBoomOrder(testOpp.Id);
        SalesOrderProductLine__c testProdLine = BoomTestHelpers.generateBoomProductLine(testSo.Id, testPbe);
        Payment_Method__c testPmtMethod = BoomTestHelpers.generateTestPmtMethod(testCtc.Id, false);
        Payment__c testPmt = BoomTestHelpers.generateTestPayment(testSo.Id, testAcc.Id, testCtc.Id, testPmtMethod.Id, 50, 'Completed');
        Pagereference testPageRef = Page.Payment2VF;
        Test.setCurrentPage(testPageRef);
        Payment2ReceiptController controller = new Payment2ReceiptController();
        ApexPages.currentPage().getParameters().put('orderId', testSo.Id);
        ApexPages.currentPage().getParameters().put('paymentId', testPmt.Id);
        System.assertEquals(testSo.Id, controller.SalesOrder.Id, 'Sales order Ids should match');
        System.assertEquals(1, controller.OrderPayments.size(), 'Payment count should be 1');
        System.assertEquals(testPmtMethod.Id, controller.paymentMethod.Id, 'Payment method Ids should match');
        Pagereference pf = controller.attachPDF();
    }
}