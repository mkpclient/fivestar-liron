public without sharing class BoomOrderCloneController {
  public static final String FINANCE_FEE_ACC = 'Multi payment Convenience Fee';
  public static final String DISC_PRODUCTNAME = 'Discount';

  @AuraEnabled
  public static Id cloneBoomOrder(Id recordId) {
    Savepoint sp = Database.setSavepoint();
    try {
      String editableFields = getEditableFields('SalesOrder__c');
      String soql =
        'SELECT ' +
        editableFields +
        ' FROM SalesOrder__c WHERE Id = \'' +
        recordId +
        '\' LIMIT 1';
      SalesOrder__c boomOrder = Database.query(soql);
      SalesOrder__c clonedOrder = boomOrder.clone(false, true, false, false);
      clonedOrder.Down_Payment__c= 0;
      clonedOrder.Approval_Status__c = 'Pending';
      clonedOrder.Status_Picklist__c = 'Draft';
      clonedOrder.Release_Status__c = null;
      clonedOrder.DateReleased__c = null;
      clonedOrder.DateApproved__c = null;
      clonedOrder.DateCancelled__c = null;
      clonedOrder.DateSent__c = null;
      clonedOrder.Release_Date__c = null;
      clonedOrder.OrderDate__c = System.today();
      clonedOrder.Released__c = null;
      clonedOrder.FulfillOrder__c = false;
      clonedOrder.FinanceOverride__c = false;
      clonedOrder.Legacy_Id__c = null;
      clonedOrder.Initial_Invoice_Sent__c = false;
      insert clonedOrder;
      cloneOrderProductLines(recordId, clonedOrder.Id);
      cloneAdditionalChargeCredit(recordId, clonedOrder.Id);
      return clonedOrder.Id;
    } catch (Exception e) {
      Database.rollback(sp);
      System.debug('Line '+ e.getLineNumber() + ':' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void cloneAdditionalChargeCredit(
    Id oldBoomOrderId,
    Id newBoomOrderId
  ) {
    Savepoint sp = Database.setSavepoint();
    List<AdditionalChargeCredit__c> acc = [SELECT Id FROM AdditionalChargeCredit__c WHERE Name = :FINANCE_FEE_ACC AND IsActive__c = true LIMIT 1];
    try {
      String editableFields = getEditableFields(
        'SalesOrderAdditionalChargeCredit__c'
      );
      String soql =
        'SELECT ' +
        editableFields +
        ' FROM SalesOrderAdditionalChargeCredit__c WHERE SalesOrder__c = \'' +
        oldBoomOrderId +
        '\'';
      List<SalesOrderAdditionalChargeCredit__c> oldACCs = Database.query(soql);
      if (oldACCs.size() > 0) {
        List<SalesOrderAdditionalChargeCredit__c> newACCs = new List<SalesOrderAdditionalChargeCredit__c>();
        for (SalesOrderAdditionalChargeCredit__c oA : oldACCs) {
          if(acc.size() > 0 && oA.Additional_Charge_Credit__c == acc[0].Id){
            continue;
          }
            SalesOrderAdditionalChargeCredit__c nA = oA.clone(false, true, false, false);
            nA.SalesOrder__c = newBoomOrderId;
            nA.Adjustment_Date__c = null;
            nA.Intacct_Sync_Complete__c = false;
            nA.Legacy_Id__c = null;
            newACCs.add(nA);
        }
        insert newACCs;
      }
    } catch (Exception e) {
      Database.rollback(sp);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static void cloneOrderProductLines(
    Id oldBoomOrderId,
    Id newBoomOrderId
  ) {
    Savepoint sp = Database.setSavepoint();
    List<Product2> discProd = [SELECT Id FROM Product2 WHERE Name = :DISC_PRODUCTNAME AND IsActive = true LIMIT 1];

    try {
      String editableFields = getEditableFields('SalesOrderProductLine__c');
      String soql =
        'SELECT ' +
        editableFields +
        ', (SELECT Id, Recipient__c, Primary__c FROM Order_Line_Recipients__r)' +
        ' FROM SalesOrderProductLine__c WHERE SalesOrder__c = \'' +
        oldBoomOrderId +
        '\'';
      List<SalesOrderProductLine__c> oldOrderProductLines = Database.query(
        soql
      );
      if (oldOrderProductLines.size() > 0) {
        Map<Id, SalesOrderProductLine__c> clonedOrderProductLines = new Map<Id, SalesOrderProductLine__c>();
        Map<Id, List<Order_Line_Recipient__c>> oldOrderLineRecipients = new Map<Id, List<Order_Line_Recipient__c>>();
        for (
          SalesOrderProductLine__c oldOrderProductLine : oldOrderProductLines
        ) {
          if(discProd.size() > 0 && oldOrderProductLine.Product__c == discProd[0].Id) {
            continue;
          }
          if (oldOrderProductLine.KitBundleLine__c == null) {
            SalesOrderProductLine__c clonedOrderProductLine = oldOrderProductLine.clone(
              false,
              true,
              false,
              false
            );
            
            oldOrderLineRecipients.put(
              oldOrderProductLine.Id,
              oldOrderProductLine.Order_Line_Recipients__r
            );
            String clonedJson = JSON.serialize(clonedOrderProductLine);
            clonedJson =
              clonedJson.substringBefore(',"Order_Line_Recipients__r"') +
              clonedJson.substringAfter(']');
            
            clonedOrderProductLine = (SalesOrderProductLine__c) JSON.deserialize(
              clonedJson,
              SalesOrderProductLine__c.class
            );
            clonedOrderProductLine.SalesOrder__c = newBoomOrderId;
            clonedOrderProductLine.Recipient_Count__c = 0;
            clonedOrderProductLine.DateRequired__c = System.today();
            clonedOrderProductLine.Void_Date__c = null;
            clonedOrderProductLine.Legacy_Id__c = null;
            clonedOrderProductLine.Intacct_Sync_Complete__c = false;
            clonedOrderProductLines.put(
              oldOrderProductLine.Id,
              clonedOrderProductLine
            );
          }
        }

        try {
          insert clonedOrderProductLines.values();
        } catch (DmlException err) {
          System.debug('Error on cloning product lines: ' + err.getMessage());
          throw err;
        }


        List<Order_Line_Recipient__c> autoGeneratedRecipients = [
          SELECT Id
          FROM Order_Line_Recipient__c
          WHERE OrderProductLine__c = :clonedOrderProductLines.values()
        ];

        // delete automatically generated recipients generated by trigger
        
        try {
          delete autoGeneratedRecipients;
        } catch (DmlException err) {
          System.debug('From deleting recipients generated by trigger: ' + err.getMessage());
          throw err;
        }

        List<Order_Line_Recipient__c> newRecipients = new List<Order_Line_Recipient__c>();
        for (Id oldId : clonedOrderProductLines.keySet()) {
          SalesOrderProductLine__c clonedPL = clonedOrderProductLines.get(
            oldId
          );
          for(Order_Line_Recipient__c oldRecipient : oldOrderLineRecipients.get(oldId)) {
            Order_Line_Recipient__c newRecipient = new Order_Line_Recipient__c();
            newRecipient.Recipient__c = oldRecipient.Recipient__c;
            newRecipient.Order__c = newBoomOrderId;
            newRecipient.OrderProductLine__c = clonedPL.Id;
            newRecipient.Primary__c = oldRecipient.Primary__c;
            newRecipient.Legacy_Id__c = null;
            newRecipients.add(newRecipient);
          }
        }

        try {
          insert newRecipients;
        } catch (DmlException err) {
          System.debug('From inserting new recipients '+ err.getLineNumber() + ':' + err.getMessage());
          throw err;
        }
        
      }
    } catch (Exception e) {
      Database.rollback(sp);
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static String getEditableFields(String sobjectName) {
    Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe()
      .get(sobjectName)
      .getDescribe()
      .fields.getMap();
    String editableFields = '';
    for (Schema.SObjectField fieldRef : fields.values()) {
      Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
      if (fieldResult.isUpdateable()) {
        editableFields += fieldResult.getname() + ',';
      }
    }
    editableFields = editableFields.removeEnd(',');
    return editableFields;
  }
}