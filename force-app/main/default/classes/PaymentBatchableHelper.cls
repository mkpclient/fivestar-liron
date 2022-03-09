public without sharing class PaymentBatchableHelper {
  public static Map<String, Id> templateMap = new Map<String, Id>{
    'Declined' => queryTemplateId('New_Credit_Card_Declined'),
    'Approved' => queryTemplateId('Boom_Payment_VF_Template')
  };

  public static OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'billing@fivestarprofessional.com'];


  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
  .IsSandbox;

  public static string processEmails(List<Payment__c> newPayments) {

    Messaging.SingleEmailMessage[] approvedMessages = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage[] declinedMessages = new List<Messaging.SingleEmailMessage>();

    for (Payment__c s : newPayments) {
      String emailAddress = '';

      if (
        s.Sales_Order__r.Send_Invoice_to_Alternate_Contact__c == true &&
        String.isNotEmpty(s.Sales_Order__r.Alternate_Contact_Email__c)
      ) {
        emailAddress = s.Sales_Order__r.Alternate_Contact_Email__c;
      } else {
        emailAddress = s.Contact__r.Email;
      }

      if (String.isNotEmpty(emailAddress)) {

        if(s.Status__c == 'Completed') {
          approvedMessages.add(sendEmail(
          'Approved',
          s.Id,
          s.Contact__c,
          emailAddress,
          s.Sales_Order__c,
          true
        ));
        } else if (s.Status__c == 'Declined') {
          declinedMessages.add(sendEmail(
          'Declined',
          s.Id,
          s.Contact__c,
          emailAddress,
          s.Sales_Order__c,
          true
        ));
        }
        
      }

    }

    if (!isSandbox) {
      Messaging.SendEmailResult[] results = new List<Messaging.SendEmailResult>();
      if (approvedMessages.size() > 0) {
        results.addAll(Messaging.sendEmail(approvedMessages));
      }

      if(declinedMessages.size() > 0) {
        results.addAll(Messaging.sendEmail(declinedMessages));
      }

      if (results.size() > 0 && results[0].success) {
        return 'Success';
      } else {
        return 'Error';
      }
    } else {
      return 'Success';
    }
  }

  public static Messaging.SingleEmailMessage sendEmail(
    String status,
    Id paymentId,
    Id contactId,
    String contactEmail,
    Id salesOrderId,
    Boolean isActive
  ) {
    Id templateId = templateMap.get(status);
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    List<String> ccAddresses = new List<String>{'accounts.receivable@fivestarprofessional.com'};
    message.setTargetObjectId(contactId);

    if(owea.size() > 0) {
      message.setOrgWideEmailAddressId(owea[0].Id);
    }
    
    message.setUseSignature(false);
    message.setBccSender(false);
    message.setSaveAsActivity(false);
    message.setTemplateID(templateId);
    message.setWhatId(paymentId);
    message.toAddresses = new List<String>{ contactEmail };
    message.setccAddresses(ccAddresses);

    if(status == 'Approved') {
      // PageReference pdf = Page.Payment2VF;

      // pdf.getParameters().put('orderId', (String) salesOrderId);
      // pdf.getParameters().put('paymentId', (String) paymentId);
      // Blob b;
      // if (Test.isRunningTest()) {
      //   b = Blob.valueOf('testbody');
      // } else {
      //   b = pdf.getContent();
      // }
      // // Create the email attachment
      // Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
      // efa.setFileName('Payment_Invoice.pdf');
      // efa.setBody(b);

      // message.setFileAttachments(
      //   new List<Messaging.EmailFileAttachment>{ efa }
      // );

    }

    return message;
    
  }

  public static Id queryTemplateId(String tempName) {
    EmailTemplate temp = [
      SELECT Id, DeveloperName
      FROM EmailTemplate
      WHERE DeveloperName = :tempName
      LIMIT 1
    ];

    return temp.Id;
  }
}