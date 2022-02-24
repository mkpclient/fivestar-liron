/* --------------------------------------- */
/*   CustomInvoicePDFExt class by Kugamon  */
/*   Copyright: Kugamon LLC                */
/*   http://www.kugamon.com                */
/*   NO SUPPORT PROVIDED                   */
/*   DO NOT COPY, STEAL, SELL THIS CODE    */
/* --------------------------------------- */

public without sharing class CustomInvoicePDFExt {

    public kugo2p.InvoicePDFExt invoicePDFExt  {get; set;}

    public CustomInvoicePDFExt() {
        invoicePDFExt = new kugo2p.InvoicePDFExt();
    }
    
    // public CustomInvoicePDFExt(ApexPages.StandardController stdController) {
    //  invoicePDFExt = new kugo2p.InvoicePDFExt(stdController);
    // }
    
    // public CustomInvoicePDFExt(ApexPages.StandardSetController controller) {
    //  invoicePDFExt = new kugo2p.InvoicePDFExt(controller);
    // }

    //Set invoiceId from InvoicePDF component which is used in Sales Invoice VF Email Template page
    public Id invoiceIdValue {
        get;
        set {
            invoiceIdValue = value;
            invoicePDFExt.invoiceIdValue = invoiceIdValue;
        }
    }

    public kugo2p__KugamonInvoice__c Invoice {
        get { if(Invoice == null) Invoice = invoicePDFExt.Invoice; return Invoice;}
        private set;
    }

    public kugo2p__KugamonSetting__c settings {
        get { if(settings == null) settings = invoicePDFExt.settings; return settings;}
        private set;
    }

    public list<kugo2p.InvoicePDFExt.PDFInvoiceLine> InvoiceLines {
        get { if(InvoiceLines==null) InvoiceLines = invoicePDFExt.InvoiceLines; return InvoiceLines;}
        private set;
    }

    public list<kugo2p__KugamonInvoiceAdditionalChargeCredit__c> ACCLines {
        get { if(ACCLines==null) ACCLines=invoicePDFExt.Invoice.kugo2p__Invoice_Additional_Charges_Credits__r; return ACCLines;}
        private set;
    }

    public String downloadPDFURL {
        get {
            return URL.getSalesforceBaseUrl().toExternalForm() + '/apex/CustomInvoicePDF?id='+invoicePDFExt.Invoice.Id+'&p=1';
        }
    }

    public String getPaymentURL() {
        return invoicePDFExt.PaymentURL + '&retURL=' + downloadPDFURL; 
    }

    public String getAcceptAndPayOnline() {
        return invoicePDFExt.getAcceptAndPayOnline();

        // un-comment the following section if the customer needs customization to online payment page.         
        /*PageReference pr = Page.CustomOnlinePayment;

        pr.getParameters().put('invId', invoicePDFExt.Invoice.Id);
        if (ApexPages.currentPage().getParameters().containsKey('retURL')) pr.getParameters().put('retURL', ApexPages.currentPage().getParameters().get('retURL'));

        pr.setRedirect(true);
        return pr.getUrl();*/
    }

    public String orderName {get; set;}
    public list<LineRecipient__c> LineRecipients {
        get {
            if (LineRecipients == null) {

                kugo2p__OrderInvoiceRelationship__c oir = [Select kugo2p__SalesOrder__c, kugo2p__SalesOrder__r.Name from kugo2p__OrderInvoiceRelationship__c where kugo2p__Invoice__c = :invoicePDFExt.Invoice.Id];
                orderName = oir.kugo2p__SalesOrder__r.Name;

                LineRecipients = CustomOrderPDFExt.getLineRecipients(oir.kugo2p__SalesOrder__c);
            }

            return LineRecipients;
        }
        private set;
    }
}