/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_kugo2p_PaymentXTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_kugo2p_PaymentXTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new kugo2p__PaymentX__c());
    }
}