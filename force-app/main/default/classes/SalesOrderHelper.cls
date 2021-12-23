public without sharing class SalesOrderHelper {
  static final String RELEASED_STATUS = 'Released';
  static final String UNRELEASED_STATUS = 'Unreleased';
  static final String CANCELLED_STATUS = 'Cancelled';
  static final String APPROVED_STATUS = 'Approved';
  static final String DRAFT_STATUS = 'Draft';

  public static void beforeUpdate(
    Map<Id, SalesOrder__c> oldMap,
    Map<Id, SalesOrder__c> newMap
  ) {
    for (Id key : newMap.keySet()) {
      SalesOrder__c oldSO = oldMap.get(key);
      SalesOrder__c newSO = newMap.get(key);

      // skipping legacy orders
      if (String.isEmpty(newSO.Legacy_Id__c)) {
        // when SO meets all release criteria
        Approval.unlock(newSO.Id);
        if (
          newSO.Status_Picklist__c == APPROVED_STATUS &&
          newSO.ExistingPayments__c >= newSO.NetAmount__c &&
          newSO.FinanceOverride__c != true &&
          newSO.Status_Picklist__c != RELEASED_STATUS &&
          (newSO.NetAmount__c != 0 ||
          (newSO.Approved_Complimentary_Order__c == true ||
          newSO.Complaint_Order__c == true ||
          newSO.Sample_ELM_Copy__c == true))
        ) {
          if (newSO.DateReleased__c == null) {
            newSO.DateReleased__c = Date.today();
          }
          newSO.Release_Date__c = Date.today();
          newSO.Status_Picklist__c = RELEASED_STATUS;
          newSO.Released__c = System.now();
          newSO.FulfillOrder__c = true;
          newSO.Email_To_Send__c = true;
        }

        // when SO gets unreleased
        if (
          (newSO.Status_Picklist__c != oldSO.Status_Picklist__c) &&
          (newSO.Status_Picklist__c == UNRELEASED_STATUS)
        ) {
          newSO.FinanceOverride__c = true;
        }
      }
    }
  }

  public static void afterUpdate(
    List<SalesOrder__c> newList,
    List<SalesOrder__c> oldList
  ) {
    Map<Id, SalesOrder__c> salesOrderMap = new Map<Id, SalesOrder__c>();
    Set<Id> salesOrderIds = new Set<Id>();
    List<Id> salesOrderIdsList = new List<Id>();
    Set<Id> recordsToLock = new Set<Id>();
    Set<Id> paymentsToCancel = new Set<Id>();

    for (Integer i = 0; i < newList.size(); i++) {
      // we do not want legacy orders running through the triggers
      if (String.isEmpty(newList[i].Legacy_Id__c)) {
        if (orderNeedsFulfillmentsCreated(newList[i], oldList[i])) {
          salesOrderMap.put(newList[i].Id, newList[i]);
        } else if (orderWasCancelled(newList[i], oldList[i])) {
        }

        if (
          oldList[i].BalanceDueAmount__c != newList[i].BalanceDueAmount__c &&
          newList[i].BalanceDueAmount__c == 0 &&
          newList[i].NetAmount__c != null && newList[i].NetAmount__c != 0
        ) {
          paymentsToCancel.add(newList[i].Id);
        }

        if (
          newList[i].Initial_Invoice_Sent__c != true &&
          newList[i].Email_To_Send__c == true &&
          newList[i].Status_Picklist__c == RELEASED_STATUS
        ) {
          salesOrderIdsList.add(newList[i].Id);
        }

        if (oldList[i].Price_Book__c != newList[i].Price_Book__c) {
          salesOrderIds.add(newList[i].Id);
        }

        if (
          !Approval.isLocked(newList[i].Id) &&
          (newList[i].Status_Picklist__c == 'Released' ||
          newList[i].Status_Picklist__c == 'Approved')
        ) {
          recordsToLock.add(newList[i].Id);
        }
      }
    }

    if (salesOrderMap.size() > 0) {
      createfulfillments(salesOrderMap.keySet());
      // createInvoice(salesOrderMap.values());
    }

    if (salesOrderIdsList.size() > 0) {
      BoomOrderInvoiceWithAttachment.sendEmailWithAttachment(salesOrderIdsList);
    }

    if (salesOrderIds.size() > 0) {
      // ? : all order product lines are deleted when price book is changed
      deleteOrderProductLines(salesOrderIds);
    }

    if (paymentsToCancel.size() > 0) {
      cancelScheduledPayments(paymentsToCancel);
    }

    for (Id id : recordsToLock) {
      Approval.lock(id);
    }
  }

  public static void beforeDelete(List<SalesOrder__c> oldList) {
    for (Integer i = 0; i < oldList.size(); i++) {
      if (
        (oldList[i].Status_Picklist__c != DRAFT_STATUS ||
        oldList[i].ExistingPayments__c > 0) &&
        String.isEmpty(oldList[i].Legacy_Id__c)
      ) {
        oldList[i]
          .addError(
            'Cannot delete sales orders that aren\'t in draft and has payments.'
          );
      }
    }
  }

  public static void deleteOrderProductLines(Set<Id> salesOrderIds) {
    List<Order_Line_Recipient__c> lineRecips = [
      SELECT Id
      FROM Order_Line_Recipient__c
      WHERE Order__c IN :salesOrderIds
    ];

    List<SalesOrderProductLine__c> prodLines = [
      SELECT Id
      FROM SalesOrderProductLine__c
      WHERE SalesOrder__c IN :salesOrderIds
    ];

    if (lineRecips.size() > 0) {
      Database.delete(lineRecips, false);
    }

    if (prodLines.size() > 0) {
      Database.delete(prodLines, false);
    }

    System.debug(
      'Deleted ' +
      lineRecips.size() +
      ' line recipients' +
      ' and ' +
      prodLines.size() +
      ' product lines'
    );
  }

  public static Boolean orderNeedsFulfillmentsCreated(
    SalesOrder__c newRecord,
    SalesOrder__c oldRecord
  ) {
    return (newRecord.FulfillOrder__c == true &&
    oldRecord.FulfillOrder__c == false);
  }

  public static Boolean orderWasCancelled(
    SalesOrder__c newRecord,
    SalesOrder__c oldRecord
  ) {
    return (newRecord.RecordStatus__c == CANCELLED_STATUS &&
    newRecord.RecordStatus__c != oldRecord.RecordStatus__c);
  }

  public static void createfulfillments(Set<Id> orderIds) {
    List<Order_Fulfillment__c> fulfillments = new List<Order_Fulfillment__c>();
    for (SalesOrderProductLine__c l : queryOrderProductLines(orderIDs)) {
      fulfillments.add(constructFulfillment(l));
    }
    insert fulfillments;
  }

  public static List<SalesOrderProductLine__c> queryOrderProductLines(
    Set<Id> orderIds
  ) {
    return [
      SELECT
        Id,
        ContactShipping__c,
        Product__r.Name,
        SalesOrder__c,
        SalesOrder__r.Market__c,
        (
          SELECT Id, Recipient__c, Primary__c
          FROM Order_Line_Recipients__r
          WHERE Primary__c = TRUE
          LIMIT 1
        )
      FROM SalesOrderProductLine__c
      WHERE
        SalesOrder__c IN :orderIds
        AND Product__r.CreateOrderFulfillment__c = TRUE
        AND Quantity__c > 0
    ];
  }

  public static void cancelScheduledPayments(Set<Id> orderIds) {
    List<Payment__c> payments = [
      SELECT Id
      FROM Payment__c
      WHERE Status__c = 'Scheduled' AND Sales_Order__c IN :orderIds
    ];

    if (payments.size() > 0) {
      for (Payment__c p : payments) {
        p.Date__c = null;
        p.Status__c = 'Cancelled';
      }

      update payments;
    }
  }

  // ? : from 11/OCT meeting with Fivestar, we do not need to fill in the value for ParentFulfillment__c

  public static Order_Fulfillment__c constructFulfillment(
    SalesOrderProductLine__c l
  ) {
    Order_Fulfillment__c f = new Order_Fulfillment__c();
    // f.Activity_Subject_Choices__c = '';
    // f.Ad_Prod_Alternate_Contact__c = null;
    // f.Ad_Prod_Alternate_Email__c = '';
    // f.Ad_Prod_Alternate_Notes__c = '';
    // f.Ad_Prod_Alternate_Phone__c = '';
    // f.Appropriate_Template_Opened__c = false;
    // f.approved_completed__c = false;
    // f.Auto_Post__c = false;
    // f.Back_Cover_Inside_Ad_Template__c = '';
    // f.Back_Cover_Ad_Form__c = '';
    // f.Boosted__c = false;
    // f.Build_from_Existing_Proflie__c = false;
    // f.Build_Reprint_from_Profile__c = false;
    // f.Callback_Date__c = null;
    // f.CFP__c = false;
    // f.Change_status_to_Send_Initial_Proof__c = false;
    // f.Client_Contact_List__c = '';
    // f.Client_Contact_List_2__c = '';
    // f.Client_Success_Tracker_URL__c = '';
    // f.Client_Tier__c = '';
    f.Contact__c = l.ContactShipping__c;
    f.OrderProductLine__c = l.Id;
    f.Status__c = 'New Profile';
    f.PrimaryRecipient__c = l.Order_Line_Recipients__r[0].Recipient__c;
    f.Product_Name__c = l.Product__r.Name;
    f.Market__c = l.SalesOrder__r.Market__c;
    f.OrderNumber__c = l.SalesOrder__c;
    return f;
  }

  // public static void createInvoice(List<SalesOrder__c> soDetails) {

  //   Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
  //   Map<String, Schema.SObjectField> invoiceFields = schemaMap.get('Invoice__c')
  //     .getDescribe()
  //     .fields.getMap();
  //   List<Invoice__c> newInvoices = new List<Invoice__c>();
  //   for (SalesOrder__c so : soDetails) {
  //     Map<String, Object> soFields = so.getPopulatedFieldsAsMap();
  //     Invoice__c inv = new Invoice__c();
  //     inv.SalesOrder__c = so.Id;

  //     for (String field : soFields.keySet()) {
  //       Object value = soFields.get(field);
  //       if (
  //         invoiceFields.containsKey(field) &&
  //         invoiceFields.get(field).getDescribe().isUpdateable()
  //       ) {
  //         inv.put(field, soFields.get(field));
  //       }
  //     }

  //     newInvoices.add(inv);
  //   }
  //   try {
  //     if (newInvoices.size() > 0) {
  //       Database.insert(newInvoices, false);
  //       System.Debug(JSON.serialize(newInvoices));
  //       List<OrderInvoiceRelationship__c> newOIR = new List<OrderInvoiceRelationship__c>();
  //       for (Invoice__c inv : newInvoices) {
  //         newOIR.add(
  //           new OrderInvoiceRelationship__c(
  //             SalesOrder__c = inv.SalesOrder__c,
  //             Invoice__c = inv.Id
  //           )
  //         );
  //       }
  //       Database.insert(newOIR, false);
  //     }
  //   } catch (DmlException err) {
  //     System.debug(
  //       JSON.serialize(
  //         new Map<String, String>{
  //           'Error creating invoice' => err.getMessage()
  //         }
  //       )
  //     );
  //   }
  // }
}