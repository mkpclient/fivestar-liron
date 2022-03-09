global without sharing class SendBoomOrderInvoiceAfterOneHour implements Schedulable {
  global List<Id> soIds;
  public static final String ESSENTIAL_ENG = 'Essential Engine';
  public static final String PAYMENT_EMAIL_TEMPLATE = 'Boom_Payment_VF_Template';
  public static final Map<String, String> EMAIL_TEMP_MAP = new Map<String, String> {
    'Five Star' => 'Five_Star_Standard_Email_Template',
    'Essential' => 'Essential_Engine_Email_Template'
  };
  public static final Map<String,String> ORGWIDE_EMAIL_MAP = new Map<String, String> {
    'Five Star' => 'billing@fivestarprofessional.com',
    'Essential' => 'billing@essentialengine.com'
  };

  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
  .IsSandbox;

  public SendBoomOrderInvoiceAfterOneHour(List<id> listofSalesOrderIds) {
    soIds = listofSalesOrderIds;
  }
  global void execute(SchedulableContext ctx) {
    system.debug('inside batch');
    if (System.IsBatch() == false && System.isFuture() == false) {
      system.debug('inside batch1');
      SendEmail(soIds);
      system.debug('inside batch2');
    }
  }

  global static void SendEmail(List<id> listofSalesOrderIds) {

    List<SalesOrder__c> lstOrders = [
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
        Send_Invoice_to_Alternate_Contact__c,
        Price_Book__r.Business_Unit__c
      FROM SalesOrder__c
      WHERE Id IN :listofSalesOrderIds
    ];

    List<Payment__c> payments = [
      SELECT
        Id,
        Contact__c,
        Contact__r.Email,
        Sales_Order__c,
        Sales_Order__r.Name,
      Sales_Order__r.Send_Invoice_to_Alternate_Contact__c,
        Sales_Order__r.Alternate_Contact_Email__c
      FROM Payment__c
      WHERE Sales_Order__c IN :listofSalesOrderIds AND Status__c = 'Completed'
    ];

    List<SalesOrder__c> lstOrdersToSend = new List<SalesOrder__c>();
    for (SalesOrder__c so : lstOrders) {
      System.debug('status' + so.Status_Picklist__c);
      if (
        (so.Email_To_Send__c == true &&
        so.NetAmount__c > 0 &&
        so.Initial_Invoice_Sent__c == false) || test.isrunningtest()
      ) {
        lstOrdersToSend.add(so);
      }
    }
    system.debug('listofSalesOrderIds==' + listofSalesOrderIds);
    List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
   sendPaymentEmails(
      payments
    );

    // Map<String, Attachment> mapOrderIdToAttachment = new Map<String, Attachment>();
    // for (SalesOrder__c order : lstOrdersToSend) {
    //   Attachment attach = new Attachment();
    //   attach.ParentId = order.Id;
    //   PageReference pref = Page.SalesOrderInvoicePDF;
    //   pref.getParameters().put('id', (String) order.Id);
     
    //   pref.setRedirect(true);
    //   if (!test.isRunningTest()) {
    //     Blob b = pref.getContentAsPDF();
    //     attach.Body = b;
    //   }
    //   if (test.isRunningTest()) {
    //     Blob b = blob.valueof('Test error');
    //     attach.Body = b;
    //   }
    //   attach.Name = order.Name + '.pdf';
    //   mapOrderIdToAttachment.put(order.Id, attach);
    // }

    // system.debug('mapOrderIdToAttachment===' + mapOrderIdToAttachment);
    // if (mapOrderIdToAttachment.size() > 0) {
    //   insert mapOrderIdToAttachment.values();
    // }
    // system.debug(
    //   'After Insert mapOrderIdToAttachment===' + mapOrderIdToAttachment
    // );
    for (SalesOrder__c order : lstOrders) {
      String bizType = 'Five Star';

      if(order.Price_Book__r.Business_Unit__c == ESSENTIAL_ENG){
        bizType = 'Essential';
      }
      String Orderid = order.Id;
      String emailTemplateName = EMAIL_TEMP_MAP.get(bizType);
      EmailTemplate et = [
        SELECT Id
        FROM EmailTemplate
        WHERE DeveloperName = :emailTemplateName
      ];
      List<string> toAddress = new List<string>();
      List<string> cCAddress = new List<string>();
      OrgWideEmailAddress[] anOrgWideEmailAddress = [
        SELECT Id
        FROM OrgWideEmailAddress
        WHERE Address = :ORGWIDE_EMAIL_MAP.get(bizType)
      ];

      if (
        order.Send_Invoice_to_Alternate_Contact__c == true &&
        String.isNotEmpty(order.Alternate_Contact_Email__c)
      ) {
        toAddress.add(order.Alternate_Contact_Email__c);
      } else {
        toAddress.add(order.ContactBuying__r.Email);
      }

      cCAddress.add('accounts.receivable@fivestarprofessional.com');
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setTemplateId(et.Id);
      if (anOrgWideEmailAddress != null && anOrgWideEmailAddress.size() > 0) {
        mail.setOrgWideEmailAddressId(anOrgWideEmailAddress[0].Id);
      }
      mail.setCCAddresses(cCAddress);
      mail.setToAddresses(toAddress);
      mail.setTreatTargetObjectAsRecipient(false);
      mail.setTargetObjectId(order.ContactBilling__c);
      mail.setWhatId(Orderid);
      // Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
      // if (!test.isRunningTest()) {
      //   if (mapOrderIdToAttachment.containsKey(Orderid)) {
      //     Blob b = mapOrderIdToAttachment.get(Orderid).Body;
      //     system.debug('Blob b===' + b);
      //     attach.setBody(b);
      //   }
      // } else {
      //   attach.setBody(Blob.valueOf('Test'));
      // }
      // attach.setFileName(order.Name + '.pdf');
      // mail.setFileAttachments(
      //   new List<Messaging.EmailFileAttachment>{ attach }
      // );
      system.debug('mail==' + mail);

      allmsg.add(mail);
    }
    try {
      system.debug('Emails===' + allmsg);
      if (test.isRunningTest()) {
        System.debug('inside sandbox, skipping email');
        System.debug(JSON.serializePretty(lstOrders));
        return;
      }
      Messaging.SendEmailResult[] results = Messaging.sendEmail(allmsg);
      if (results.get(0).isSuccess()) {
        EmailSent(lstOrders);
      }

      system.debug('results ===' + results);
      //Messaging.sendEmail(allmsg);
      return;
    } catch (Exception e) {
      System.debug(e.getMessage());
    }
  }
  global static void EmailSent(List<SalesOrder__c> lstOrders) {
    List<SalesOrder__c> lstOrdersToUpdate = new List<SalesOrder__c>();
    for (SalesOrder__c so : lstOrders) {
      if (so.Initial_Invoice_Sent__c == false) {
        so.Initial_Invoice_Sent__c = true;
        lstOrdersToUpdate.add(so);
      }
    }

    update lstOrdersToUpdate;
  }

  global static void sendPaymentEmails(
    List<Payment__c> payments
  ) {
    Id templateId = [
      SELECT Id, DeveloperName
      FROM EmailTemplate
      WHERE DeveloperName = :PAYMENT_EMAIL_TEMPLATE
      LIMIT 1
    ]
    .Id;

    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

    // List<Attachment> attachments = new List<Attachment>();

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

      // Database.insert(attachments, false);
      Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

      system.debug('results ===' + results);
      
    } catch (Exception e) {
      System.debug(e.getMessage());
    }
  }
}