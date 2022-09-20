trigger SalesOrderTrigger on SalesOrder__c(after update, before update, before delete) {
  if((Trigger_Setting__mdt.getInstance('AllTriggers').Active__c == true && Trigger_Setting__mdt.getInstance('SalesOrder').Active__c == true) || Test.isRunningTest()) {
    if (Trigger.isBefore && Trigger.isUpdate) {
      SalesOrderHelper.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
      SalesOrderHelper.afterUpdate(Trigger.new, Trigger.old);
    }
  
    if(Trigger.isBefore && Trigger.isDelete) {
      SalesOrderHelper.beforeDelete(Trigger.old);
    }
  
  }
}