/* --------------------------------------- */
/*   CustomKontroller class by Kugamon     */
/*   Copyright: Kugamon LLC                */
/*   http://www.kugamon.com                */
/*   NO SUPPORT PROVIDED                   */
/*   DO NOT COPY, STEAL, SELL THIS CODE    */
/* --------------------------------------- */

public class CustomKontroller {

    public CustomKontroller() {
        this.params = ApexPages.CurrentPage().getParameters();
        this.action = params.get('action');
    }

    private String action;
    private map<String, String> params;

    public PageReference Director() {
        PageReference page;

        System.debug('\n**** Kontroller parameters: '+this.params);     

        /* Attach Quote/Order/Invoice PDF */
        if (action == 'attachPDF') {
            page = AttachPDF();
        }

        return page;
    }

	// Generate quote/order/invoice pdf and attach to Notes and Attachment section.
    public static PageReference AttachPDF() {
        map<String, String> params = ApexPages.CurrentPage().getParameters();
        string action = params.get('action');

        PageReference pdfPage;
        Id cid = (Id) params.get('Id');
        String pdfName = params.get('pdfName');        
        String objectType = params.get('object');

        System.debug('action '+ action + ' id ' + cid + ' pdfname ' + pdfName);

        // Assign sobject and page values based upon object type (object parameter)                    
        if (objectType == 'quote') {
            //pdfPage = Page.CustomQuotePDF;
            pdfPage = new Pagereference('/apex/CustomQuotePDF');
        } else if (objectType == 'order') {
            //pdfPage = Page.CustomOrderPDF;
            pdfPage = new Pagereference('/apex/CustomOrderPDF');                               
        } else if (objectType == 'invoice') {
            //pdfPage = Page.CustomInvoicePDF;
            pdfPage = new Pagereference('/apex/CustomInvoicePDF');
        }
        // set page parameters
        pdfPage.getParameters().put('id',cid);
        pdfPage.getParameters().put('p','pdf');

        // generate the pdf blob
		Blob pdfBlob = test.isRunningTest() ? Blob.valueOf('Test pdf') : pdfPage.getContent();

        // create the attachment against the quote
        Attachment a = new Attachment(parentId=cid, name=pdfName+'.pdf', body=pdfBlob);

        // insert the attachment
        insert a;

        // send the user back to the quote/order/invoice detail page
        return new pageReference('/' + cid);
    }
}