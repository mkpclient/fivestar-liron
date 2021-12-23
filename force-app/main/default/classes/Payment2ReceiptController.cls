public class Payment2ReceiptController {
  public SalesOrder__c SalesOrder {
    get {
      List<SalesOrder__c> resultsList = [
        SELECT
          Id,
          Name,
          Opportunity__r.Account_Manager_Name__c,
          ContactBilling__r.Name,
          BillToStreetLong__c,
          BillToCity__c,
          BillToStateProvince__c,
          BillToZipPostalCode__c,
          ContactBuying__r.ACDF_Branch_Office__c
        FROM SalesOrder__c
        WHERE id = :ApexPages.currentPage().getParameters().get('orderId')
      ];

      SalesOrder = resultsList.isEmpty() == false
        ? resultsList.get(0)
        : new SalesOrder__c();

      return SalesOrder;
    }
    private set;
  }

  public list<Payment__c> OrderPayments {
    get {
      String paymentId = ApexPages.currentPage()
        .getParameters()
        .get('paymentId');

      OrderPayments = [
        SELECT
          Id,
          Name,
          Date__c,
          Transaction_Type__c,
          CardType__c,
          Last_Four_Digits__c,
          Amount__c,
          Transaction_Id__c,
          Billing_Name__c,
          Status__c,
          Authorization_Id__c,
          Payment_Method__c
        FROM Payment__c
        WHERE Id = :paymentId
      ];
      OrderPayments.sort();
      return OrderPayments;
    }
    private set;
  }

  public Payment_Method__c paymentMethod {
    get {
      if (
        OrderPayments.size() > 0 &&
        OrderPayments[0].Payment_Method__c != null
      ) {
        paymentMethod = [
          SELECT
            Id,
            Billing_First_Name__c,
            Billing_Last_Name__c,
            Billing_Street__c,
            Billing_City__c,
            Billing_State__c,
            Billing_Postal_Code__c,
            Billing_Country__c
          FROM Payment_Method__c
          WHERE Id = :OrderPayments[0].Payment_Method__c
          LIMIT 1
        ];
      } else {
        paymentMethod = new Payment_Method__c();
      }
      return paymentMethod;
    }
    set;
  }

  public PageReference attachPDF() {
    PageReference p = Page.Payment2VF;
    p.getParameters()
      .put('orderId', ApexPages.currentPage().getParameters().get('orderId'));
    p.getParameters()
      .put(
        'paymentId',
        ApexPages.currentPage().getParameters().get('paymentId')
      );

    Blob body;

    if (Test.isRunningTest()) {
      body = Blob.valueOf('teststring');
    } else {
      body = p.getContent();
    }

    List<Payment__c> currPayments = OrderPayments;

    Attachment a = new Attachment();
    a.ParentId = ApexPages.currentPage().getParameters().get('paymentId');
    a.Body = body;
    a.Name = currPayments[0].Name + '.pdf';
    insert a;

    if (!Test.isRunningTest()) {
      p.setRedirect(true);
    }
    return p;
  }
}