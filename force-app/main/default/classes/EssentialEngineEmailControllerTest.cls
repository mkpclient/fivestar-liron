@isTest
public with sharing class EssentialEngineEmailControllerTest {
    @isTest
    public static void testEssEngController() {
        Account a = BoomTestHelpers.generateAccount();
        Contact c = BoomTestHelpers.generateContact(a.Id);
        Product2 p2 = BoomTestHelpers.generateProduct();
        PricebookEntry pbe = BoomTestHelpers.generatePriceBookEntry(p2.Id);
        Market__c m = BoomTestHelpers.generateMarket(pbe.Pricebook2Id, false);
        Opportunity o = BoomTestHelpers.generateOpportunity(a.Id, m.Id, c.Id);
        SalesOrder__c so = BoomTestHelpers.generateTestBoomOrder(o.Id);
        SalesOrderProductLine__c sopl = BoomTestHelpers.generateBoomProductLine(so.Id, pbe);
        Order_Line_Recipient__c olr = BoomTestHelpers.generateTestLineRecipient(so.Id, sopl.Id, c.Id, true);

        so.Status_Picklist__c = 'Approved';

        update so;

        Payment_Method__c pm = BoomTestHelpers.generateTestPmtMethod(c.Id, true);
        Payment__c p = BoomTestHelpers.generateTestPayment(so.Id, a.Id, c.Id, pm.Id, 25, 'Scheduled');
        Payment__c pc = BoomTestHelpers.generateTestPayment(so.Id, a.Id, c.Id, pm.Id, 25, 'Completed');


        EssentialEngineEmailController controller = new EssentialEngineEmailController();
        controller.orderId = so.Id;
        SalesOrderPDFExtension.SettingResource settings = controller.settings;
        
        System.assertEquals(so.Id, controller.Order.Id, 'Order from controller should have a value.');
        System.assertEquals(true, controller.allPayments.size() > 0, 'There should be at least one payment.');
        System.assertEquals(true, String.isNotEmpty(controller.logoUrl), 'LogoUrl should not be empty');
        System.assertEquals(sopl.Id, controller.ProductLines[0].Id, 'ProductLines[0].Id should be equal to sopl.Id');
        System.assertEquals(new List<SalesOrderAdditionalChargeCredit__c>(), controller.ACCLines, 'ACCLines should be empty');
        System.assertEquals(0, controller.ChargeCreditLineCount, 'ChargeCreditLineCount should be 0');
        System.assertEquals(p.Id, controller.PaymentSchedules[0].Id, 'PaymentSchedules[0].Id should be equal to p.Id');
        System.assertEquals(olr.Id, controller.LineRecipients[0].Id, 'LineRecipients[0].Id should be equal to olr.Id');
        System.assertEquals(pc.Id, controller.Payments[0].Id, 'Payments[0].Id should be equal to p.Id');
    }
}