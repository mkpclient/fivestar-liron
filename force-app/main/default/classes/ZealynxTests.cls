@isTest
public class ZealynxTests {

  @isTest
  public static void testCustomerMethods(){
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
    Zealynx.CustomerResource cr = new Zealynx.CustomerResource().mock();
    Map<String,Object> customerResult = Zealynx.saveCustomer(cr);
    String customerJson = (String)JSON.serialize(customerResult.get('customer'));
    System.assertEquals(true, customerJson.contains('1234'), 'Customer ID should be 1234');
  }

  @isTest
  public static void testCreditCardMethods() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
    Zealynx.CreditCardResource ccr = new Zealynx.CreditCardResource();
    Map<String,Object> ccResult = Zealynx.savePaymentMethod(ccr);
    String ccJson = (String)JSON.serialize(ccResult.get('creditCard'));
    System.assertEquals(true, ccJson.contains('1234'), 'Credit Card ID should be 1234');

    Map<String,Object> deletedCcResult = Zealynx.deletePaymentMethod(ccr);
    String deletedCcJson = (String)JSON.serialize(deletedCcResult.get('isSuccess'));
    System.assertEquals(true, deletedCcJson.contains('true'), 'Credit Card should be deleted');
  }

  @isTest
  public static void testPaymentMethods() {
    Test.setMock(HttpCalloutMock.class, new ZealynxHttpMockGenerator());
    Zealynx.PaymentResource pmt = new Zealynx.PaymentResource();
    Map<String,Object> pmResult = Zealynx.makePayment(pmt);
    System.debug(pmResult);
    String pmJson = (String)JSON.serialize(pmResult.get('payment'));
    System.assertEquals(true, pmJson.contains('1234'), 'Payment ID should be 1234');
    System.assertEquals(true, pmJson.contains('ABCD'), 'Payment token should be 5678');

    Zealynx.PaymentResource pmt2 = new Zealynx.PaymentResource();
    Map<String,Object> refundPmtResult = Zealynx.refundPayment(pmt2);
    String refundPmtJson = (String)JSON.serialize(refundPmtResult.get('payment'));
    System.assertEquals(true, refundPmtJson.contains('1234'), 'Payment ID should be 1234');
    System.assertEquals(true, refundPmtJson.contains('ABCD'), 'Payment token should be 5678');

    Zealynx.PaymentResource pmt3 = new Zealynx.PaymentResource();
    Map<String,Object> voidPmtResult = Zealynx.voidPayment(pmt3);
    System.assertEquals(true, (Boolean) voidPmtResult.get('isSuccess'), 'Payment should be voided');
  }

}