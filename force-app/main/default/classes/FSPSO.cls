public with sharing class FSPSO {
  public kugo2p__SalesOrder__c Order { get; set; }
  public list<kugo2p__SalesOrderProductLine__c> OrderedProducts { get; set; }
  public list<kugo2p__SalesOrderAdditionalChargeCredit__c> AdditionalChargeCredited {
    get;
    set;
  }
  //public list<kugo2p__PaymentX__c> OrderPayments { get; set; }
  public kugo2p__SalesOrder__c getSalesOrder() {
    return [
      SELECT
        id,
        memo__c,
        name,
        kugo2p__ContactBuying__c,
        kugo2p__ShipToName__c,
        kugo2p__ShipToStreetLong__c,
        kugo2p__ShipToCity__c,
        kugo2p__ShipToStateProvince__c,
        kugo2p__ShipToZipPostalCode__c,
        Shipping_Phone__c,
        kugo2p__BillToName__c,
        kugo2p__BillToCountry__c,
        Shipping_Type__c,
        kugo2p__ShipToCountry__c,
        kugo2p__SalesOrder__c.kugo2p__ContactBilling__r.name,
        kugo2p__SalesOrder__c.kugo2p__ContactShipping__r.name,
        kugo2p__SalesOrder__c.kugo2p__ContactBuying__r.ACDF_Branch_Office__c,
        released__c,
        billing_email__c,
        kugo2p__billToStreetLong__c,
        kugo2p__billToCity__c,
        kugo2p__billToStateProvince__c,
        kugo2p__billToZipPostalCode__c,
        kugo2p__ProductAmount__c,
        kugo2p__BalanceDueAmount__c,
        kugo2p__AppliedPaymentAmount__c,
        kugo2p__AdditionalChargeCreditAmount__c,
        kugo2p__NetAmount__c,
        kugo2p__SalesOrder__c.kugo2p__Opportunity__r.account_manager_name__c,
        kugo2p__SalesOrder__c.kugo2p__Opportunity__r.account_manager_email__c,
        kugo2p__SalesOrder__c.kugo2p__Opportunity__r.FSP_Sales_Rep__r.phone,
        kugo2p__SalesOrder__c.Market__r.Market_Upload_Date__c,
        kugo2p__TotalTaxAmount__c,
        kugo2p__ContactBuying__r.Name
      FROM kugo2p__SalesOrder__c
      WHERE id = :ApexPages.currentPage().getParameters().get('id')
    ];
  }

  public List<kugo2p__SalesOrderProductLine__c> getOrderProducts() {
    OrderedProducts = [
      SELECT
        id,
        kugo2p__DiscountSalesPrice__c,
        Product_Name__c,
        kugo2p__Quantity__c,
        kugo2p__ListPrice__c,
        kugo2p__SalesPrice__c,
        Actual_Price__c,
        kugo2p__Product__c
      FROM kugo2p__SalesOrderProductLine__c
      WHERE
        kugo2p__SalesOrder__c = :ApexPages.currentPage()
          .getParameters()
          .get('id')
    ];

    /* MK changes for pulling in additional product information */
    Set<String> additionalIds = new Set<String>();
    for (kugo2p__SalesOrderProductLine__c p : OrderedProducts) {
      additionalIds.add(p.kugo2p__Product__c);
    }


    Map<Id, kugo2p__AdditionalProductDetail__c> productDetailMap = new Map<Id, kugo2p__AdditionalProductDetail__c>([
      SELECT
        Id,
        kugo2p__ReferenceProduct__c,
        kugo2p__ReferenceProduct__r.Name,
        kugo2p__ReferenceProduct__r.Product_Display_Name__c
      FROM kugo2p__AdditionalProductDetail__c
      WHERE
        Id IN :additionalIds
    ]);


    System.debug('PRODUCT DETAIL MAP');
    System.debug(productDetailMap);

    // because we dont want to create a full new map to have this custom returned object, we will store the name in the already existing product display name on the order product line
    for (kugo2p__SalesOrderProductLine__c so : OrderedProducts) {
      if (productDetailMap.containsKey(so.kugo2p__Product__c)) {
        System.debug('CONTAINS THE ID');
        System.debug(JSON.serializepretty(productDetailMap.get(so.kugo2p__Product__c)));
        so.Display_Name_For_Invoice__c =
          productDetailMap.get(so.kugo2p__Product__c).kugo2p__ReferenceProduct__r.Product_Display_Name__c != null ?
          productDetailMap.get(so.kugo2p__Product__c).kugo2p__ReferenceProduct__r.Product_Display_Name__c :
          productDetailMap.get(so.kugo2p__Product__c).kugo2p__ReferenceProduct__r.Name;
      }
    }
    return OrderedProducts;
  }
  public decimal getTotalProducts() {
    decimal total = 0;
    /*AggregateResult[] res = [select sum(kugo2p__DiscountSalesPrice__c) total from kugo2p__SalesOrderProductLine__c 
                                  where kugo2p__SalesOrder__c = :ApexPages.currentPage().getParameters().get('id')];
        
        system.debug('res'+res);
        for(AggregateResult rt: res)
        {
           total += (decimal)(rt.get('total')== null?0:rt.get('total'));
        }*/

    List<kugo2p__SalesOrderProductLine__c> lstOrderedProducts = [
      SELECT id, Actual_Price__c
      FROM kugo2p__SalesOrderProductLine__c
      WHERE
        kugo2p__SalesOrder__c = :ApexPages.currentPage()
          .getParameters()
          .get('id')
    ];
    for (kugo2p__SalesOrderProductLine__c o : lstOrderedProducts) {
      total = total + o.Actual_Price__c;
    }

    /*string strTotal = (string)total.format();
        string[] part = strTotal.split('.');
        if(part)
        system.debug('total'+s);*/
    return total;
  }
  public List<kugo2p__SalesOrderAdditionalChargeCredit__c> getAdditionalCharges() {
    AdditionalChargeCredited = [
      SELECT
        id,
        kugo2p__LineDescription__c,
        kugo2p__SalesPrice__c,
        kugo2p__AdditionalChargeCredit__c,
        kugo2p__AdditionalChargeCredit__r.Name,
        kugo2p__Quantity__c
      FROM kugo2p__SalesOrderAdditionalChargeCredit__c
      WHERE
        kugo2p__SalesOrder__c = :ApexPages.currentPage()
          .getParameters()
          .get('id')
    ];
    System.debug('additionalchargecredit====== ' + AdditionalChargeCredited);

    // if(AdditionalChargeCredited.size()<=1)
    if (AdditionalChargeCredited.size() > 0)
      //     AdditionalChargeCredited = null;//.clear();
      system.debug('AdditionalChargeCredited' + AdditionalChargeCredited);
    return AdditionalChargeCredited;
  }

  public list<kugo2p__PaymentX__c> getOrderPayments() {
    kugo2p__SalesOrder__c SalesOrder = [
      SELECT
        id,
        name,
        (
          SELECT
            id,
            name,
            kugo2p__Amount__c,
            kugo2p__Card_Type__c,
            kugo2p__Last_4_Digits__c,
            kugo2p__Date__c,
            kugo2p__Status__c,
            kugo2p__Contact__c,
            kugo2p__Contact__r.Name
          FROM kugo2p__Payments__r
          ORDER BY kugo2p__Date__c
        )
      FROM kugo2p__SalesOrder__c
      WHERE id = :ApexPages.currentPage().getParameters().get('id')
    ];

    list<kugo2p__PaymentX__c> OrderPayments = SalesOrder.kugo2p__Payments__r;
    // OrderPayments.sort();
    return OrderPayments;
  }

  // get recipients
  public String getFulfillments() {
    List<Fulfillment__c> fulfillments = [
      SELECT Id, Name, PrimaryRecipient__r.Name
      FROM Fulfillment__c
      WHERE OrderNumber__c = :ApexPages.currentPage().getParameters().get('id')
    ];

    String recipients = '';
    Set<String> uniques = new Set<String>();
    for ( Fulfillment__c f : fulfillments ) {
      uniques.add(f.PrimaryRecipient__r.Name);
    }

    for (String s : uniques) {
      recipients += s + ', ';
    }

    return recipients.substringBeforeLast(',');
  }

  public Boolean getMemo() {
    System.debug('get memo');
    System.debug(this.order.Memo__c);
    return this.order.Memo__c != null;
  }
}