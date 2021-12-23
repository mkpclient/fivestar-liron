public without sharing class PaymentBatchableHelper {
  public static Map<String, String> templateMap = new Map<String, String>{
    'Declined' => 'New_Credit_Card_Declined',
    'Approved' => 'New_Payment_Reciept_PDF'
  };

  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
  .IsSandbox;

  public static String sendEmail(
    String status,
    Id paymentId,
    Id contactId,
    String contactEmail,
    Id salesOrderId,
    Boolean isActive
  ) {
    Id templateId = queryTemplateId(status);
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    List<String> ccAddresses = new List<String>{'accounts.receivable@fivestarprofessional.com'};
    message.setTargetObjectId(contactId);
    message.setSenderDisplayName('Five Star Billing');
    message.setReplyTo('billing@fivestarprofessional.com');
    message.setUseSignature(false);
    message.setBccSender(false);
    message.setSaveAsActivity(false);
    message.setTemplateID(templateId);
    message.setWhatId(paymentId);
    message.toAddresses = new List<String>{ contactEmail };
    message.setccAddresses(ccAddresses);

    if(status == 'Approved') {
      PageReference pdf = Page.Payment2VF;

      pdf.getParameters().put('orderId', (String) salesOrderId);
      pdf.getParameters().put('paymentId', (String) paymentId);
      Blob b;
      if (Test.isRunningTest()) {
        b = Blob.valueOf('testbody');
      } else {
        b = pdf.getContent();
      }
      // Create the email attachment
      Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
      efa.setFileName('Payment_Invoice.pdf');
      efa.setBody(b);

      message.setFileAttachments(
        new List<Messaging.EmailFileAttachment>{ efa }
      );

    }

    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{
      message
    };
    if (isActive && !isSandbox) {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

      if (results[0].success) {
        return 'Success';
      } else {
        return 'Error';
      }
    } else {
      return 'Success';
    }
  }

  public static Id queryTemplateId(String status) {
    EmailTemplate temp = [
      SELECT Id, DeveloperName
      FROM EmailTemplate
      WHERE DeveloperName = :templateMap.get(status)
      LIMIT 1
    ];

    return temp.Id;
  }
}