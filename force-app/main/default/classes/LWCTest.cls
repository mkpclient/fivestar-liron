@isTest
public with sharing class LWCTest {
    @isTest
    private static void testMethod1() {
        Object fieldLabels = LWC.getFieldLabels((String) 'Opportunity, Account');
        System.assertEquals(false, fieldLabels == null, 'fieldLabels should not be null');
        String acctSoql = 'SELECT Id, Name FROM Account WHERE Id IN ('; 
        for(Integer i = 0; i < 3; i++) {
            acctSoql += '\'' + BoomTestHelpers.generateAccount().Id + '\'';
            if(i < 2) {
                acctSoql += ',';
            }
        }
        acctSoql += ')';
        List<Account> queriedAccts = LWC.doQuery(acctSoql);
        System.assertEquals(true, queriedAccts.size() > 0, 'queriedAccts should not be empty');
        for(Integer i = 0; i < queriedAccts.size(); i++) {
            queriedAccts[i].Name = 'New Name ' + i;
        }
        LWC.saveMultipleRecords(queriedAccts);
        List<Account> updatedAccts = LWC.doQuery(acctSoql);
        for(Account acc : updatedAccts) {
            System.assertEquals(true, acc.Name.startsWith('New Name'), 'Account name should start with "New Name"');
        }
        LWC.deleteMultipleRecords(updatedAccts);
        List<Account> deletedAccts = LWC.doQuery(acctSoql);
        System.assertEquals(true, deletedAccts.size() == 0, 'deletedAccts should be empty');

        Account singleTestAcct = BoomTestHelpers.generateAccount();
        singleTestAcct.Name = 'New Test Name';
        LWC.saveRecord(singleTestAcct);
        
        Account updatedAcct = (Account) LWC.doQuery('SELECT Id, Name FROM Account WHERE Id = \'' + singleTestAcct.Id + '\'')[0];
        System.assertEquals(true, updatedAcct.Name.startsWith('New Test Name'), 'Account name should start with "New Test Name"');
        
        LWC.attachPDF(singleTestAcct.Id, 'testFile');
        List<Attachment> testAttachments = [SELECT ParentId FROM Attachment WHERE ParentId = :singleTestAcct.Id];
        System.assertEquals(true, testAttachments.size() > 0, 'testAttachments should not be empty');

        LWC.deleteRecord(singleTestAcct);
        List<Account> deletedAcct = LWC.doQuery('SELECT Id, Name FROM Account WHERE Id = \'' + singleTestAcct.Id + '\'');
        System.assertEquals(true, deletedAcct.size() == 0, 'deletedAcct should be empty');

        String deletionSoql = 'SELECT Id, Name FROM Account WHERE Id IN (';
        for(Integer i = 0; i < 3; i++) {
            deletionSoql += '\'' + BoomTestHelpers.generateAccount().Id + '\'';
            if(i < 2) {
                deletionSoql += ',';
            }
        }
        deletionSoql += ')';
        LWC.deleteRecordWithQuery(deletionSoql);
        List<Account> deletedAccts2 = LWC.doQuery(deletionSoql);
        System.assertEquals(true, deletedAccts2.size() == 0, 'deletedAccts2 should be empty');
    }
}