global class BoomPDFOneHourBatch implements Database.Batchable<sObject>, Database.allowsCallouts, Database.Stateful {
  private static String INVOICE_TEMPLATE = 'Boom_Order_Invoice';
  private static String PAYMENT_TEMPLATE = 'Boom_Payment_VF_Template';
  private static String CC_EMAIL = 'billing@fivestarprofessional.com';
  public List<String> orderIds;
  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
  .IsSandbox;

  public BoomPDFOneHourBatch(List<String> ids) {
    orderIds = ids;
  }

  global Database.QueryLocator start(Database.BatchableContext bc) {
    String query = 'SELECT Id, Name, ContactBilling__c, Status_Picklist__c, ContactBuying__r.Email, Initial_Invoice_Sent__c, Email_To_Send__c, NetAmount__c, Alternate_Contact_Email__c, Send_Invoice_to_Alternate_Contact__c FROM SalesOrder__c WHERE Id IN :orderIds';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext bc, List<sObject> scope) {
    sendEmail((List<SalesOrder__c>)scope, orderIds);
  }

  global void finish(Database.BatchableContext bc) {

  }

  private static void sendEmail(List<SalesOrder__c> lstOrders, List<String> orderIds) {
    
    List<Payment__c> payments = queryPayments(orderIds);

    List<SalesOrder__c> ordersToSend = filterOrdersToSend(lstOrders);

    sendPaymentEmails(payments);

    Map<String, Attachment> mapOrderIdToAttachment = constructAttachmentMap(ordersToSend);

    // insert the attachments 
    insert mapOrderIdToAttachment.values();

    Id templateId = queryTemplate(INVOICE_TEMPLATE);

    Id orgWideId = queryOrgWideAddress();

    List<Messaging.SingleEmailMessage> allMsg = new List<Messaging.SingleEmailMessage>();

    System.debug('ORDERS TO SEND??? ' + ordersToSend.size());
    if ( ordersToSend.size() > 0 ) {
      for ( SalesOrder__c order : ordersToSend ) {
        List<string> toAddress = new List<string>();
        List<string> cCAddress = new List<string>();
        
        if (
          order.Send_Invoice_to_Alternate_Contact__c == true &&
          String.isNotEmpty(order.Alternate_Contact_Email__c)
        ) {
          toAddress.add(order.Alternate_Contact_Email__c);
        } else {
          toAddress.add(order.ContactBuying__r.Email);
        }
  
        cCAddress.add(CC_EMAIL);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        if ( orgWideId != null ) {
          mail.setOrgWideEmailAddressId(orgWideId);
        }
        // mail.setCCAddresses(cCAddress);
        // mail.setToAddresses(toAddress);
        mail.toAddresses = new List<String>{ 'angelochagoy@gmail.com' };
        mail.setCCAddresses(new List<String>{ 'angelochagoy@live.com',  'gregory.thatcher@gmail.com', 'shelly.martin@fivestarprofessional.com'});
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setTargetObjectId(order.ContactBilling__c);
        mail.setWhatId(order.Id);
  
        // attachment stuff
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        Attachment att = mapOrderIdToAttachment.get(order.Id);
        attach.setFileName(order.Name + '.pdf');
        attach.setBody( Test.isRunningTest() ? Blob.valueOf('test') : att.Body );
        mail.setFileAttachments(
          new List<Messaging.EmailFileAttachment>{ attach }
        );
  
        allMsg.add(mail);
      }
  
      // send emails 
      try {
        system.debug('Emails to send ===' + allmsg.size());
        if (isSandbox || test.isRunningTest()) {
          System.debug('inside sandbox, skipping email');
          System.debug(JSON.serializePretty(allmsg));
          return;
        }
        System.debug('sending emails!');
        Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg);
        if (results.get(0).isSuccess()) {
          EmailSent(lstOrders);
        }
        system.debug(results);
        return;
      } catch (Exception e) {
        System.debug(e.getMessage());
      }
    }

  }

  private static void emailSent(List<SalesOrder__c> lstOrders) {
    List<SalesOrder__c> lstOrdersToUpdate = new List<SalesOrder__c>();
    for (SalesOrder__c so : lstOrders) {
      if (so.Initial_Invoice_Sent__c == false) {
        so.Initial_Invoice_Sent__c = true;
        lstOrdersToUpdate.add(so);
      }
    }

    update lstOrdersToUpdate;
  }

  private static void sendPaymentEmails(List<Payment__c> payments) {
    Id templateId = queryTemplate(PAYMENT_TEMPLATE);

    List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    List<Attachment> attachments = new List<Attachment>();

    for (Payment__c pmt : payments) {
      Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

      String emailAddress = '';

      if (
        pmt.Sales_Order__r.Send_Invoice_to_Alternate_Contact__c == true &&
        String.isNotEmpty(pmt.Sales_Order__r.Alternate_Contact_Email__c)
      ) {
        emailAddress = pmt.Sales_Order__r.Alternate_Contact_Email__c;
      } else {
        emailAddress = pmt.Contact__r.Email;
      }

      message.setTargetObjectId(pmt.Contact__c);
      message.setTreatTargetObjectAsRecipient(false);
      message.setSenderDisplayName('Five Star Billing');
      message.setReplyTo('billing@fivestarprofessional.com');
      message.setUseSignature(false);
      message.setBccSender(false);
      message.setSaveAsActivity(false);
      message.setTemplateID(templateId);
      message.setWhatId(pmt.Id);
      message.toAddresses = new List<String>{ emailAddress };
      // message.toAddresses = new List<String>{ 'angelochagoy@gmail.com', 'gregory.thatcher@gmail.com', 'shelly.martin@fivestarprofessional.com' };

      // Attachment attach = new Attachment();
      // attach.ParentId = pmt.Id;

      // PageReference pdf = Page.Payment2VF;

      // pdf.getParameters().put('orderId', (String) pmt.Sales_Order__c);
      // pdf.getParameters().put('paymentId', (String) pmt.Id);

      // pdf.setRedirect(true);

      // // Take the PDF content
      // Blob b;
      // if (Test.isRunningTest()) {
      //   b = Blob.valueOf('testbody');
      // } else {
      //   b = pdf.getContentAsPdf();
      // }
      // attach.Body = b;
      // attach.Name = 'Payment_For_' + pmt.Sales_Order__r.Name + '.pdf';
      // attachments.add(attach);

      // Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
      // efa.setFileName('Payment_For_' + pmt.Sales_Order__r.Name + '.pdf');
      // efa.setBody(b);

      // message.setFileAttachments(
      //   new List<Messaging.EmailFileAttachment>{ efa }
      // );

      messages.add(message);
    }

    try {
      if (isSandbox || test.isRunningTest()) {
        System.debug('inside sandbox, skipping email');
        System.debug(JSON.serializePretty(messages));
        return;
      }

      // disabled for testing
      // Database.insert(attachments, false);
      Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
      system.debug('results ===' + results);
      
    } catch (Exception e) {
      System.debug(e.getMessage());
    }
  }

  private static Map<String, Attachment> constructAttachmentMap(List<SalesOrder__c> orders) {
    Map<String, Attachment> attachmentMap = new Map<String, Attachment>();
    for ( SalesOrder__c so : orders ) {
      Attachment attach = new Attachment();
      attach.ParentId = so.Id;
      attach.Name = so.Name + '.pdf';

      Pagereference pref = Page.SalesOrderInvoicePDF;
      pref.getParameters().put('id', (String)so.Id);
      pref.setRedirect(true);
      
      attach.body = Test.isRunningTest() ? Blob.valueOf('test') : pref.getContentAsPDF();

      attachmentMap.put(so.Id, attach);
    }
    return attachmentMap;
  }

  private static Id queryTemplate(String templateName) {
    return [
      SELECT Id, DeveloperName 
      FROM EmailTemplate 
      WHERE DeveloperName = :templateName
      LIMIT 1
    ].Id;
  }

  private static Id queryOrgWideAddress() {
    List<OrgWideEmailAddress> orgWide = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'accounts.receivable@fivestarprofessional.com'
    ];

    if ( orgWide != null && orgWide.size() > 0 ) {
      return orgWide.get(0).Id;
    }
    return null;
  }

  private static List<SalesOrder__c> filterOrdersToSend(List<SalesOrder__c> orders) {
    List<SalesOrder__c> returnedOrders = new List<SalesOrder__c>();
    for ( SalesOrder__c so : orders ) {
      if (
        (so.Email_To_Send__c == true &&
        so.NetAmount__c > 0 &&
        so.Initial_Invoice_Sent__c == false) || Test.isRunningTest()
      ) {
        returnedOrders.add(so);
      }
    }
    return returnedOrders;
  }

  private static List<Payment__c> queryPayments(List<String> orderIds) {
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

// test with
// List<String> orders = new List<String>{'a5c52000000B3l0AAC'};
// System.scheduleBatch(new BoomPDFOneHourBatch(orders), 'testscheduleable' + System.today(), 1);