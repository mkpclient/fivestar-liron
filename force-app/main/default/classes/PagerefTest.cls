@isTest
public with sharing class PagerefTest {
    @isTest
    public static void testUserAccess() {
        String uniqueUserName = 'testuser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='default Profile'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);
        insert u;
         System.runAs(u) {
            String CRON_EXP = '0 0 0 3 9 ? 2022';
            String jobId = System.schedule('TestingPagereferenceInSchedule', CRON_EXP, new TestingPagereferenceInSchedule());
            }


    }
}
