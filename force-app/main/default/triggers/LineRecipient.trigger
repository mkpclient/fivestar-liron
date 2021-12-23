trigger LineRecipient on LineRecipient__c (before insert, after insert, after delete, after undelete) {

	if (trigger.isBefore && trigger.isInsert) FiveStarHelper.assignLineRecipientAccountManager(trigger.new);

	if (trigger.isAfter && trigger.isInsert) FiveStarHelper.createKitMemberLineRecipients(trigger.new);

	if (trigger.isAfter && (trigger.isInsert || trigger.isDelete || trigger.isUndelete) ) FiveStarHelper.updateLineRecipientCount(trigger.new == null ? trigger.old : trigger.new);
}