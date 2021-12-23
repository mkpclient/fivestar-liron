trigger PaymentTrigger on kugo2p__PaymentX__c (before insert, after insert) {
  if (trigger.isAfter && trigger.isInsert) {
    System.debug('******');
    System.debug('******');
    System.debug('running the payment trigger');
    System.debug('******');
    System.debug('******');
         
    // PaymentHelper.afterInsert(trigger.new);

  }
}