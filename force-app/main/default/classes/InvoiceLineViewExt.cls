public with sharing class InvoiceLineViewExt {

	private final kugo2p__KugamonInvoiceLine__c invLine;
	public list<LineRecipient__c> lineRecipients {get; set;}

	public InvoiceLineViewExt(ApexPages.StandardController stdCon) {
		invLine = (kugo2p__KugamonInvoiceLine__c) stdCon.getRecord();

		//if (invLine.kugo2p__SalesOrderProductLine__c != null || invLine.kugo2p__SalesOrderServiceLine__c != null) {
		lineRecipients = [select 	Id, Name, Order__r.Name, OrderLine__c, Primary__c, Recipient__r.Name, Fulfillment__r.Name
						from 	LineRecipient__c 
						where 	(OrderProductLine__c != null AND OrderProductLine__c = :invLine.kugo2p__SalesOrderProductLine__c) OR 
								(OrderServiceLine__c != null AND OrderServiceLine__c = :invLine.kugo2p__SalesOrderServiceLine__c)];
		//}
	}
}