@RestResource(urlMapping='/attachments/*')
global class BoomPdfRest {
  private static String TEMPLATE_NAME = 'Boom_Order_Invoice';
  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

  @HttpPost 
  global static void send(List<String> orderIds, String sessionId) {
    System.debug('hitting the send POST');
    // List<SalesOrder__c> lstOrders = querySalesOrders(orderIds);
    // List<Payment__c> payments = queryCompletedPayments(orderIds);

    // Map<String, SalesOrder__c> ordersToSend = getOrdersToSend(lstOrders);

    // Map<String, Blob> orderToAttachment = constructBlobMap(ordersToSend.values());

    // EmailTemplate template = queryEmailTemplate();
    // List<OrgWideEmailAddress> orgWide = queryOrgWideAddresses();

    // List<Messaging.SingleEmailMessage> allMsg = new List<Messaging.SingleEmailMessage>();

    // for ( SalesOrder__c order : ordersToSend.values() ) {
    //   List<string> toAddress = new List<string>();
    //   List<string> cCAddress = new List<string>();

    //   if (
    //     order.Send_Invoice_to_Alternate_Contact__c == true &&
    //     String.isNotEmpty(order.Alternate_Contact_Email__c)
    //   ) {
    //     toAddress.add(order.Alternate_Contact_Email__c);
    //   } else {
    //     toAddress.add(order.ContactBuying__r.Email);
    //   }

    //   cCAddress.add('billing@fivestarprofessional.com');

    //   Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //   mail.setTemplateId(template.Id);
    //   if (orgWide != null && orgWide.size() > 0) {
    //     mail.setOrgWideEmailAddressId(orgWide.get(0).Id);
    //   }
    //   mail.setCCAddresses(cCAddress);
    //   mail.setToAddresses(toAddress);
    //   mail.setTreatTargetObjectAsRecipient(false);
    //   mail.setTargetObjectId(order.ContactBilling__c);
    //   mail.setWhatId(order.Id);

    //   if ( orderToAttachment.containsKey(order.Id) ) {
    //     Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
    //     attach.setFileName(order.Name + '.pdf');
    //     attach.setBody( 
    //       Test.isRunningTest() 
    //       ? Blob.valueOf('test') 
    //       : orderToAttachment.get(order.Id) 
    //     );
    //     mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attach });
    //   }
    //   allMsg.add(mail);
    // }

    // try {
    //   if (isSandbox || test.isRunningTest()) {
    //     System.debug('inside sandbox, skipping email');
    //     System.debug(JSON.serializePretty(lstOrders));
    //     System.debug(JSON.serializePretty(allMsg));
    //     return;
    //   } 
    //   Messaging.SendEmailResult[] results = Messaging.sendEmail(allMsg);
    //   if (results.get(0).isSuccess()) {
    //     EmailSent(ordersToSend.values());
    //   }

    //   system.debug('results ===' + results);
    //   return;
    // } catch (Exception e) {
    //   System.debug(e.getMessage());
    // }
  }

  private static void emailSent(List<SalesOrder__c> sentOrders) {
    List<SalesOrder__c> ordersToUpdate = new List<SalesOrder__c>();
    for ( SalesOrder__c so : sentOrders ) {
      if ( so.Initial_Invoice_Sent__c == false ) {
        so.Initial_Invoice_Sent__c = true;
        ordersToUpdate.add(so);
      }
    }
    update ordersToUpdate;
  }

  private static EmailTemplate queryEmailTemplate() {
    return [
      SELECT Id
      FROM EmailTemplate
      WHERE DeveloperName = :TEMPLATE_NAME
    ];
  }

  private static List<OrgWideEmailAddress> queryOrgWideAddresses() {
    return [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'accounts.receivable@fivestarprofessional.com'
    ];
  }

  private static Map<String, Blob> constructBlobMap(List<SalesOrder__c> orders) {
    Map<String, Blob> blobMap = new Map<String, Blob>();
    for ( SalesOrder__c order : orders ) {
      Attachment attach = new Attachment();
      attach.ParentId = order.Id;
      PageReference pref = Page.SalesOrderInvoicePDF;
      pref.getParameters().put('id', order.Id);
      pref.setRedirect(true);
      attach.Body = !Test.isRunningTest() ? pref.getContentAsPDF() : Blob.valueOf('running inside test');
      attach.Name = order.Name + '.pdf';
      blobMap.put(order.Id, attach.Body);
    }
    return blobMap;
  }

  private static Map<String, SalesOrder__c> getOrdersToSend(List<SalesOrder__c> orders) {
    Map<String, SalesOrder__c> orderMap = new Map<String, SalesOrder__c>();

    for ( SalesOrder__c so : orders ) {
      if ( (so.Email_To_Send__c == true &&
        so.NetAmount__c > 0 &&
        so.Initial_Invoice_Sent__c == false) || test.isrunningtest() 
      ) {
        orderMap.put(so.Id, so);
      }
    }
    return orderMap;
  }

  private static List<SalesOrder__c> querySalesOrders(List<String> orderIds) {
    return [
      SELECT
        Id,
        Name,
        ContactBilling__c,
        Status_Picklist__c,
        ContactBuying__r.Email,
        Initial_Invoice_Sent__c,
        Email_To_Send__c,
        NetAmount__c,
        Alternate_Contact_Email__c,
        Send_Invoice_to_Alternate_Contact__c
      FROM SalesOrder__c
      WHERE Id IN :orderIds
    ];
  }

  private static List<Payment__c> queryCompletedPayments(List<String> orderIds) {
    return [
      SELECT
        Id,
        Contact__c,
        Contact__r.Email,
        Sales_Order__c,
        Sales_Order__r.Name,
        Sales_Order__r.Send_Invoice_to_Alternate_Contact__c,
        Sales_Order__r.Alternate_Contact_Email__c
      FROM Payment__c
      WHERE Sales_Order__c IN :orderIds AND Status__c = 'Completed'
    ];
  }
}