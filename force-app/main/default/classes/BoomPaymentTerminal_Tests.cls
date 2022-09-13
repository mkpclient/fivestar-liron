@isTest
public with sharing class BoomPaymentTerminal_Tests {
    @TestSetup
    static void makeData(){
        Product2 testProd = BoomTestHelpers.generateProduct();
        PricebookEntry pbE1 = BoomTestHelpers.generatePriceBookEntry(testProd.Id);
        Market__c mkt = BoomTestHelpers.generateMarket(pbe1.Pricebook2Id, true);
        Account a = BoomTestHelpers.generateAccount();
        Contact c = BoomTestHelpers.generateContact(a.Id);
        Opportunity o = BoomTestHelpers.generateOpportunity(a.Id, mkt.Id, c.Id);
        SalesOrder__c so = BoomTestHelpers.generateTestBoomOrder(o.Id);
        SalesOrderProductLine__c sopl = BoomTestHelpers.generateBoomProductLine(so.Id, pbe1);

        so.Status_Picklist__c = 'Approved';

        update so;

        Payment_Method__c pm = BoomTestHelpers.generateTestPmtMethod(c.Id, true);

    }
    @isTest
    public static void testSaveCustomer() {
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        BoomPaymentTerminal_LightningController.TerminalWrapper tw = BoomPaymentTerminal_LightningController.getRecordData(so.Id);
        Map<Id, Payment_Method__c> pmMap = BoomPaymentTerminal_LightningController.returnPaymentMethods(c.Id);
        Contact ctc = BoomPaymentTerminal_LightningController.returnRelatedContact(c.Id);
        Contact updatedCtc = BoomPaymentTerminal_LightningController.saveCustomer(ctc);
        Test.stopTest();

    }
    
    @isTest
    public static void testSavePaymentMethod() { 
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Map<Id, Payment_Method__c> pmMap = BoomPaymentTerminal_LightningController.returnPaymentMethods(c.Id);

        Test.startTest();
        BoomPaymentTerminal_LightningController.CustomPaymentMethod cpm = new BoomPaymentTerminal_LightningController.CustomPaymentMethod();
        cpm.cardNumber = '4242424242424242';
        cpm.expirationMonth = '12';
        cpm.expirationYear = '2029';
        cpm.customerMerchantId = '1234';
        BoomPaymentTerminal_LightningController.savePaymentMethod(pmMap.values()[0], cpm);
        Test.stopTest();

    }

    @isTest
    public static void testPayment(){
        Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());

        Contact ctc = [SELECT Id FROM Contact LIMIT 1];
        Map<Id, Payment_Method__c> pmMap = BoomPaymentTerminal_LightningController.returnPaymentMethods(ctc.Id);
        SalesOrder__c so = [SELECT Id FROM SalesOrder__c LIMIT 1];

        Test.startTest();
        BoomPaymentTerminal_LightningController.MultiplePayment mp = new BoomPaymentTerminal_LightningController.MultiplePayment();
        mp.waveFinanceFee = false;
        mp.contactId = ctc.Id;
        mp.financeFee = 10;
        mp.paymentAmount = 10;
        mp.firstPayment = 10;
        mp.paymentMethodId = pmMap.values()[0].Id;
        mp.salesOrderId = so.Id;
        mp.newFirstPaymentDate = System.today().addMonths(1);
        mp.numberOfPayments = 2;
        BoomPaymentTerminal_LightningController.handleMultiplePayments(mp);
        Test.stopTest();

    }
}