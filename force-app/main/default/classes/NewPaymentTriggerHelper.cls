public without sharing class NewPaymentTriggerHelper {
  public static final String COMPLETED_STATUS = 'Completed';
  public static final String SCHEDULED_STATUS = 'Scheduled';

  public static final List<String> INVALID_STATUSES = new List<String>{
    'Declined',
    'Error',
    'Expired',
    'Reversed',
    'Voided'
  };
  public static final String EMAIL_TEMPLATE = 'Boom_Payment_VF_Template';
  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
  .IsSandbox;

  public static final String MXMERCHANT_PROCESSOR = 'MX Merchant';

  public static void beforeInsert(List<Payment__c> newPayments) {
    Set<Id> pmtMethodIds = new Set<Id>();
    List<Payment__c> paymentsToUpdate = new List<Payment__c>();
    List<Id> SalesOrdersToUnlock = new List<Id>();

    for (Payment__c p : newPayments) {

      if (Approval.isLocked(p.Sales_Order__c)) {
        SalesOrdersToUnlock.add(p.Sales_Order__c);
      }

      if (String.isEmpty(p.Name)) {
        p.Name = 'Payment for Sales Order ' + p.Order_Name__c;
      }

      if (
        String.isEmpty(p.Payment_Processor__c) &&
        p.Payment_Method__c != null &&
        (p.Status__c == SCHEDULED_STATUS ||
        String.isNotEmpty(p.Payment_Token__c))
      ) {
        p.Payment_Processor__c = MXMERCHANT_PROCESSOR;
      }

      if (p.Payment_Method__c != null && String.isEmpty(p.Billing_Name__c)) {
        pmtMethodIds.add(p.Payment_Method__c);
        paymentsToUpdate.add(p);
      }
      
    }

    if(SalesOrdersToUnlock.size() > 0) {
      Approval.unlock(SalesOrdersToUnlock);
    }

    if (pmtMethodIds.size() > 0) {
      Map<Id, Payment_Method__c> pmtMethodMap = new Map<Id, Payment_Method__c>(
        [
          SELECT Id, Billing_First_Name__c, Billing_Last_Name__c
          FROM Payment_Method__c
          WHERE Id IN :pmtMethodIds
        ]
      );

      for (Payment__c p : paymentsToUpdate) {
        Payment_Method__c pm = pmtMethodMap.get(p.Payment_Method__c);
        if (
          String.isNotEmpty(pm.Billing_First_Name__c) &&
          String.isNotEmpty(pm.Billing_Last_Name__c)
        ) {
          p.Billing_Name__c =
            pm.Billing_First_Name__c +
            ' ' +
            pm.Billing_Last_Name__c;
        }
      }
    }
  }

  public static void afterInsert(List<Payment__c> newList) {
    List<Payment__c> completedPayments = new List<Payment__c>();
    List<Id> salesOrdersToLock = new List<Id>();
    for (Payment__c p : newList) {
      if (
        p.Status__c == COMPLETED_STATUS &&
        p.Payment_Method__c != null &&
        p.Order_Release_Date__c != null
      ) {
        completedPayments.add(p);
      }

      if (!Approval.isLocked(p.Sales_Order__c)) {
        salesOrdersToLock.add(p.Sales_Order__c);
      }
    }

    if(salesOrdersToLock.size() > 0) {
      List<SalesOrder__c> queriedOrdersToLock = [SELECT Id FROM SalesOrder__c WHERE Id IN :salesOrdersToLock AND Status_Picklist__c IN ('Released', 'Approved')];
      if(queriedOrdersToLock.size() > 0) {
        Approval.lock(queriedOrdersToLock);
      }
    }

    if (completedPayments.size() > 0) {
      sendEmail(JSON.serialize(completedPayments));
    }
  }

  public static void beforeUpdate(
    List<Payment__c> oldList,
    List<Payment__c> newList
  ) {
    Set<Id> pmtMethodIds = new Set<Id>();
    List<Payment__c> paymentsToUpdate = new List<Payment__c>();
    List<Id> salesOrdersToUnlock = new List<Id>();

    for (Integer i = 0; i < newList.size(); i++) {
        Payment__c p = newList[i];
        Payment__c oldP = oldList[i];

      if (Approval.isLocked(p.Sales_Order__c)) {
        salesOrdersToUnlock.add(p.Sales_Order__c);
      }

      if (
        String.isNotEmpty(p.Payment_Token__c) &&
        String.isEmpty(p.Payment_Processor__c) &&
        p.Payment_Method__c != null
      ) {
        p.Payment_Processor__c = MXMERCHANT_PROCESSOR;
      }

      if (
        (p.Payment_Method__c != oldP.Payment_Method__c ||
        String.isEmpty(p.Billing_Name__c)) && p.Payment_Method__c != null
      ) {
        pmtMethodIds.add(p.Payment_Method__c);
        paymentsToUpdate.add(p);
      }
      
    }
    if(salesOrdersToUnlock.size() > 0) {
      Approval.unlock(salesOrdersToUnlock);
    }

    if (pmtMethodIds.size() > 0) {
      Map<Id, Payment_Method__c> pmtMethodMap = new Map<Id, Payment_Method__c>(
        [
          SELECT Id, Billing_First_Name__c, Billing_Last_Name__c
          FROM Payment_Method__c
          WHERE Id IN :pmtMethodIds
        ]
      );

      for (Payment__c p : paymentsToUpdate) {
        Payment_Method__c pm = pmtMethodMap.get(p.Payment_Method__c);
        if (
          String.isNotEmpty(pm.Billing_First_Name__c) &&
          String.isNotEmpty(pm.Billing_Last_Name__c)
        ) {
          p.Billing_Name__c =
            pm.Billing_First_Name__c +
            ' ' +
            pm.Billing_Last_Name__c;
        }
      }
    }
  }

  public static void afterUpdate(
    List<Payment__c> oldList,
    List<Payment__c> newList
  ) {

    List<Id> unlockedOrders = new List<Id>();


    for (Integer i = 0; i < newList.size(); i++) {
      if (!Approval.isLocked(newList[i].Sales_Order__c)) {
        unlockedOrders.add(newList[i].Sales_Order__c);
      }
    }

    List<SalesOrder__c> ordersToLock = [SELECT Id FROM SalesOrder__c WHERE Id IN :unlockedOrders AND Status_Picklist__c IN ('Approved', 'Released')];
    
    if(ordersToLock.size() > 0) {
      Approval.lock(ordersToLock);
    }
  }

  public static void beforeDelete(List<Payment__c> oldList) {
  }

  @future(callout=true)
  public static void sendEmail(String paymentJson) {
    List<Payment__c> pts = (List<Payment__c>) JSON.deserialize(
      paymentJson,
      List<Payment__c>.class
    );

    DateTime dt = System.Now().addHours(-1);

    List<Payment__c> payments = [
      SELECT
        Id,
        Contact__c,
        Contact__r.Email,
        Sales_Order__c,
        Sales_Order__r.Send_Invoice_to_Alternate_Contact__c,
        Sales_Order__r.Alternate_Contact_Email__c,
        Sales_Order__r.Name
      FROM Payment__c
      WHERE Id IN :pts
      AND Sales_Order__r.Released__c <= :dt
    ];

    Id templateId = [
      SELECT Id, DeveloperName
      FROM EmailTemplate
      WHERE DeveloperName = :EMAIL_TEMPLATE
      LIMIT 1
    ]
    .Id;

    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

    if(payments.size() > 0) {

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
        message.setSenderDisplayName('Five Star Billing');
        message.setReplyTo('billing@fivestarprofessional.com');
        message.setUseSignature(false);
        message.setBccSender(false);
        message.setSaveAsActivity(false);
        message.setTemplateID(templateId);
        message.setWhatId(pmt.Id);
        message.toAddresses = new List<String>{ emailAddress };
  
        
        // PageReference pdf = Page.Payment/2VF;
  
        // pdf.getParameters().put('orderId', (String) pmt.Sales_Order__c);
        // pdf.getParameters().put('paymentId', (String) pmt.Id);
  
        // pdf.setRedirect(true);
  
        // // Take the PDF content
        // Blob b;
        // if (Test.isRunningTest()) {
        //   System.debug('::PAGE REFERENCE');
        //   System.debug(pdf);
        //   b = Blob.valueOf('testbody');
        // } else {
        //   b = pdf.getContentAsPdf();
        // }
        // // Create the email attachment
        // Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        // efa.setFileName('Payment_For_' + pmt.Sales_Order__r.Name + '.pdf');
        // efa.setBody(b);
  
        // message.setFileAttachments(
        //   new List<Messaging.EmailFileAttachment>{ efa }
        // );
  
        messages.add(message);
      }
  
      if (!isSandbox && !Test.isRunningTest()) {
        try {
          Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        } catch (Exception e) {
          System.debug('Error sending email: ' + e.getMessage());
        }
      } else {
        System.debug('Skipping email send in sandbox mode');
        System.debug(JSON.serializePretty(messages));
      }
    }

    
  }
}