trigger SalesOrderProductLine on kugo2p__SalesOrderProductLine__c (after insert, before delete) {

  //   if (trigger.isAfter && trigger.isInsert) {
  //   	FiveStarHelper.createKitMemberFulfillments(trigger.newMap);
  //   }

	// if (trigger.isBefore && trigger.isDelete) {
	// 	FiveStarHelper.deleteFulfillmentAndLineRecipients(trigger.oldMap.keySet());
	// }
}