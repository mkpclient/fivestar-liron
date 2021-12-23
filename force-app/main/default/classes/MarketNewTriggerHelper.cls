public with sharing class MarketNewTriggerHelper {
  // Trigger to add pricebook to each market record when they're updated or inserted for simpler record access
  public static void afterInsert(Map<Id, Market__c> newMap) {
    Map<Id, String> pbNameMap = new Map<Id, String>();
    for (Id key : newMap.keySet()) {
      Market__c market = newMap.get(key);
      if (market.Price_Book__c == null) {
        pbNameMap.put(key, market.Name);
      }
    }
    findPriceBook(pbNameMap);
  }

  public static void afterUpdate(
    Map<Id, Market__c> oldMap,
    Map<Id, Market__c> newMap
  ) {
    Map<Id, String> pbNameMap = new Map<Id, String>();
    for (Id key : newMap.keySet()) {
      Market__c oldMarket = oldMap.get(key);
      Market__c newMarket = newMap.get(key);
      if (
        newMarket.Price_Book__c == null ||
        (oldMarket.Name != newMarket.Name &&
        newMarket.Price_Book_Name__c != newMarket.Name)
      ) {
        pbNameMap.put(key, newMarket.Name);
      }
    }
    findPriceBook(pbNameMap);
  }

  public static void findPriceBook(Map<Id, String> pbNameMap) {
    Map<String, Id> pbMap = new Map<String, Id>();
    for (PriceBook2 pb : [
      SELECT Id, Name
      FROM Pricebook2
      WHERE Name IN :pbNameMap.values()
    ]) {
        pbMap.put(pb.Name, pb.Id);
    }

    List<Market__c> updatedMarkets = new List<Market__c>();
    for(Id key : pbNameMap.keySet()){
        Id pbId = pbMap.get(pbNameMap.get(key));
        updatedMarkets.add(new Market__c(Id=key, Price_Book__c=pbId));
    }

    try{
        Database.update(updatedMarkets);
    } catch(DmlException err) {
        System.debug('Market pricebook update error :');
        System.debug(err.getMessage());
    }
  }
}