@istest(seeAllData=true)
public class FiveStarHelper_TEST {

  @isTest
  static void appliedPayment() {
    List<kugo2p__AppliedPayment__c> appliedPayments = [
      SELECT
        Id,
        kugo2p__AmountApplied__c,
        kugo2p__InvoiceAdditionalChargeCredit__c,
        kugo2p__InvoiceLine__c,
        kugo2p__Invoice__c,
        kugo2p__SalesOrderAdditionalChargeCredit__c,
        kugo2p__SalesOrder__c,
        kugo2p__SalesOrderProductLine__c,
        kugo2p__SalesOrderServiceLine__c,
        kugo2p__Payment__c
      FROM kugo2p__AppliedPayment__c
      WHERE kugo2p__SalesOrder__r.kugo2p__OrderName__c = 'Test Opportunity'
      LIMIT 1
    ];
    // Savepoint sp = Database.setSavepoint();
    // kugo2p__AppliedPayment__c testAppliedPayment = appliedPayments[0]
    //   .clone(false, true);
    // insert testAppliedPayment;

    // kugo2p_AppliedPayment_Queueable.touchAppliedPaymentsToStartLogic(
    //   new List<kugo2p__AppliedPayment__c>{ appliedPayments[0] }
    // );
    // Database.rollback(sp);
  }

  @istest
  static void assign_market() {
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT Id, kugo2p__Opportunity__c
      FROM kugo2p__SalesOrder__c
      WHERE kugo2p__Opportunity__c IN :ids
    ];

