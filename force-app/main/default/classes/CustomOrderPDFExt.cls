/* --------------------------------------- */
/*   CustomOrderPDFExt class by Kugamon    */
/*   Copyright: Kugamon LLC                */
/*   http://www.kugamon.com                */
/*   NO SUPPORT PROVIDED                   */
/*   DO NOT COPY, STEAL, SELL THIS CODE    */
/* --------------------------------------- */

public without sharing class CustomOrderPDFExt {

	public String encodedSignature	{get; set;}
	public kugo2p.OrderPDFExt orderPDFExt  {get; set;}

	public CustomOrderPDFExt() {
		orderPDFExt = new kugo2p.OrderPDFExt();
	}

	public CustomOrderPDFExt(ApexPages.StandardController stdController) {
		orderPDFExt = new kugo2p.OrderPDFExt(stdController);
	}

    //Set orderId from OrderPDF component which is used in Sales Order VF Email Template page
    public Id orderIdValue {
        get;
        set {
            orderIdValue = value;
            orderPDFExt.orderIdValue = orderIdValue;
        }
    }

    public kugo2p__SalesOrder__c Order {
        get { if(Order == null) Order = orderPDFExt.Order; return Order;}
        private set;
    }

    public kugo2p__KugamonSetting__c settings {
        get { if(settings == null) settings = orderPDFExt.settings; return settings;}
        private set;
    }

    public list<kugo2p.OrderPDFExt.OrderLine> ProductLines {
    	get { if(ProductLines==null) ProductLines = orderPDFExt.ProductLines; return ProductLines;}
    	private set;
    }

    public list<kugo2p.OrderPDFExt.OrderLine> ServiceLines {
    	get { if(ServiceLines==null) ServiceLines = orderPDFExt.ServiceLines; return ServiceLines;}
    	private set;
    }

    public list<kugo2p__SalesOrderAdditionalChargeCredit__c> ACCLines {
    	get { if(ACCLines==null) ACCLines=orderPDFExt.ACCLines; return ACCLines;}
    	private set;
    }

    public String downloadPDFURL {
    	get {
			system.debug('\n ### toExternalForm ' + URL.getSalesforceBaseUrl().toExternalForm());
			system.debug('\n ### getHost ' + URL.getSalesforceBaseUrl().getHost());
   			return URL.getSalesforceBaseUrl().toExternalForm() + '/apex/CustomOrderPDF?id='+orderPDFExt.Order.Id+'&p=1';
    	}
    }

    public String getPaymentURL() {
        return orderPDFExt.PaymentURL + '&retURL=' + downloadPDFURL; 
    }

    public PageReference acceptAndPayOnline() {
		String orderRecordStatus = this.Order.kugo2p__RecordStatus__c;

    	PageReference pr = orderPDFExt.acceptAndPayOnline();

		// un-comment the following section if the customer needs customization to online payment page. 
    	/*if (pr != null) {
    		pr = Page.CustomOnlinePayment;
	        if(this.Order.kugo2p__BalanceDueAmount__c == 0 || orderPDFExt.settings.kugo2p__OnlinePaymentButton__c.equalsIgnoreCase('Accept & Approve') || this.Order.kugo2p__PaymentMethod__c=='Invoice') {
	            pr = Page.CustomOnlineConfirmation;
	        }
	        pr.getParameters().put('soId', Order.Id);
	        if (ApexPages.currentPage().getParameters().containsKey('retURL')) pr.getParameters().put('retURL', ApexPages.currentPage().getParameters().get('retURL'));
	        pr.setRedirect(true);
    	}*/

    	if (pr != null && (orderRecordStatus == 'Draft' || orderRecordStatus == 'Sent')) {
    		saveSignature();
    	}

    	return pr;
    }

    public PageReference checkout() {
		String orderRecordStatus = this.Order.kugo2p__RecordStatus__c;
    	PageReference pr = orderPDFExt.checkout();

    	if (pr != null && (orderRecordStatus == 'Draft' || orderRecordStatus == 'Sent')) {
    		saveSignature();
    	}

    	return pr;
    }

	private String signatureName {
		get {
			return	this.Order.Name + ' - Accepted Signature.png';
		}
	}

    private void saveSignature() {

        if (String.isNotBlank(encodedSignature)) {

            Attachment attach = new Attachment(Name = signatureName, Description = 'Accepted by ' + orderPDFExt.acceptedBy + ' from IP Address: ' + getIPAddress(),
            									Body = encodingUtil.base64Decode(encodedSignature), parentId = this.Order.Id, isPrivate = false);

            insert attach;
        }
    }

	public String SignatureUrl {
		get {
			if (SignatureUrl == null && order.kugo2p__ShipToStreet__c != null) {
				Id attachmentId;
				for (Attachment attach : [Select Id from Attachment where ParentId = :Order.Id and Name = :signatureName order by createdDate desc Limit 1]) {
					attachmentId = attach.Id;
				}

				SignatureUrl = attachmentId != null ? (order.kugo2p__ShipToStreet__c + '/servlet/servlet.FileDownload?file=' + attachmentId + '&oid='+UserInfo.getOrganizationId()) : '';
			}
			return SignatureUrl;
		}
		private set;
	}

    // Returns IP address of current user.
    private String getIPAddress() {
        return ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
    }

    public static list<LineRecipient__c> getLineRecipients(Id orderId) {
    	return orderId == null ? null : [Select Id, OrderLine__c, OrderProductLine__r.kugo2p__Product__r.Name, OrderServiceLine__r.kugo2p__Service__r.Name, Recipient__r.Name, Primary__c
								  		from 	 LineRecipient__c where Order__c = :orderId order by OrderProductLine__r.kugo2p__SortOrder__c NULLS Last, OrderServiceLine__r.kugo2p__SortOrder__c NULLS Last, Recipient__r.Name];
    }

    public list<LineRecipient__c> LineRecipients {
    	get {
    		if (LineRecipients == null) {
				//LineRecipients = getLineRecipients(orderPDFExt.orderIdValue);
				LineRecipients = getLineRecipients(Order.Id);
    		}

    		return LineRecipients;
    	}
    	private set;
    }

    public list<PaymentSchedule__c> PaymentSchedules {
    	get {
    		if (PaymentSchedules == null) {
				PaymentSchedules = [Select Id, DueDate__c, Amount__c from PaymentSchedule__c where OrderNumber__c = :orderPDFExt.orderIdValue order by DueDate__c];
    		}

    		return PaymentSchedules;
    	}
    	private set;
    }
}