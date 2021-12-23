public without sharing class KitBundleHelper {
    public static void afterInsert(List<Kit_Bundle_Member__c> newList) {
        Set<Id> parentProductIds = new Set<Id>();
        for(Kit_Bundle_Member__c kbm : newList) {
            parentProductIds.add(kbm.ReferenceKitBundle__c);
        }

        updateParentProducts(parentProductIds);
    }

    public static void updateParentProducts(Set<Id> parentProductIds) {
        List<Product2> parentProducts = [SELECT Id, IsKitBundle__c FROM Product2 WHERE Id IN :parentProductIds];

        for(Product2 p : parentProducts) {
            p.IsKitBundle__c = true;
        }

        update parentProducts;
    }
}