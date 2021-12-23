public with sharing class ManageChargesCreditsController {
  @AuraEnabled
  public static String addNewOrderChargesCredits(List<Id> ccIds, Id soId) {
    List<AdditionalChargeCredit__c> selectedACCs = [
      SELECT
        Id,
        Name,
        DefaultQuantity__c,
        DefaultLineDescription__c,
        UnitPrice__c,
        MinimumQuantity__c
      FROM AdditionalChargeCredit__c
      WHERE Id IN :ccIds
    ];

    List<SalesOrderAdditionalChargeCredit__c> generatedSOACCs = new List<SalesOrderAdditionalChargeCredit__c>();

    for (AdditionalChargeCredit__c acc : selectedACCs) {
      SalesOrderAdditionalChargeCredit__c soacc = new SalesOrderAdditionalChargeCredit__c();
      soacc.Quantity__c = acc.DefaultQuantity__c != null
        ? acc.DefaultQuantity__c
        : (acc.MinimumQuantity__c != null ? acc.MinimumQuantity__c : 1);
      soacc.LineDescription__c = String.isEmpty(acc.DefaultLineDescription__c) ? '' : acc.DefaultLineDescription__c;
      soacc.SalesPrice__c = acc.UnitPrice__c != null ? (Decimal) acc.UnitPrice__c : 0;
      soacc.Date__c = Date.today();
      soacc.SalesOrder__c = soId;
      soacc.Additional_Charge_Credit__c = acc.Id;
      generatedSOACCs.add(soacc);
    }

    try {
      Database.insert(generatedSOACCs, false);

    List<SalesOrderAdditionalChargeCredit__c> results = [
      SELECT
        Id,
        Additional_Charge_Credit__r.Name,
        Quantity__c,
        SalesPrice__c,
        LineDescription__c,
        Date__c,
        Line_Total__c,
        Additional_Charge_Credit__r.LockLineDescription__c,
        Additional_Charge_Credit__r.LockQuantity__c,
        Additional_Charge_Credit__r.LockUnitPrice__c,
        Additional_Charge_Credit__r.MaximumQuantity__c,
        Additional_Charge_Credit__r.MinimumQuantity__c
      FROM SalesOrderAdditionalChargeCredit__c
      WHERE Id in :generatedSOACCs
    ];

    return JSON.serialize(results);
    } catch (DmlException err) {
      System.Debug(err.getMessage());
      Map<String, String> errMap = new Map<String, String>();
      errMap.put('Error', err.getMessage());
      return JSON.serialize(errMap);
    }
  }

    // @AuraEnabled(cacheable=true)
  // public static String generateChargesCredits() {
  //   List<AdditionalChargeCredit__c> chargesCredits = [
  //     SELECT Id, Name, Description__c, UnitPrice__c
  //     FROM AdditionalChargeCredit__c
  //     WHERE IsActive__c = TRUE
  //   ];

  //   for(AdditionalChargeCredit__c c : chargesCredits) {
  //     if(c.UnitPrice__c == null) {
  //       c.UnitPrice__c = 0;
  //     }
  //   }

  //   return JSON.serialize(chargesCredits);
  // }

  // @AuraEnabled(cacheable=true)
  // public static String generateOrderChargesCredits(Id recordId) {
  //   List<SalesOrderAdditionalChargeCredit__c> results = [
  //     SELECT
  //       Id,
  //       Additional_Charge_Credit__r.Name,
  //       Quantity__c,
  //       SalesPrice__c,
  //       LineDescription__c,
  //       Date__c,
  //       Line_Total__c,
  //       Additional_Charge_Credit__r.LockLineDescription__c,
  //       Additional_Charge_Credit__r.LockQuantity__c,
  //       Additional_Charge_Credit__r.LockUnitPrice__c,
  //       Additional_Charge_Credit__r.MaximumQuantity__c,
  //       Additional_Charge_Credit__r.MinimumQuantity__c,
  //       Additional_Charge_Credit__c
  //     FROM SalesOrderAdditionalChargeCredit__c
  //     WHERE SalesOrder__c = :recordId
  //   ];

  //   return JSON.serialize(results);
  // }

  // @AuraEnabled
  // public static String saveOrderAdditionalChargeCredit(List<SalesOrderAdditionalChargeCredit__c> records) {
  //   Map<String, List<Object>> returnMap = new Map<String, List<Object>>();
  //   try {
  //     Database.upsert(records);
  //     List<SalesOrderAdditionalChargeCredit__c> result = [
  //       SELECT
  //       Id,
  //       Additional_Charge_Credit__r.Name,
  //       Additional_Charge_Credit__c,
  //       Quantity__c,
  //       SalesPrice__c,
  //       LineDescription__c,
  //       Date__c,
  //       Line_Total__c,
  //       Additional_Charge_Credit__r.LockLineDescription__c,
  //       Additional_Charge_Credit__r.LockQuantity__c,
  //       Additional_Charge_Credit__r.LockUnitPrice__c,
  //       Additional_Charge_Credit__r.MaximumQuantity__c,
  //       Additional_Charge_Credit__r.MinimumQuantity__c
  //     FROM SalesOrderAdditionalChargeCredit__c
  //     WHERE Id IN :records
  //     ];
  //     returnMap.put('Data', result);
  //     return JSON.serialize(returnMap);
  //   } catch (DmlException err) {
  //     returnMap.put('Error', new List<Object>{err.getMessage()});
  //     return JSON.serialize(returnMap);
  //   }
  // }

  // @AuraEnabled
  // public static String deleteOrderChargesCredits(List<SalesOrderAdditionalChargeCredit__c> records) {
  //   Map<String, String> statusMap = new Map<String, String>();
  //   try {
  //     Database.delete(records);
  //     statusMap.put('Success', 'Delete success');
  //     return JSON.serialize(statusMap);
  //   } catch (DmlException err) {
  //     statusMap.put('Error', err.getMessage());
  //     return JSON.serialize(statusMap);
  //   }
  // } 

}