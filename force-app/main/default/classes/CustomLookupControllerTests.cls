@isTest
public with sharing class CustomLookupControllerTests {
    @TestSetup
    public static void makeData(){
        Account a = BoomTestHelpers.generateAccount();
        Contact c = BoomTestHelpers.generateContact(a.Id);
    }

    @isTest
    public static void testMethod1() {
        CustomLookupController.getSearchResult('Contact', 'Name', 'jan');
        CustomLookupController.getSearchResult('Contact', 'Name', 'jan', 'Account.Name', 'tes');
        CustomLookupController.getSearchResult('Contact', 'MailingStreet', 'jac', 'Account.Name', 'tes');
    }
}
