trigger kuga_SalesOrderAdditionalChargeCredit on kugo2p__SalesOrderAdditionalChargeCredit__c (after insert) {
	
	if (trigger.isAfter && trigger.isInsert) {
		// FiveStarHelper.deleteClonedFinanceOrderACC(trigger.new);
	}
    
}