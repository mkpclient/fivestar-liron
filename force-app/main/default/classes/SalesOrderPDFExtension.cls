global without sharing class SalesOrderPDFExtension {
  global Id orderId { get; set; }
  global String encodedSignature { get; set; }
  global Boolean acceptTerms { get; set; }
  global String acceptedBy { get; set; }
  global SalesOrder__c salesOrder { get; set; }
  global Boolean showTermsErrorBlock { get; set; }

  global Boolean allowEssentialEmails {
    get {
      return FivestarSetting__mdt.getInstance('Universal') != null &&
      FivestarSetting__mdt.getInstance('Universal').Allow_Essential_Engine_Emails__c;
    } private set;
  }
  global SalesOrderPDFExtension() {
    system.debug('Default Constructor');
    if (
      orderId == null &&
      ApexPages.currentPage().getParameters().containsKey('id')
    ) {
      orderId = ApexPages.currentPage().getParameters().get('id');

      salesOrder = querySalesOrder(orderId);
      showTermsErrorBlock = true;
      acceptTerms = false;
    }
  }

  global SalesOrderPDFExtension(ApexPages.StandardController stdController) {
    system.debug('StandardController Constructor');
    System.debug(UserInfo.getUserName());
    if (orderId == null) {
      orderId = stdController.getId();
      salesOrder = querySalesOrder(orderId);
      showTermsErrorBlock = true;
      acceptTerms = false;
    }
  }

  global void captureAcceptedByInput() {
    acceptedBy = ApexPages.currentPage().getParameters().get('acceptedByName');
  }

  global void toggleAcceptTerms() {
    acceptTerms = !acceptTerms;
    showTermsErrorBlock = !showTermsErrorBlock;
  }

  // global Boolean showTermsErrorBlock {
  //   get {
  //     if(acceptTerms != null) {
  //       showTermsErrorBlock = !acceptTerms;
  //       return showTermsErrorBlock;
  //     }
  //     return true;
  //   } private set;
  // }

  global Boolean showAcceptedByNameErrorBlock {
    get {
      showAcceptedByNameErrorBlock = String.isEmpty(this.acceptedBy);
      return showAcceptedByNameErrorBlock;
    }
    private set;
  }

  global PageReference attachPDF() {
    

    SalesOrder__c salesOrder = querySalesOrder(orderId);
    String vfPageName = 'salesorderpdfvf';

    if(salesOrder.Price_Book__r.Business_Unit__c == 'Essential Engine' && allowEssentialEmails) {
      vfPageName = 'EssentialEngineOrderPdfVf';
    }
    String url = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/' + vfPageName + '?id=' + orderId;

    PageReference p = new PageReference(url);

    Blob body;

    if (Test.isRunningTest()) {
      body = Blob.valueOf('teststring');
    } else {
      body = p.getContent();
    }

    Attachment a = new Attachment();
    a.ParentId = orderId;
    a.Body = body;
    a.Name = salesOrder.Name + '.pdf';
    insert a;

    if (Test.isRunningTest()) {
      return p;
    }
    return new ApexPages.standardController(new SalesOrder__c(Id = orderId))
      .view();
  }

  global static SalesOrder__c querySalesOrder(Id recordId) {
    DescribeSObjectResult describeResult = recordId.getSObjectType()
      .getDescribe();
    List<String> fieldNames = new List<String>(
      describeResult.fields.getMap().keySet()
    );
    fieldNames.add('Owner.Name');
    fieldNames.add('ContactBilling__r.Name');
    fieldNames.add('ContactBilling__r.Email');
    fieldNames.add('ContactBilling__r.Phone');
    fieldNames.add('ContactBilling__r.Fax');
    fieldNames.add('Account__r.Name');
    fieldNames.add('Price_Book__r.Business_Unit__c');

    String queryString =
      ' SELECT ' +
      String.join(fieldNames, ',') +
      ' FROM ' +
      describeResult.getName() +
      ' WHERE ' +
      ' id = :recordId ' +
      ' LIMIT 1 ';
    return database.query(queryString);
  }

  global List<Product2> getProducts() {
    return null;
  }

  global Boolean gethasProductTextandTerms() {
    return false;
  }

  global String getTermsAcceptedBy() {
    return acceptedBy != null
      ? acceptedBy
      : orderId != null && Order != new SalesOrder__c() ? Order.ContactBilling__r.Name : '';
  }

  global String getTermsAcceptedDate() {
    TimeZone tz = UserInfo.getTimeZone();
    DateTime dt = Datetime.now();
    return dt.format();
  }

  global String getTermsAcceptedFromIPAddress() {
    // Map<String, String> session = Auth.SessionManagement.getCurrentSession();
    String retString = '';

    if (Test.isRunningTest()) {
      retString = 'test string';
    } else {
      retString = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
    }
    return retString;
  }

  global String getISOCurrencyCode() {
    return 'USD';
  }

  global Boolean getIsMultiCurrencyEnabled() {
    return false;
  }

  global string InitialedBy {
    get {
      if (String.isEmpty(InitialedBy) && orderId != null && Order != null && Order != new SalesOrder__c()) {
        InitialedBy = Order.ContactBilling__r.Name;
      }
      return InitialedBy;
    }
    set;
  }

  global Boolean showInitialByErrorBlock {
    get {
      showInitialByErrorBlock = String.isEmpty(InitialedBy);
      if (Test.isRunningTest()) {
        showInitialByErrorBlock = false;
      }
      return showInitialByErrorBlock;
    }
    set;
  }

  global Boolean getDisplayShipToInfo() {
    return true;
  }

  global Boolean getRenderPaymentButton() {
    return true;
  }

  global Integer getProductLineCount() {
    return ProductLines != null && ProductLines.size() > 0 ? ProductLines.size() : 0;
  }

  global String getLogoUrl() {
    String retUrl = 'https://fivestarprofessional--c.na169.content.force.com/servlet/servlet.ImageServer?id=015d00000060AVl&oid=00Dd0000000gsfl';

    if (Test.isRunningTest()) {
      retUrl = 'test.com';
    }
    return retUrl;
  }

  global Boolean getProductsHaveDescriptions() {
    return true;
  }
  global Boolean getAccsHaveDescriptions() {
    return true;
  }
  global Integer getChargeCreditLineCount() {
    return ACCLines != null ? ACCLines.size() : 0;
  }

  global SalesOrder__c Order {
    get {
      if (orderId != null) {
        Order = querySalesOrder(orderId);
      } else {
        Order = new SalesOrder__c();
      }
      return Order;
    }
    private set;
  }

  global SettingResource settings {
    get {
      if (settings == null) {
        settings = new SettingResource();
      }
      return settings;
    }
    private set;
  }

  global List<Payment__c> Payments {
    get {
      if (orderId != null && (Payments == null || Payments.size() == 0)) {
        Payments = [
          SELECT
            Id,
            Date__c,
            Payment_Type__c,
            Memo__c,
            Amount__c,
            Contact__r.Name,
            CardType__c,
            Last_Four_Digits__c,
            Status__c,
            Billing_Name__c
          FROM Payment__c
          WHERE Sales_Order__c = :orderId AND Status__c = 'Completed'
          ORDER BY Date__c
        ];
      } else {
        Payments = new List<Payment__c>();
      }

      return Payments;
    }
    private set;
  }

  global list<SalesOrderProductLine__c> ProductLines {
    get {
      if (orderId != null) {
        ProductLines = [
          SELECT
            Id,
            Display_Name_for_Invoice__c,
            Product__r.Name,
            Product__r.Product_Display_Name__c,
            ListPrice__c,
            Name,
            LineDescription__c,
            Quantity__c,
            Actual_Price__c,
            TotalAmount__c,
            DateAvailableToPromise__c,
            DiscountSalesPrice__c
          FROM SalesOrderProductLine__c
          WHERE SalesOrder__c = :orderId
        ];
      } else {
        ProductLines = new List<SalesOrderProductLine__c>();
      }
      return ProductLines;
    }
    private set;
  }

  // global list<SalesOrderProductLine__c> ServiceLines {
  //   get {
  //     if (ServiceLines == null) {
  //       // ServiceLines = orderPDFExt.ServiceLines;
  //     }
  //     return ServiceLines;
  //   }
  //   private set;
  // }

  global list<SalesOrderAdditionalChargeCredit__c> ACCLines {
    get {
      if (orderId != null) {
        ACCLines = [
          SELECT
            LineDescription__c,
            Date__c,
            Quantity__c,
            SalesPrice__c,
            AdditionalChargeCreditAmount__c,
            Additional_Charge_Credit__r.Name
          FROM SalesOrderAdditionalChargeCredit__c
          WHERE SalesOrder__c = :orderId
        ];
      } else {
        ACCLines = new List<SalesOrderAdditionalChargeCredit__c>();
      }

      return ACCLines;
    }
    private set;
  }

  global String downloadPDFURL {
    get {
      system.debug(
        '\n ### toExternalForm ' + URL.getSalesforceBaseUrl().toExternalForm()
      );
      system.debug('\n ### getHost ' + URL.getSalesforceBaseUrl().getHost());
      String pageName = 'SalesOrderPDF';
      if(Order.Price_Book__r.Business_Unit__c == 'Essential Engine' && allowEssentialEmails) {
        pageName = 'EssentialEngineOrderPdfVf';
      }
      String url =
        URL.getSalesforceBaseUrl().toExternalForm() +
        '/apex/' + pageName + '?id=' +
        Order.Id +
        '&p=1';

      if (Test.isRunningTest()) {
        url = 'test.pdf.url.com';
      }
      return url;
    }
  }

  global String getPaymentURL() {
    // return orderPDFExt.PaymentURL + '&retURL=' + downloadPDFURL;
    return null;
  }

  global PageReference acceptAndPayOnline() {
    String orderRecordStatus = this.Order.Status_Picklist__c;
    // this will be the page reference to the payment screen
    Boolean isEssential = allowEssentialEmails && Order.Price_Book__r.Business_Unit__c == 'Essential Engine';
    PageReference pr = new PageReference(
      '/apex/publicPaymentVfPage?id=' + orderId + '&isEssential=' + isEssential
    );

    if (attachmentId == null) {
      encodedSignature = ApexPages.currentPage()
        .getParameters()
        .get('signature');

      if (!Test.isRunningTest()) {
        saveSignature();
      }
    }

    // un-comment the following section if the customer needs customization to online payment page.
    /*if (pr != null) {
          pr = Page.CustomOnlinePayment;
          if(this.Order.BalanceDueAmount__c == 0 || orderPDFExt.settings.OnlinePaymentButton__c.equalsIgnoreCase('Accept & Approve') || this.Order.PaymentMethod__c=='Invoice') {
              pr = Page.CustomOnlineConfirmation;
          }
          pr.getParameters().put('soId', Order.Id);
          if (ApexPages.currentPage().getParameters().containsKey('retURL')) pr.getParameters().put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
          pr.setRedirect(true);
      }*/

    return pr;
  }

  global PageReference checkout() {
    String orderRecordStatus = this.Order.RecordStatus__c;
    // PageReference pr = orderPDFExt.checkout();

    // if (pr != null && (orderRecordStatus == 'Draft' || orderRecordStatus == 'Sent')) {
    //     saveSignature();
    // }

    // return pr;
    return null;
  }

  private String signatureName {
    get {
      return this.Order.Name + ' - Accepted Signature.png';
    }
  }

  private void saveSignature() {
    if (String.isNotBlank(encodedSignature)) {
      Attachment attach = new Attachment(
        Name = signatureName,
        Description = 'Accepted by ' +
          '' +
          // orderPDFExt.acceptedBy
          ' from IP Address: ' +
          getIPAddress(),
        Body = encodingUtil.base64Decode(encodedSignature),
        parentId = this.Order.Id,
        isPrivate = false
      );
      insert attach;
    }
  }

  global Id attachmentId {
    get {
      if (attachmentId == null && signatureName != null) {
        for (Attachment attach : [
          SELECT Id
          FROM Attachment
          WHERE ParentId = :Order.Id AND Name = :signatureName
          ORDER BY createdDate DESC
          LIMIT 1
        ]) {
          attachmentId = attach.Id;
        }
      }
      return attachmentId;
    }
    private set;
  }

  // global String SignatureUrl {
  //   get {
  //     if (SignatureUrl == null && order.ShipToStreetLong__c != null) {
  //       Id attachmentId;
  //       for (Attachment attach : [
  //         SELECT Id
  //         FROM Attachment
  //         WHERE ParentId = :Order.Id AND Name = :signatureName
  //         ORDER BY createdDate DESC
  //         LIMIT 1
  //       ]) {
  //         attachmentId = attach.Id;
  //       }
  //       SignatureUrl = attachmentId != null
  //         ? ('/servlet/servlet.FileDownload?file=' +
  //           attachmentId +
  //           '&oid=' +
  //           UserInfo.getOrganizationId())
  //         : '';
  //     }
  //     return SignatureUrl;
  //   }
  //   private set;
  // }

  // Returns IP address of current user.
  @TestVisible
  private String getIPAddress() {
    String ipAddress = '';
    if (Test.isRunningTest()) {
      ipAddress = 'test string';
    } else {
      ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
    }
    return ipAddress;
  }

  global static list<Order_Line_Recipient__c> queryLineRecipients(Id orderId) {
    return orderId == null
      ? new List<Order_Line_Recipient__c>()
      : [
          SELECT
            Id,
            OrderLine__c,
            OrderProductLine__r.Product__r.Name,
            OrderProductLine__r.Product__r.Product_Display_Name__c,
            OrderProductLine__r.Display_Name_for_Invoice__c,
            Recipient__r.Name,
            Primary__c
          FROM Order_Line_Recipient__c
          WHERE Order__c = :orderId
          ORDER BY
            OrderProductLine__r.SortOrder__c NULLS LAST,
            Recipient__r.Name
        ];
  }

  global list<Order_Line_Recipient__c> LineRecipients {
    get {
      if (orderId != null) {
        LineRecipients = queryLineRecipients(orderId);
      } else {
        LineRecipients = new List<Order_Line_Recipient__c>();
      }
      return LineRecipients;
    }
    private set;
  }

  global Integer UniqueLineRecipientsCount {
    get {
      UniqueLineRecipientsCount = UniqueLineRecipients.size();
      return UniqueLineRecipientsCount;
    } set;
  }

  global Set<String> UniqueLineRecipients {
    get {
      if (orderId != null) {
        Set<String> localUniqueLrs = new Set<String>();
        for (Order_Line_Recipient__c lr : queryLineRecipients(orderId)) {
          localUniqueLrs.add(lr.Recipient__r.Name);
        }
        UniqueLineRecipients = localUniqueLrs;
      } else {
        UniqueLineRecipients = new Set<String>();
      }
      return UniqueLineRecipients;
    }
    private set;
  }

  global list<Payment__c> PaymentSchedules {
    get {
      if (
        orderId != null ) {
        PaymentSchedules = [
          SELECT
            Scheduled_Payment_Date__c,
            Id,
            Date__c,
            Payment_Type__c,
            Memo__c,
            Amount__c,
            Contact__r.Name,
            CardType__c,
            Last_Four_Digits__c,
            Status__c,
            Billing_Name__c
          FROM Payment__c
          WHERE Sales_Order__c = :orderId AND Status__c = 'Scheduled'
          ORDER BY Date__c
        ];
      } else {
        PaymentSchedules = new List<Payment__c>();
      }
      return PaymentSchedules;
    }
    private set;
  }

  global class SettingResource {
    global String RemitToName { get; set; }
    global String RemitToStreet { get; set; }
    global String RemitToCity { get; set; }
    global String RemitToStateProvince { get; set; }
    global String RemitToZipPostalCode { get; set; }
    global String RemitToCountry { get; set; }
    global String OnlinePaymentLogoinPDFSourceURL { get; set; }
    global String BankName { get; set; }
    global String ACName { get; set; }
    global String ACNumber { get; set; }
    global String ABANumber { get; set; }
    global String SWIFT_Code { get; set; }
    global Boolean ListPriceColumnonPDF { get; set; }
    global Boolean PrintCompanyTextandTerms { get; set; }
    global String CompanyTextandTerms { get; set; }
    global Boolean SignatureLinestoPDF { get; set; }
    global String OnlinePaymentButton { get; set; }

    global SettingResource() {
      SignatureLinestoPDF = true;
      PrintCompanyTextandTerms = true;
      CompanyTextandTerms = 'For questions about:<br/>';
      CompanyTextandTerms += '<ul>';
      CompanyTextandTerms += '<li>Invoice, payments and payment plans, contact billing@fivestarprofessional.com</li>';
      CompanyTextandTerms += '<li>Your order, or to order more tools, contact your Account Manager';
      CompanyTextandTerms += '<li>All marketing product service questions, contact customerservice@fivestarprofessional.com';
      CompanyTextandTerms += '</ul>';
      CompanyTextandTerms += '100% “No Risk” Satisfaction Guarantee<br/>';
      CompanyTextandTerms += '<br/>';
      CompanyTextandTerms += 'If your expectations for any product or program are not fully met, as summarized on your invoice, give us one opportunity to make things right.';
      CompanyTextandTerms += 'If we don’t make things right, we provide you a complete refund.';
      OnlinePaymentButton = 'Accept & Pay';
    }
  }
}