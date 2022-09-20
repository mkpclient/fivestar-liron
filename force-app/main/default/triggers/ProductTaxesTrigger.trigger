trigger ProductTaxesTrigger on Product2 (after update) {
  if(Trigger.isAfter && Trigger.isUpdate) {
    ProductTaxesHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }
 }