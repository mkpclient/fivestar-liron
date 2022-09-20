trigger ContactTriggerForTaxes on Contact (after update) {
  if(Trigger.isAfter && Trigger.isUpdate) {
    ContactTriggerForTaxesHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }
}