global class ProductUpdateBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
  public String queryString;

  public ProductUpdateBatch() {
    if (String.isBlank(queryString)) {
      if (Test.isRunningTest()) {
        queryString = 'SELECT kugo2p__ReferenceProduct__c FROM kugo2p__AdditionalProductDetail__c WHERE kugo2p__ReferenceProduct__r.Name = \'Test Product 1\' LIMIT 1';
      } else {
        queryString = 'SELECT kugo2p__TaxableSales__c, kugo2p__ReferenceProduct__c, kugo2p__TaxableUsage__c, kugo2p__TaxableVAT__c FROM kugo2p__AdditionalProductDetail__c WHERE kugo2p__ReferenceProduct__r.isActive = true AND kugo2p__ReferenceProduct__r.TaxableSale__c != true AND kugo2p__TaxableSales__c = true';
      }
    }
  }

  public Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(queryString);
  }

  public void execute(
    Database.BatchableContext info,
    List<kugo2p__AdditionalProductDetail__c> scope
  ) {
    List<Product2> newProds = new List<Product2>();
    for (kugo2p__AdditionalProductDetail__c s : scope) {
      newProds.add(
        new Product2(Id = s.kugo2p__ReferenceProduct__c, TaxableSale__c = true)
      );
    }
    update newProds;
  }

  public void finish(Database.BatchableContext info) {
  }
}