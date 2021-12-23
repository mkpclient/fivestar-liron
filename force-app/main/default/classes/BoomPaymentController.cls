global class BoomPaymentController {
  global String PagePDFContent { get; set; }
  global String paymentId {
    get;
    set {
      UpdatePDFContent(value);
    }
  }

  public void UpdatePDFContent(String pmtId) {
    try {
      Payment__c pmt = [
        SELECT Id, Sales_Order__c
        FROM Payment__c
        WHERE Id = :pmtId
        LIMIT 1
      ];
      PageReference pageRef = Page.Payment2VF;
      pageRef.getParameters().put('orderId', (String) pmt.Sales_Order__c);
      pageRef.getParameters().put('paymentId', (String) pmt.Id);
      PagePDFContent = pageRef.getContent()
        .toString()
        .replace('<html style="display:none !important;">', '<html>');
    } catch (System.Exception ex) {
    }
  }
}