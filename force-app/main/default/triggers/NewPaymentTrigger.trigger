trigger NewPaymentTrigger on Payment__c (before insert, after insert, before update, after update, before delete) {
  if(Trigger.isBefore && Trigger.isInsert) {
    NewPaymentTriggerHelper.beforeInsert(Trigger.new);
  }

  if(Trigger.isAfter && Trigger.isInsert) {
    NewPaymentTriggerHelper.afterInsert(Trigger.new);
  }

  if(Trigger.isBefore && Trigger.isUpdate) {
    NewPaymentTriggerHelper.beforeUpdate(Trigger.old, Trigger.new);
  }

  if(Trigger.isAfter && Trigger.isUpdate) {
    NewPaymentTriggerHelper.afterUpdate(Trigger.old, Trigger.new);
  }

  // if(Trigger.isBefore && Trigger.isDelete) {
  //   NewPaymentTriggerHelper.beforeDelete(Trigger.old);
  // }
}