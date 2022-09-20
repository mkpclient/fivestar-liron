public without sharing class PaymentBatchableHelper {
  public static Map<String, Id> templateMap = new Map<String, Id>{
    'Declined' => queryTemplateId('New_Credit_Card_Declined'),
    'Declined_Essential' => queryTemplateId('New_Credit_Card_Declined_Essential'),
    'Approved' => queryTemplateId('Boom_Payment_VF_Template'),
    'Approved_Essential' => queryTemplateId('Essential_Payment_VF_Template')
  };

  public static final String ESSENTIAL_ENG = 'Essential Engine';

  public static OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'billing@fivestarprofessional.com'];

  public static final Map<String,OrgWideEmailAddress> ORGWIDE_EMAIL_MAP = new Map<String, OrgWideEmailAddress> {
    'Approved' => [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'billing@fivestarprofessional.com'
    ],
    'Approved_Essential' => [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'billing@essentialengine.com'
    ],
    'Declined' => [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'billing@fivestarprofessional.com'
    ],
    'Declined_Essential' => [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'billing@essentialengine.com'
    ]
  };

  public static Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1]
  .IsSandbox;

  public static string processEmails(List<Payment__c> newPayments) {

    Messaging.SingleEmailMessage[] approvedMessages = new List<Messaging.SingleEmailMessage>();
    Messaging.SingleEmailMessage[] declinedMessages = new List<Messaging.SingleEmailMessage>();
    Boolean allowEssentialEmails = FivestarSetting__mdt.getInstance('Universal') != null &&
    FivestarSetting__mdt.getInstance('Universal').Allow_Essential_Engine_Emails__c;
    Boolean sendEEReceipts = FivestarSetting__mdt.getInstance('Universal') != null && FivestarSetting__mdt.getInstance('Universal').Send_Essential_Engine_Payment_Receipts__c;
    

    for (Payment__c s : newPayments) {
      if(s.Sales_Order__r.Price_Book__r.Business_Unit__c == ESSENTIAL_ENG && (!allowEssentialEmails || !sendEEReceipts)) {
       continue;
      }
  
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
        String statusText = '';

        if (s.Status__c == 'Completed') {
          if(s.Sales_Order__r.Price_Book__r.Business_Unit__c == ESSENTIAL_ENG && allowEssentialEmails && sendEEReceipts) {
            statusText = 'Approved_Essential';
          } else {
            statusText = 'Approved';
          }
        } else {
          statusText = s.Sales_Order__r.Price_Book__r.Business_Unit__c == ESSENTIAL_ENG && allowEssentialEmails ? 'Declined_Essential' : 'Declined';
        }

        if(s.Status__c == 'Completed') {
          approvedMessages.add(sendEmail(
          statusText,
          s.Id,
          s.Contact__c,
          emailAddress,
          s.Sales_Order__c,
          true
        ));
        } else if (s.Status__c == 'Declined') {
          declinedMessages.add(sendEmail(
          statusText,
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
        results.addAll(Messaging.sendEmail(approvedMessages, false));
      }

      if(declinedMessages.size() > 0) {
        results.addAll(Messaging.sendEmail(declinedMessages, false));
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
    List<String> ccAddresses = new List<String>();
    if(status.containsIgnoreCase('essential')){
      ccAddresses.add('billing@essentialengine.com');
    } else {
      ccAddresses.add('accounts.receivable@fivestarprofessional.com');
    }
    message.setTargetObjectId(contactId);
    
    if(ORGWIDE_EMAIL_MAP.get(status) != null) {
      message.setOrgWideEmailAddressId(ORGWIDE_EMAIL_MAP.get(status).Id);
    }
    
    message.setUseSignature(false);
    message.setBccSender(false);
    message.setSaveAsActivity(false);
    message.setTemplateID(templateId);
    message.setWhatId(paymentId);
    message.toAddresses = new List<String>{ contactEmail };
    if(ccAddresses.size() > 0) {
    message.setccAddresses(ccAddresses);
    }
    

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