    // FiveStarHelper.assignMarket(orders);
  }

  @istest
  static void update_locked_price_line_discount() {
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT Id, kugo2p__DiscountPercent__c, kugo2p__Opportunity__c
      FROM kugo2p__SalesOrder__c
      WHERE kugo2p__DiscountPercent__c != NULL
      LIMIT 20
    ];

    Map<Id, kugo2p__SalesOrder__c> salesOrderMap = new Map<Id, kugo2p__SalesOrder__c>();
    for (kugo2p__SalesOrder__c so : orders) {
      salesOrderMap.put(so.Id, so);
    }

    List<kugo2p__SalesOrder__c> newOrders = new List<kugo2p__SalesOrder__c>();
    for (Integer i = 0; i < orders.size(); i++) {
      kugo2p__SalesOrder__c sale = new kugo2p__SalesOrder__c();
      sale.Id = orders[i].Id;
      sale.kugo2p__DiscountPercent__c =
        orders[i].kugo2p__DiscountPercent__c + 20;
      sale.kugo2p__Opportunity__c = orders[i].kugo2p__Opportunity__c;
      newOrders.add(sale);
    }
    Map<Id, kugo2p__SalesOrder__c> newSalesOrderMap = new Map<Id, kugo2p__SalesOrder__c>();
    for (kugo2p__SalesOrder__c kso : newOrders) {
      newSalesOrderMap.put(kso.Id, kso);
    }
    // FiveStarHelper.updateLockedPriceLineDiscount(
    //   newSalesOrderMap,
    //   salesOrderMap
    // );
  }

  @istest
  static void fulfill_orders() {
    Integer deleteCount = 0;
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT
        Id,
        kugo2p__DiscountPercent__c,
        kugo2p__Opportunity__c,
        FulFillOrder__c,
        kugo2p__RecordStatus__c
      FROM kugo2p__SalesOrder__c
      LIMIT 100
    ];

    Map<Id, kugo2p__SalesOrder__c> salesOrderMap = new Map<Id, kugo2p__SalesOrder__c>();
    for (kugo2p__SalesOrder__c so : orders) {
      salesOrderMap.put(so.Id, so);
    }

    List<kugo2p__SalesOrder__c> newOrders = new List<kugo2p__SalesOrder__c>();
    for (Integer i = 0; i < orders.size(); i++) {
      kugo2p__SalesOrder__c sale = new kugo2p__SalesOrder__c();
      sale.Id = orders[i].Id;
      sale.FulFillOrder__c = !orders[i].FulFillOrder__c;
      sale.kugo2p__Opportunity__c = orders[i].kugo2p__Opportunity__c;
      if (deleteCount < 1) {
        sale.kugo2p__RecordStatus__c = 'Cancelled';
        deleteCount++;
      }
      newOrders.add(sale);
    }
    Map<Id, kugo2p__SalesOrder__c> newSalesOrderMap = new Map<Id, kugo2p__SalesOrder__c>();
    for (kugo2p__SalesOrder__c kso : newOrders) {
      newSalesOrderMap.put(kso.Id, kso);
    }
    // FiveStarHelper.fulfillOrders(newSalesOrderMap, salesOrderMap);
  }

  @istest
  static void assign_line_receipient_account_manager() {
    Integer deleteCount = 0;
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();
    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    Set<Id> orderIds = new Set<Id>();
    List<kugo2p__SalesOrder__c> orders = [
      SELECT
        Id,
        kugo2p__DiscountPercent__c,
        kugo2p__Opportunity__c,
        FulFillOrder__c,
        kugo2p__RecordStatus__c
      FROM kugo2p__SalesOrder__c
      WHERE kugo2p__Opportunity__c IN :ids
    ];
    for (kugo2p__SalesOrder__c so : orders) {
      orderIds.add(so.Id);
    }

    List<LineRecipient__c> recipients = [
      SELECT Id, AccountManager__c, Order__c
      FROM LineRecipient__c
      LIMIT 20
    ];
    for (LineRecipient__c l : recipients) {
      if (deleteCount < 1) {
        l.AccountManager__c = null;
      }
    }

    // FiveStarHelper.assignLineRecipientAccountManager(recipients);
  }

  @istest
  static void delete_fulfillment_and_line_recipients() {
    Set<Id> ids = new Set<Id>{ UserInfo.getUserId() };
    FiveStarHelper.deleteFulfillmentAndLineRecipients(ids);
  }

  @istest
  static void schedule_send_email_class() {
    Integer deleteCount = 0;
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT
        Id,
        kugo2p__DiscountPercent__c,
        kugo2p__Opportunity__c,
        FulFillOrder__c,
        kugo2p__RecordStatus__c
      FROM kugo2p__SalesOrder__c
      WHERE kugo2p__Opportunity__c IN :ids
    ];

    Map<Id, kugo2p__SalesOrder__c> salesOrderMap = new Map<Id, kugo2p__SalesOrder__c>();
    for (kugo2p__SalesOrder__c so : orders) {
      salesOrderMap.put(so.Id, so);
    }

    List<kugo2p__SalesOrder__c> newOrders = new List<kugo2p__SalesOrder__c>();
    for (Integer i = 0; i < orders.size(); i++) {
      kugo2p__SalesOrder__c sale = new kugo2p__SalesOrder__c();
      sale.Id = orders[i].Id;
      sale.FulFillOrder__c = !orders[i].FulFillOrder__c;
      sale.kugo2p__Opportunity__c = orders[i].kugo2p__Opportunity__c;
      if (deleteCount < 1) {
        sale.Initial_Invoice_Sent__c = false;
        deleteCount++;
      }
      newOrders.add(sale);
    }
    Map<Id, kugo2p__SalesOrder__c> newSalesOrderMap = new Map<Id, kugo2p__SalesOrder__c>();
    for (kugo2p__SalesOrder__c kso : newOrders) {
      newSalesOrderMap.put(kso.Id, kso);
    }

    // FiveStarHelper.scheduleSendEmailClass(newOrders, salesOrderMap);
  }

  @istest
  static void update_line_recipient_count() {
    List<LineRecipient__c> lrs = [
      SELECT Id, OrderProductLine__c
      FROM LineRecipient__c
      LIMIT 10
    ];
    // FiveStarHelper.updateLineRecipientCount(lrs);
  }

  @istest
  static void create_kit_member_fulfillments() {
    Integer changeCount = 0;

    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT Id, kugo2p__Opportunity__c
      FROM kugo2p__SalesOrder__c
      LIMIT 30
    ];
    Set<Id> orderIds = new Set<Id>();
    for (kugo2p__SalesOrder__c s : orders) {
      orderIds.add(s.Id);
    }

    Map<Id, kugo2p__SalesOrderProductLine__c> sopl = new Map<Id, kugo2p__SalesOrderProductLine__c>(
      [
        SELECT Id, kugo2p__KitBundleLine__c
        FROM kugo2p__SalesOrderProductLine__c
        WHERE kugo2p__SalesOrder__c IN :orderIds
      ]
    );
    // FiveStarHelper.createKitMemberFulfillments(sopl);
  }

  @istest
  static void auto_release_order() {
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();
    System.debug('auto release order');
    System.debug(opps);
    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT
        Id,
        kugo2p__Opportunity__c,
        FinanceOverride__c,
        kugo2p__RecordStatus__c,
        kugo2p__BalanceDueAmount__c,
        Complaint_Order__c,
        kugo2p__TotalAmount__c,
        kugo2p__AppliedPaymentAmount__c,
        Released__c,
        Email_To_Send__c
      FROM kugo2p__SalesOrder__c
      WHERE Salesperson__c = 'Greg Thatcher'
      ];
      // WHERE kugo2p__Opportunity__c IN :ids

    System.debug(orders);

    orders[0].kugo2p__RecordStatus__c = 'Approved';
    orders[0].Complaint_Order__c = true;

    // FiveStarHelper.autoReleaseOrder(orders);
  }

  @istest
  static void release_order() {
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT
        Id,
        kugo2p__Opportunity__c,
        kugo2p__RecordStatus__c,
        kugo2p__BalanceDueAmount__c,
        Complaint_Order__c,
        kugo2p__TotalAmount__c,
        kugo2p__AppliedPaymentAmount__c,
        Released__c,
        Email_To_Send__c,
        FinanceOverride__c
      FROM kugo2p__SalesOrder__c
      WHERE Salesperson__c = 'Greg Thatcher'
    ];

    // FiveStarHelper.releaseOrder(orders[0]);
  }

  @istest
  static void auto_release_order_payment_profile() {
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT
        Id,
        kugo2p__Opportunity__c,
        kugo2p__RecordStatus__c,
        kugo2p__BalanceDueAmount__c,
        Complaint_Order__c,
        kugo2p__TotalAmount__c,
        kugo2p__AppliedPaymentAmount__c,
        Released__c,
        Email_To_Send__c,
        FinanceOverride__c
      FROM kugo2p__SalesOrder__c
      LIMIT 50
    ];

    Set<Id> orderIds = new Set<Id>();
    for (kugo2p__SalesOrder__c o : orders) {
      orderIds.add(o.Id);
    }

    Map<Id, kugo2p__Payment_Profile__c> oldProfileMap = new Map<Id, kugo2p__Payment_Profile__c>(
      [
        SELECT Id, kugo2p__SalesOrder__c, kugo2p__Subscription_Status__c
        FROM kugo2p__Payment_Profile__c
        WHERE kugo2p__SalesOrder__C IN :orderIds
      ]
    );
    System.debug(oldProfileMap.size());

    Map<Id, kugo2p__Payment_Profile__c> newProfileMap = new Map<Id, kugo2p__Payment_Profile__c>();
    for (kugo2p__Payment_Profile__c p : oldProfileMap.values()) {
      kugo2p__Payment_Profile__c pp = new kugo2p__Payment_Profile__c();
      pp.kugo2p__Subscription_Status__c = 'Active';
      pp.kugo2p__SalesOrder__c = p.kugo2p__SalesOrder__c;
      newProfileMap.put(p.Id, pp);
    }

    // FiveStarHelper.autoReleaseOrder(newProfileMap, oldProfileMap);
  }

  @istest
  static void reset_order_release_dates() {
    List<Opportunity> opps = [
      SELECT Id, Name
      FROM Opportunity
      WHERE Name = 'Test Opportunity'
    ];
    Set<Id> ids = new Set<Id>();

    for (Opportunity o : opps) {
      ids.add(o.Id);
    }

    List<kugo2p__SalesOrder__c> orders = [
      SELECT Id, kugo2p__Opportunity__c
      FROM kugo2p__SalesOrder__c
      WHERE kugo2p__Opportunity__c IN :ids
    ];

    for (kugo2p__SalesOrder__c so : orders) {
      so.kugo2p__RecordStatus__c = 'Released';
      so.Release_Date__c = System.today();
    }

    // FiveStarHelper.resetOrderReleaseDates(orders);
    // FiveStarHelper.resetOrderFinanceTerm(orders);
  }

  @istest
  static void delete_cloned_finance_order_acc() {
    List<kugo2P__SalesOrderAdditionalChargeCredit__c> orderACCs = [
      SELECT Id, kugo2p__AdditionalChargeCredit__c
      FROM kugo2P__SalesOrderAdditionalChargeCredit__c
      LIMIT 10
    ];
    // FiveStarHelper.deleteClonedFinanceOrderACC(orderACCs);
  }

  @istest
  static void create_kit_member_line_recipients() {
    List<LineRecipient__c> lrs = [
      SELECT Id, OrderProductLine__c, Primary__c, Recipient__c
      FROM LineRecipient__c
      WHERE Primary__c != NULL
      LIMIT 200
    ];

    // FiveStarHelper.createKitMemberLineRecipients(lrs);
  }

  @istest
  static void before_update() {
    List<kugo2p__SalesOrder__c> sos = new List<kugo2p__SalesOrder__c>();

    kugo2p__SalesOrder__c so = new kugo2p__SalesOrder__c();
    so.FinanceOverride__c = true;
    so.kugo2p__RecordStatus__c = 'Approved';
    sos.add(so);

    // FiveStarHelper.beforeUpdate(sos, sos);
    // FiveStarHelper.orderNeedsToBeReleased(so);

    List<kugo2p__SalesOrder__c> so1 = [
      SELECT
        Id,
        Name,
        kugo2p__Account__c,
        kugo2p__Carrier__c,
        kugo2p__ContactBilling__c,
        kugo2p__ContactBuying__c,
        kugo2p__ContactShipping__c,
        kugo2p__InvoiceSchedule__c,
        kugo2p__Opportunity__c,
        kugo2p__SalesQuote__c,
        kugo2p__Warehouse__c
      FROM kugo2p__SalesOrder__c
      WHERE kugo2p__OrderName__c = 'Test Opportunity'
      LIMIT 1
    ];

    Savepoint sp = Database.setSavepoint();
    try {
      update so1;
    } catch (Exception e) {
    }
    // kugo2p__SalesOrder__c so2 = so1.clone(false, true);
    // try {
    //   insert so2;
    //   // update so2;
    //   delete so2;
    // } catch (Exception e) {
    // }
    Database.rollback(sp);
  }

  @istest
  static void calling_all_the_queries() {
    Set<Id> ids = new Set<Id>{ UserInfo.getUserId() };
    // FiveStarHelper.aggregateLineReceipients(ids);
    // FiveStarHelper.aggregatePaymentProfile(ids);
    // FiveStarHelper.querySalesOrderForAutoRelease(ids);
    // FiveStarHelper.querySalesOrderProductLines(ids);
    FiveStarHelper.fulfillOrdersLineRecipient(ids);

    List<Account> accounts = [SELECT Id FROM Account LIMIT 1];

    // FiveStarHelper.nullCheckList(accounts);
  }
}