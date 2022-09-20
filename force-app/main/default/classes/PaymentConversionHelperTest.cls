@isTest(SeeAllData=True)
public without sharing class PaymentConversionHelperTest {
    @isTest
    public static void PaymentConversionHelperTest() {
        kugo2p__SalesOrder__c so = [SELECT Id FROM kugo2p__SalesOrder__c LIMIT 1];

        Product2 testProd = BoomTestHelpers.generateProduct();
        PricebookEntry testPbe = BoomTestHelpers.generatePricebookEntry(
          testProd.Id
        );
        Market__c testMarket = BoomTestHelpers.generateMarket(
          testPbe.Pricebook2Id,
          true
        );
        Account testAcct = BoomTestHelpers.generateAccount();
        Contact testCont = BoomTestHelpers.generateContact(testAcct.Id);
        Opportunity testOpp = BoomTestHelpers.generateOpportunity(
          testAcct.Id,
          testMarket.Id,
          testCont.Id
        );

        List<SalesOrder__c> soList = [SELECT Id FROM SalesOrder__c WHERE Legacy_Id__c = :so.Id  LIMIT 1];
            
        SalesOrder__c testSo;
        
        if(soList.size() > 0) {
            testSo = soList[0];
        } else {
            testSo = BoomTestHelpers.generateTestBoomOrder(
                testOpp.Id
              );

            testSo.Legacy_Id__c = so.Id;

            update testSo;
        }

        
    
        kugo2p__paymentX__c newPayment = new kugo2p__paymentX__c();
        newPayment.kugo2p__SalesOrder__c = so.Id;
        insert newPayment;

        List<Payment__c> testPayment = [
            SELECT Id, Legacy_Id__c
            FROM Payment__c
            WHERE Legacy_Id__c = :newPayment.Id
        ];
        
        System.assertEquals(true, testPayment.size() > 0, 'Payment not created');


        newPayment.kugo2p__Memo__c = 'TEST MEMO';

        update newPayment;

        List<Payment__c> testPayment2 = [
            SELECT Id, Legacy_Id__c
            FROM Payment__c
            WHERE Legacy_Id__c = :newPayment.Id
            AND Memo__c LIKE '%TEST MEMO%'
        ];

        System.assertEquals(true, testPayment2.size() > 0, 'Payment not updated');
        
    }
}