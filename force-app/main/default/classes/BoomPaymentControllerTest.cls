@isTest
public with sharing class BoomPaymentControllerTest {
    @isTest
    public static void testMethod1() {
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
      'Completed'
    );
    BoomPaymentController testController = new BoomPaymentController();
    testController.paymentId = testPayment.Id;

    }

}