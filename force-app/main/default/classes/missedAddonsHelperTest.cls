@isTest(seeAllData=true)
public with sharing class missedAddonsHelperTest {
    @isTest
    public static void testLwcMethods() {
        List<missedAddonsHelper.MissedAddonResource> resources = missedAddonsHelper.retrieveMissingAddons();
        
    }
}
