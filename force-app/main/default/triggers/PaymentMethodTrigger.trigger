trigger PaymentMethodTrigger on Payment_Method__c (before insert, after insert, after update, after delete) {


  if((Trigger_Setting__mdt.getInstance('AllTriggers').Active__c == true && Trigger_Setting__mdt.getInstance('Payment_Method').Active__c == true) || Test.isRunningTest()) { 
    if(Trigger.isBefore) {
      if(Trigger.isInsert) {
        PaymentMethodTriggerHelper.beforeInsert(Trigger.new);
      }
    }
  
    if(Trigger.isAfter) {
      if(Trigger.isUpdate) {
        PaymentMethodTriggerHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
      }
      
      if (Trigger.isInsert) {
        PaymentMethodTriggerHelper.afterInsert(Trigger.new);
      }
  
      if(Trigger.isDelete) {
        PaymentMethodTriggerHelper.afterDelete(Trigger.old);
      }
    }
  }
}