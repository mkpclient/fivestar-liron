trigger SalesOrderProductLineTrigger on SalesOrderProductLine__c (before insert, after insert, before update, after update, before delete) {
  if((Trigger_Setting__mdt.getInstance('SalesOrderProductLine').Active__c == true && Trigger_Setting__mdt.getInstance('AllTriggers').Active__c == true) || Test.isRunningTest()) {
    if(Trigger.isBefore && Trigger.isInsert) {
      SalesOrderProductLineHelper.beforeInsert(Trigger.new);
    }
  
    if(Trigger.isAfter && Trigger.isInsert) {
      SalesOrderProductLineHelper.afterInsert(Trigger.newMap);
    }
  
    if(Trigger.isBefore && Trigger.isUpdate) {
      SalesOrderProductLineHelper.beforeUpdate(Trigger.old, Trigger.new);
    }
  
    if(Trigger.isAfter && Trigger.isUpdate) {
      SalesOrderProductLineHelper.afterUpdate(Trigger.old, Trigger.new);
    }
  
    if(Trigger.isBefore && Trigger.isDelete) {
      SalesOrderProductLineHelper.beforeDelete(Trigger.oldMap);
    }  
  }
}