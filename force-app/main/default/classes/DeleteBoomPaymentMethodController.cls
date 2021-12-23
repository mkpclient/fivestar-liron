public with sharing class DeleteBoomPaymentMethodController {
  public Payment_Method__c pm { get; set; }

  public DeleteBoomPaymentMethodController(ApexPages.StandardController sc) {
    pm = (Payment_Method__c) sc.getRecord();
  }

  public Pagereference doDelete() {
    if (pm != null) {
      Id ctId = pm.Contact__c;
      if (
        String.isNotEmpty(pm.ExternalId__c) &&
        String.isNotEmpty(pm.MX_Customer_Id__c)
      ) {
        handleApiDelete(pm.ExternalId__c, pm.MX_Customer_Id__c);
        delete pm;
      } else {
        delete pm;
      }

      return new ApexPages.standardController(new Contact(Id = ctId)).view();
    } else {
      return null;
    }
  }

  @future(callout=true)
  public static void handleApiDelete(String externalId, String mxCustomerId) {
    Zealynx.CreditCardResource creditCardResource = new Zealynx.CreditCardResource();
    creditCardResource.customerId = long.valueOf(mxCustomerId);
    creditCardResource.id = long.valueOf(externalId);
    try {
      creditCardResource.deleteCard();
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw e;
    }
  }
}