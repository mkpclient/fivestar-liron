public without sharing class DataMigration implements Queueable {
  static final Integer MAX_RECORDS = 50;
  static Map<String, Map<String, Schema.SObjectField>> objectFieldMap = new Map<String, Map<String, Schema.SObjectField>>();
  static Map<Id,Id> productOldNewIdMap;
  static Map<Id,Id> kitBundleOldNewIdMap;

  static {
    objectFieldMap.put('kugo2p__AdditionalAccountDetail__c', kugo2p__AdditionalAccountDetail__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Account', Account.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__AdditionalProductDetail__c', kugo2p__AdditionalProductDetail__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Product2', Product2.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__KitBundleMember__c', kugo2p__KitBundleMember__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Kit_Bundle_Member__c', Kit_Bundle_Member__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__AdditionalChargeCredit__c', kugo2p__AdditionalChargeCredit__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('AdditionalChargeCredit__c', AdditionalChargeCredit__c.getSobjectType().getDescribe().fields.getMap());

    objectFieldMap.put('kugo2p__SalesOrder__c', kugo2p__SalesOrder__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('SalesOrder__c', SalesOrder__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Fulfillment__c', Fulfillment__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Order_Fulfillment__c', Order_Fulfillment__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__SalesOrderProductLine__c', kugo2p__SalesOrderProductLine__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('SalesOrderProductLine__c', SalesOrderProductLine__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('LineRecipient__c', LineRecipient__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Order_Line_Recipient__c', Order_Line_Recipient__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__SalesOrderAdditionalChargeCredit__c', kugo2p__SalesOrderAdditionalChargeCredit__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('SalesOrderAdditionalChargeCredit__c', SalesOrderAdditionalChargeCredit__c.getSobjectType().getDescribe().fields.getMap());

    objectFieldMap.put('kugo2p__KugamonInvoice__c', kugo2p__KugamonInvoice__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Invoice__c', Invoice__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('InvoiceLine__c', InvoiceLine__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__KugamonInvoiceLine__c', kugo2p__KugamonInvoiceLine__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__KugamonInvoiceAdditionalChargeCredit__c', kugo2p__KugamonInvoiceAdditionalChargeCredit__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('InvoiceAdditionalChargeCredit__c', InvoiceAdditionalChargeCredit__c.getSobjectType().getDescribe().fields.getMap());
   
    objectFieldMap.put('kugo2p__AppliedPayment__c', kugo2p__AppliedPayment__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('AppliedPayment__c', AppliedPayment__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('kugo2p__PaymentX__c', kugo2p__PaymentX__c.getSobjectType().getDescribe().fields.getMap());
    objectFieldMap.put('Payment__c', Payment__c.getSobjectType().getDescribe().fields.getMap());
  }

  public List<kugo2p__AdditionalProductDetail__c> productDetailsToMigrate;
  public List<kugo2p__AdditionalChargeCredit__c> additionalChargeCreditsToMigrate; 
  public List<kugo2p__AdditionalAccountDetail__c> additionalAccountDetailsToMigrate;
  public List<kugo2p__SalesOrder__c> salesOrdersToMigrate;
  public List<kugo2p__SalesOrderAdditionalChargeCredit__c> salesOrderAdditionalChargeCreditsToMigrate;
  public List<kugo2p__SalesOrderProductLine__c> salesOrderProductLinesToMigrate;
  public List<LineRecipient__c> lineRecipientsToMigrate;
  public List<Fulfillment__c> fulfillmentsToMigrate;    
  public List<kugo2p__KugamonInvoice__c> invoicesToMigrate;
  public List<kugo2p__KugamonInvoiceLine__c> invoiceLinesToMigrate;
  public List<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> invoiceChargesToMigrate;
  public List<kugo2p__PaymentX__c> paymentsToMigrate;
  public List<kugo2p__AppliedPayment__c> appliedPaymentsToMigrate;
  public List<kugo2p__KitBundleMember__c> kitBundlesToMigrate;
  public DateTime queryOrdersCreatedBefore;

  public void execute(QueueableContext context) {
    migrateRecords();
  }

  public void migrateRecords(){
    if ( queryOrdersCreatedBefore != null ){
      migrateSalesOrders(queryOrdersCreatedBefore);      
    }
    else if ( productDetailsToMigrate != null && productDetailsToMigrate.size() > 0 ){
      migrateProducts(productDetailsToMigrate);
    } 
    else if ( additionalChargeCreditsToMigrate != null && additionalChargeCreditsToMigrate.size() > 0 ){
      migrateAdditionalChargeCredits(additionalChargeCreditsToMigrate);
      additionalChargeCreditsToMigrate = null;
    } 
    else if ( additionalAccountDetailsToMigrate != null && additionalAccountDetailsToMigrate.size() > 0 ){
      migrateAccounts(additionalAccountDetailsToMigrate);
      additionalAccountDetailsToMigrate = null;
    } 
    else if ( salesOrdersToMigrate != null && salesOrdersToMigrate.size() > 0 ){
      migrateSalesOrders(salesOrdersToMigrate);
    } 
    // else if ( lineRecipientsToMigrate != null && lineRecipientsToMigrate.size() > 0 ){
    //   migrateLineRecipients(lineRecipientsToMigrate);
    //   lineRecipientsToMigrate = null;
    // } 
    else if ( invoicesToMigrate != null && invoicesToMigrate.size() > 0 ){
      migrateInvoices(invoicesToMigrate);
    } 
    else if ( paymentsToMigrate != null && paymentsToMigrate.size() > 0 ){
      migratePayments(paymentsToMigrate);
      paymentsToMigrate = null;
    }
    else if ( appliedPaymentsToMigrate != null && appliedPaymentsToMigrate.size() > 0 ){
      migrateAppliedPayments(appliedPaymentsToMigrate);
      appliedPaymentsToMigrate = null;
    }
    requeue();
  }

  /**
   * @name requeue
   */
  public void requeue(){
    Boolean hasMoreRecords = false;
    DataMigration cls = new DataMigration();
    if ( queryOrdersCreatedBefore != null ){
      cls.queryOrdersCreatedBefore = queryOrdersCreatedBefore;
      hasMoreRecords = true;
    }
    else if ( productDetailsToMigrate != null && productDetailsToMigrate.size() > 0 ){
      cls.productDetailsToMigrate = productDetailsToMigrate;
      hasMoreRecords = true;
    } 
    else if ( additionalAccountDetailsToMigrate != null && additionalAccountDetailsToMigrate.size() > 0 ){
      cls.additionalAccountDetailsToMigrate = additionalAccountDetailsToMigrate;
      hasMoreRecords = true;
    } 
    else if ( salesOrdersToMigrate != null && salesOrdersToMigrate.size() > 0 ){
      cls.salesOrdersToMigrate = salesOrdersToMigrate;
      hasMoreRecords = true;
    } 
    else if ( lineRecipientsToMigrate != null && lineRecipientsToMigrate.size() > 0 ){
      cls.lineRecipientsToMigrate = lineRecipientsToMigrate;
      hasMoreRecords = true;
    } 
    else if ( invoicesToMigrate != null && invoicesToMigrate.size() > 0 ){
      cls.invoicesToMigrate = invoicesToMigrate;
      hasMoreRecords = true;
    } 
    else if ( appliedPaymentsToMigrate != null && appliedPaymentsToMigrate.size() > 0 ){
      cls.appliedPaymentsToMigrate = appliedPaymentsToMigrate;
      hasMoreRecords = true;
    }
    if ( hasMoreRecords ){
      System.enqueueJob(cls);
    }
  }

  /**
   * @name migrateProducts
   * @description One-Time Use Only
   */
  public static void updateExistingProduct2LegacyIds(){
    List<Product2> toUpdate = new List<Product2>();
    for ( kugo2p__AdditionalProductDetail__c d : [
      SELECT Id, kugo2p__ReferenceProduct__c
      FROM kugo2p__AdditionalProductDetail__c
      WHERE kugo2p__ReferenceProduct__c != null 
      AND kugo2p__ReferenceProduct__r.Legacy_Id__c = null
      LIMIT 50
    ]){
      Product2 p = new Product2();
      p.Id = d.kugo2p__ReferenceProduct__c;
      p.Legacy_Id__c = d.Id;
      toUpdate.add(p);
    }
    update toUpdate;
  }

  /**
   * @name migrateProducts
   * @description One-Time Use Only
   */
  public static void updateExistingKitBundleLegacyIds(){
    Map<String,Id> oldMap = new Map<String,Id>();
    for ( kugo2p__KitBundleMember__c o : [
      SELECT Id, kugo2p__ReferenceKitBundle__r.kugo2p__ReferenceProduct__c, kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__c
      FROM kugo2p__KitBundleMember__c
      WHERE kugo2p__ReferenceKitBundle__c != null 
      AND kugo2p__ReferenceMemberProductService__c != null
    ]){
      oldMap.put( o.kugo2p__ReferenceKitBundle__r.kugo2p__ReferenceProduct__c+'|'+ o.kugo2p__ReferenceMemberProductService__r.kugo2p__ReferenceProduct__c, o.Id);
    }
    List<Kit_Bundle_Member__c> toUpdate = new List<Kit_Bundle_Member__c>();
    for ( Kit_Bundle_Member__c k : [
      SELECT Id, ReferenceKitBundle__c, ReferenceMemberProduct__c
      FROM Kit_Bundle_Member__c
      WHERE ReferenceKitBundle__c != null
      AND ReferenceMemberProduct__c != null
    ]){
      k.Legacy_Id__c = oldMap.get(k.ReferenceKitBundle__c+'|'+k.ReferenceMemberProduct__c);
      toUpdate.add(k);
    }
    update toUpdate;
  }

  /**
   * @name migrateProducts
   */
  public void migrateProducts(List<kugo2p__AdditionalProductDetail__c> oldList){
    List<kugo2p__AdditionalProductDetail__c> toReQueue = new List<kugo2p__AdditionalProductDetail__c>();
    List<Product2> recordsToUpsert = new List<Product2>();
    for ( Integer i=0;i<oldList.size();i++ ){
      if ( i < MAX_RECORDS ){
        Product2 n = (Product2)toNewSobject(oldList[i], new Product2());
        n.Id = oldList[i].kugo2p__ReferenceProduct__c;
        n.Legacy_Id__c = oldList[i].Id;
        recordsToUpsert.add(n);
      } else {
        toReQueue.add(oldList[i]);
      }
    }
    database.upsert(recordsToUpsert);
    productDetailsToMigrate = toReQueue;
  }

  /**
   * @name migrateProducts
   */
  public static void migrateAdditionalChargeCredits(List<kugo2p__AdditionalChargeCredit__c> oldList){
    List<AdditionalChargeCredit__c> recordsToUpsert = new List<AdditionalChargeCredit__c>();
    for ( kugo2p__AdditionalChargeCredit__c o : oldList ){
      AdditionalChargeCredit__c n = (AdditionalChargeCredit__c)toNewSobject(o, new AdditionalChargeCredit__c());
      n.Legacy_Id__c = o.Id;
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, AdditionalChargeCredit__c.Legacy_Id__c);
  }

  /**
   * @name migrateAccounts
   */
  public static void migrateAccounts(List<kugo2p__AdditionalAccountDetail__c> oldList){
    List<Account> recordsToUpsert = new List<Account>();
    for ( kugo2p__AdditionalAccountDetail__c o : oldList ){
      Account n = (Account)toNewSobject(o, new Account());
      n.Id = o.kugo2p__Account__c;
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert);
  }

  /**
   * @name migrateFulfillments
   */
  public static void migrateFulfillments(Set<Id> recordIds){
    String queryString = 'SELECT '+String.join(compileAllFields('Fulfillment__c'),',');
    queryString += ' FROM Fulfillment__c WHERE OrderNumber__c IN :recordIds';
    List<Fulfillment__c> records = database.query(queryString);
    migrateFulfillments(records);
  }

  /**
   * @name migrateFulfillments
   */
  public static void migrateFulfillments(List<Fulfillment__c> oldList){
    List<Order_Fulfillment__c> recordsToUpsert = new List<Order_Fulfillment__c>();
    for ( Fulfillment__c o : oldList ){
      Order_Fulfillment__c n = (Order_Fulfillment__c)toNewSobject(o, new Order_Fulfillment__c());
      n.Legacy_Id__c = o.Id;
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, Order_Fulfillment__c.Legacy_Id__c);
  }

  /**
   * @name migrateInvoices
   */
  public static void migrateInvoices(List<kugo2p__KugamonInvoice__c> oldList){
    Set<Id> recordIds = new Set<Id>();
    Map<Id,Id> invoiceMap = new Map<Id,Id>();
    Map<Id,Id> salesOrderMap = new Map<Id,Id>();
    List<Invoice__c> recordsToUpsert = new List<Invoice__c>();
    for ( kugo2p__KugamonInvoice__c o : oldList ){
      recordIds.add(o.Id);
      Invoice__c n = (Invoice__c)toNewSobject(o, new Invoice__c());
      n.Legacy_Id__c = o.Id;
      salesOrderMap.put(n.SalesOrder__c, null);
      recordsToUpsert.add(n);
    }
    for ( SalesOrder__c s : [
      SELECT Id, Legacy_Id__c
      FROM SalesOrder__c
      WHERE Legacy_Id__c IN :salesOrderMap.keySet()
    ]){
      salesOrderMap.put(s.Legacy_Id__c,s.Id);
    }
    for ( Invoice__c n : recordsToUpsert ){
      n.SalesOrder__c = salesOrderMap.get(n.SalesOrder__c);
    }
    database.upsert(recordsToUpsert, Invoice__c.Legacy_Id__c);
    for ( Invoice__c n : recordsToUpsert ){
      invoiceMap.put(n.Legacy_Id__c,n.Id);
    }
    migrateInvoiceCharges(invoiceMap);
    migrateInvoiceLines(invoiceMap);
  }

  /**
   * @name migrateInvoiceCharges
   */
  public static void migrateInvoiceCharges(Map<Id,Id> oldNewInvoiceIdMap){
    Set<id> recordIds = oldNewInvoiceIdMap.keySet();
    String chargeQueryString = 'SELECT '+String.join(compileAllFields('kugo2p__KugamonInvoiceAdditionalChargeCredit__c'),',');
    chargeQueryString += ' FROM kugo2p__KugamonInvoiceAdditionalChargeCredit__c WHERE kugo2p__Invoice__c IN :recordIds';
    List<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> records = database.query(chargeQueryString);
    migrateInvoiceCharges(records, oldNewInvoiceIdMap);
  }

  /**
   * @name migrateInvoiceCharges
   */
  public static void migrateInvoiceCharges(List<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> oldList, Map<Id,Id> invoiceMap){
    List<InvoiceAdditionalChargeCredit__c> recordsToUpsert = new List<InvoiceAdditionalChargeCredit__c>();
    for ( kugo2p__KugamonInvoiceAdditionalChargeCredit__c o : oldList ){
      InvoiceAdditionalChargeCredit__c n = (InvoiceAdditionalChargeCredit__c)toNewSobject(o, new InvoiceAdditionalChargeCredit__c());
      n.Legacy_Id__c = o.Id;
      n.Invoice__c = invoiceMap.get(n.Invoice__c);
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, InvoiceAdditionalChargeCredit__c.Legacy_Id__c);
  }

  /**
   * @name migrateInvoiceLines
   */
  public static void migrateInvoiceLines(Map<Id,Id> oldNewInvoiceIdMap){
    Set<id> recordIds = oldNewInvoiceIdMap.keySet();
    String lineQueryString = 'SELECT '+String.join(compileAllFields('kugo2p__KugamonInvoiceLine__c'),',');
    lineQueryString += ' FROM kugo2p__KugamonInvoiceLine__c WHERE kugo2p__Invoice__c IN :recordIds';
    List<kugo2p__KugamonInvoiceLine__c> records = database.query(lineQueryString);
    migrateInvoiceLines(records, oldNewInvoiceIdMap);
  }

  /**
   * @name migrateInvoiceLines
   */
  public static void migrateInvoiceLines(List<kugo2p__KugamonInvoiceLine__c> oldList, Map<Id,Id> invoiceMap){
    List<InvoiceLine__c> recordsToUpsert = new List<InvoiceLine__c>();
    for ( kugo2p__KugamonInvoiceLine__c o : oldList ){
      InvoiceLine__c n = (InvoiceLine__c)toNewSobject(o, new InvoiceLine__c());
      n.Legacy_Id__c = o.Id;
      n.Invoice__c = invoiceMap.get(n.Invoice__c);
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, InvoiceLine__c.Legacy_Id__c);
  }

  /**
   * @name migrateKitBundles
   */
  public static void migrateKitBundles(List<kugo2p__KitBundleMember__c> oldList){
    List<Kit_Bundle_Member__c> recordsToUpsert = new List<Kit_Bundle_Member__c>();
    Map<Id,Id> productMap = compileProductIdMap();
    for ( kugo2p__KitBundleMember__c o : oldList ){
      Kit_Bundle_Member__c n = (Kit_Bundle_Member__c)toNewSobject(o, new Kit_Bundle_Member__c());
      n.Legacy_Id__c = o.Id;
      n.ReferenceKitBundle__c = productMap.get(n.ReferenceKitBundle__c);
      n.ReferenceMemberProduct__c = productMap.get(n.ReferenceMemberProduct__c);
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, Kit_Bundle_Member__c.Legacy_Id__c);
  }

  /**
   * @name migrateSalesOrders
   */
  public void migrateSalesOrders(DateTime dt){
    List<String> fields = DataMigration.compileAllFields('kugo2p__SalesOrder__c');
    String queryString = 'SELECT '+String.join(fields,',')+' FROM kugo2p__SalesOrder__c';
    queryString += ' WHERE CreatedDate <= :dt';
    queryString += ' ORDER BY CreatedDate desc LIMIT '+MAX_RECORDS;
    List<kugo2p__SalesOrder__c> orders = database.query(queryString);
    if ( orders.size() > 0 ){
      queryOrdersCreatedBefore = orders[orders.size()-1].CreatedDate;
      migrateSalesOrders(orders);
    } else {
      queryOrdersCreatedBefore = null;      
    }
  }

  /**
   * @name migrateSalesOrders
   */
  public void migrateSalesOrders(List<kugo2p__SalesOrder__c> oldList){
    List<kugo2p__SalesOrder__c> toReQueue = new List<kugo2p__SalesOrder__c>();
    Set<Id> recordIds = new Set<Id>();
    List<SalesOrder__c> recordsToUpsert = new List<SalesOrder__c>();
    for ( Integer i=0; i<oldList.size(); i++ ){
      if ( i < MAX_RECORDS ){
        recordIds.add(oldList[i].Id);
        SalesOrder__c n = (SalesOrder__c)toNewSobject(oldList[i], new SalesOrder__c());
        n.Legacy_Id__c = oldList[i].Id;
        recordsToUpsert.add(n);
      } else {
        toReQueue.add(oldList[i]);
      }
    }
    database.upsert(recordsToUpsert, SalesOrder__c.Legacy_Id__c);
    migrateOrderAdditionalChargeCredits(recordIds);
    migrateOrderProductLines(recordIds);
    migrateLineRecipients(recordIds);
    migrateFulfillments(recordIds);
    salesOrdersToMigrate = toReQueue;
  }

  public static void migrateOrderAdditionalChargeCredits(Set<Id> recordIds){
    String queryString = 'SELECT '+String.join(compileAllFields('kugo2p__SalesOrderAdditionalChargeCredit__c'),',');
    queryString += ' FROM kugo2p__SalesOrderAdditionalChargeCredit__c WHERE kugo2p__SalesOrder__c IN :recordIds';
    List<kugo2p__SalesOrderAdditionalChargeCredit__c> additionalCharges = database.query(queryString);
    migrateOrderAdditionalChargeCredits(additionalCharges);
  }

  public static void migrateOrderAdditionalChargeCredits(List<kugo2p__SalesOrderAdditionalChargeCredit__c> oldList){
    List<SalesOrderAdditionalChargeCredit__c> recordsToUpsert = new List<SalesOrderAdditionalChargeCredit__c>();
    for ( kugo2p__SalesOrderAdditionalChargeCredit__c o : oldList ){
      SalesOrderAdditionalChargeCredit__c n = (SalesOrderAdditionalChargeCredit__c)toNewSobject(o, new SalesOrderAdditionalChargeCredit__c());
      n.Legacy_Id__c = o.Id;
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, SalesOrderAdditionalChargeCredit__c.Legacy_Id__c);
  }

  public static void migrateOrderProductLines(Set<Id> recordIds){
    String queryString = 'SELECT '+String.join(compileAllFields('kugo2p__SalesOrderProductLine__c'),',');
    queryString += ' FROM kugo2p__SalesOrderProductLine__c WHERE kugo2p__SalesOrder__c IN :recordIds';
    List<kugo2p__SalesOrderProductLine__c> productLines = database.query(queryString);
    migrateOrderProductLines(productLines);
  }

  public static void migrateOrderProductLines(List<kugo2p__SalesOrderProductLine__c> oldList){
    Map<Id,Id> kitBundleMap = compileKitBundledMap();
    List<SalesOrderProductLine__c> recordsToUpsert = new List<SalesOrderProductLine__c>();
    for ( kugo2p__SalesOrderProductLine__c o : oldList ){
      SalesOrderProductLine__c n = (SalesOrderProductLine__c)toNewSobject(o, new SalesOrderProductLine__c());
      n.Legacy_Id__c = o.Id;
//      n.Product__c = productMap.get(n.Product__c);
      n.KitBundleLine__c = kitBundleMap.get(n.KitBundleLine__c);
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, SalesOrderProductLine__c.Legacy_Id__c);
  }

  /**
   * @name migrateLineRecipients
   */
  public static void migrateLineRecipients(Set<Id> recordIds){
    String lineRecipientQueryString = 'SELECT '+String.join(compileAllFields('LineRecipient__c'),',');
    lineRecipientQueryString += ' FROM LineRecipient__c WHERE Order__c IN :recordIds';
    List<LineRecipient__c> records = database.query(lineRecipientQueryString);
    migrateLineRecipients(records);
  }

  /**
   * @name migrateLineRecipients
   */
  public static void migrateLineRecipients(List<LineRecipient__c> oldList){    
    List<Order_Line_Recipient__c> recordsToUpsert = new List<Order_Line_Recipient__c>();
    for ( LineRecipient__c o : oldList ){
      Order_Line_Recipient__c n = (Order_Line_Recipient__c)toNewSobject(o, new Order_Line_Recipient__c());
      n.Legacy_Id__c = o.Id;
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, Order_Line_Recipient__c.Legacy_Id__c);
  }
  
  /**
   * @name migratePayments
   */
  public static void migratePayments(List<kugo2p__PaymentX__c> oldList){
    List<Payment__c> recordsToUpsert = new List<Payment__c>();
    for ( kugo2p__PaymentX__c o : oldList ){
      Payment__c n = new Payment__c();
      toNewSobject(o, n);
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, Payment__c.Legacy_Id__c);
  }

  /**
   * @name migrateAppliedPayments
   */
  public static void migrateAppliedPayments(List<kugo2p__AppliedPayment__c> oldList){
    List<AppliedPayment__c> recordsToUpsert = new List<AppliedPayment__c>();
    for ( kugo2p__AppliedPayment__c o : oldList ){
      AppliedPayment__c n = new AppliedPayment__c();
      toNewSobject(o, n);
      recordsToUpsert.add(n);
    }
    database.upsert(recordsToUpsert, AppliedPayment__c.Legacy_Id__c);
  }

  /**
   * @name toNewSobject
   */
  public static sObject toNewSobject(sObject o, sObject n ){
    Map<String,Schema.SObjectField> oldFieldMap = objectFieldMap.get(''+o.getSObjectType());
    Map<String,Schema.SObjectField> newFieldMap = objectFieldMap.get(''+n.getSObjectType());
    for ( String fieldName : oldFieldMap.keySet() ){
      Schema.DescribeFieldResult oldDescribe = oldFieldMap.get(fieldName).getDescribe();
      Schema.DescribeFieldResult describe;
      if ( oldDescribe.isAccessible() && !oldDescribe.isCalculated() && o.get(fieldName) != null ){
        String newFieldName = fieldName.startsWith('kugo2p__') ? fieldName.substringAfter('kugo2p__') : fieldName;
        if ( newFieldName == 'ReferenceMemberProductService__c' ){
          newFieldName = 'ReferenceMemberProduct__c';
        }
        // system.debug(newFieldName);
        if ( newFieldMap.containsKey(newFieldName) ){
          describe = newFieldMap.get(newFieldName).getDescribe();
        }
        if ( describe != null && describe.isAccessible() && describe.isCreateable() ){
          if ( newFieldName.toLowerCase() == 'parentproductline__c' ){

          }
          else if (newFieldName.toLowerCase() == 'invoice__c'){
            n.putSobject('Invoice__r', new Invoice__c(Legacy_Id__c=(String)o.get(fieldName)) );
          }
          else if (newFieldName.toLowerCase() == 'invoiceline__c'){
            n.putSobject('InvoiceLine__r', new InvoiceLine__c(Legacy_Id__c=(String)o.get(fieldName)) );
          }
          else if ( newFieldName.toLowerCase() == 'payment__c' ){
            n.putSobject('Payment__r', new Payment__c(Legacy_Id__c=(String)o.get(fieldName)) );
          }
          else if (newFieldName.toLowerCase() == 'product__c'){
            n.putSobject('Product__r', new Product2(Legacy_Id__c=(String)o.get(fieldName)) );
          }
          else if (newFieldName.toLowerCase() == 'order__c'){
            n.putSobject('Order__r', new SalesOrder__c(Legacy_Id__c=(String)o.get(fieldName)) );
          }
          else if (newFieldName.toLowerCase() == 'ordernumber__c'){
            n.putSobject('OrderNumber__r', new SalesOrder__c(Legacy_Id__c=(String)o.get(fieldName)) );
          }          
          else if (newFieldName.toLowerCase() == 'orderproductline__c'){
            n.putSobject('OrderProductLine__r', new SalesOrderProductLine__c(Legacy_Id__c=(String)o.get(fieldName)) );
          }
          else if (newFieldName.toLowerCase() == 'salesorder__c'){
            n.putSobject('SalesOrder__r', new SalesOrder__c(Legacy_Id__c=(String)o.get(fieldName)) );
          }
          else if (newFieldName.toLowerCase() == 'sales_order__c'){
            n.putSobject('Sales_Order__r', new SalesOrder__c(Legacy_Id__c=(String)o.get(fieldName)) );
          } else {
            n.put(newFieldName, o.get(fieldName));
          }
        }
      }
    }
    return n;
  }

  public static List<String> compileAllFields(String sobjectName){
    List<String> fields = new List<String>();
    Map<String,Schema.SObjectField> fieldMap = objectFieldMap.get(sobjectName);
    for ( String fieldName : fieldMap.keySet() ){
      Schema.DescribeFieldResult describe = fieldMap.get(fieldName).getDescribe();
      if( describe.isAccessible() && !describe.isCalculated() ){
        fields.add(fieldName);
      }
    }
    return fields;
  }

  public static Map<Id,Id> compileProductIdMap(){
    if ( productOldNewIdMap == null ){
      productOldNewIdMap = new Map<Id,Id>();
      for ( Product2 p : [
        SELECT Id, Legacy_Id__c
        FROM Product2
        WHERE Legacy_Id__c != null
      ]){
        productOldNewIdMap.put(p.Legacy_Id__c, p.Id);
      }
    }
    return productOldNewIdMap;
  }

  /**
   * @name compileKitBundledMap
   */
  public static Map<Id,Id> compileKitBundledMap(){
    Map<Id,Id> oldNewIdMap = new Map<Id,Id>();
    for ( Kit_Bundle_Member__c p : [
      SELECT Id, Legacy_Id__c
      FROM Kit_Bundle_Member__c
      WHERE Legacy_Id__c != null
    ]){
      oldNewIdMap.put(p.Legacy_Id__c, p.Id);
    }
    return oldNewIdMap;
  }

}