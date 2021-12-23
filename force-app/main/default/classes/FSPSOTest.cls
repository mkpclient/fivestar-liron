@istest(seealldata=true)
public class FSPSOTest {
  @istest
  public static void testOrder() {
    kugo2p__SalesOrder__c so = [SELECT id FROM kugo2p__SalesOrder__c LIMIT 1];

    PageReference pageRef = Page.New_FSP_Non_WM_Invoice;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('id', so.id);
    FSPSO controller = new FSPSO();

    controller.Order = controller.getSalesOrder();
    system.assertNotEquals(null, controller.Order);

    controller.getOrderPayments();
    controller.OrderedProducts = controller.getOrderProducts();

    controller.AdditionalChargeCredited = controller.getAdditionalCharges();
    decimal total = controller.getTotalProducts();
  }
}