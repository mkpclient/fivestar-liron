trigger KitBundleTrigger on Kit_Bundle_Member__c (after insert) {
  if(Trigger.isAfter && Trigger.isInsert) {
    KitBundleHelper.afterInsert(Trigger.New);
  }
}