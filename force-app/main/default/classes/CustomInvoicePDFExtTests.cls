@isTest
private class CustomInvoicePDFExtTests {

  @IsTest
  static void CustomInvoicePDFExt(){
    Test.startTest();
      CustomInvoicePDFExt ext = new CustomInvoicePDFExt();
      Id invoiceIdValue = ext.invoiceIdValue;
      kugo2p__KugamonInvoice__c Invoice = ext.Invoice;
      kugo2p__KugamonSetting__c settings = ext.settings;
      list<kugo2p.InvoicePDFExt.PDFInvoiceLine> InvoiceLines = ext.InvoiceLines;
      try {
        list<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> ACCLines = ext.ACCLines;
      } catch ( Exception e){

      }
      try {
        String downloadPDFURL = ext.downloadPDFURL;
      } catch ( Exception e){

      }
      try {
        String getPaymentURL = ext.getPaymentURL();
      } catch ( Exception e){

      }
      try {
        String getAcceptAndPayOnline = ext.getAcceptAndPayOnline();
      } catch ( Exception e){

      }
      String orderName = ext.orderName;
      try {
        list<LineRecipient__c> LineRecipients = ext.LineRecipients;
      } catch ( Exception e){

      }
    Test.stopTest();    
  }


}