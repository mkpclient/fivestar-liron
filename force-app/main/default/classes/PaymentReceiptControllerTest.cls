@isTest(seeAllData = true)
public class PaymentReceiptControllerTest {
      
    public static testmethod void shouldGeneratePDF(){
        
        PageReference testRef = page.paymentVF;
        test.setCurrentPage(testRef);
        
        kugo2p__SalesOrder__c salesOrder = [Select Id From kugo2p__SalesOrder__c Limit 1];
        kugo2p__PaymentX__c payment = [Select Id from kugo2p__PaymentX__c Limit 1];
            
        apexpages.currentPage().getParameters().put('orderId', salesOrder.Id);
        apexpages.currentPage().getParameters().put('paymentId', payment.Id);
        
        PaymentReceiptController controller = new PaymentReceiptController();
        
        System.assertEquals(false, controller.getSalesOrder() == null);
        System.assertEquals(1, controller.getOrderPayments().size());
        
        
    }
    
}