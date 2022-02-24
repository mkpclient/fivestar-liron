global with sharing class TestingPagereferenceInSchedule implements Schedulable {
    public static String SoId = 'a5c52000000B3l0AAC';

    global void execute(SchedulableContext ctx) {
        PageReference pref = Page.SalesOrderInvoicePDF;
        pref.getParameters().put('id', SoId);
        pref.setRedirect(true);

        String fullUrl = Url.getSalesforceBaseUrl().toExternalForm() + pref.getUrl();

        System.debug(fullUrl);
        System.debug(pref);
    }
}