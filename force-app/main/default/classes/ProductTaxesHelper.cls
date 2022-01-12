public without sharing class ProductTaxesHelper {
    public static void afterUpdate(Map<Id, Product2> oldMap, Map<Id, Product2> newMap) {
        List<Id> updatedProductTaxes = new List<Id>();
        for(Product2 np : newMap.values()) {
            Product2 op = oldMap.get(np.Id);

            if(np.TaxableSale__c != op.TaxableSale__c || np.TaxableExcise__c != op.TaxableExcise__c || np.TaxableUsage__c != op.TaxableUsage__c || np.TaxableVAT__c != op.TaxableVAT__c) {
                updatedProductTaxes.add(np.Id);
            }
        }

        if(updatedProductTaxes.size() > 0) { 
            updateProductLineTaxes(updatedProductTaxes);
        }
    }

    public static void updateProductLineTaxes(List<Id> prodIds) {
        List<SalesOrderProductLine__c> sopls = [SELECT Id, TaxAmount__c,Tax_Amount_Hidden__c FROM SalesOrderProductLine__c WHERE Product__c IN :prodIds];
        List<SalesOrderProductLine__c> soplsToUpdate = new List<SalesOrderProductLine__c>();

        for(SalesOrderProductLine__c sopl : sopls) {
            if(sopl.TaxAmount__c != sopl.Tax_Amount_Hidden__c) {
                sopl.Tax_Amount_Hidden__c = sopl.TaxAmount__c;
                soplsToUpdate.add(sopl);
            }
        }

        if(soplsToUpdate.size() > 0) {
            update soplsToUpdate;
        }
    }
    
}
