/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_kugo2p_Payment_ProfileTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_kugo2p_Payment_ProfileTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new kugo2p__Payment_Profile__c());
    }
}