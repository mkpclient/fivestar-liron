public class TestUpdateOpportunityFieldBatchClass {
    public static void  testUpdateOpportunityFieldBatch(integer batchsize)
    {
        Set<String> setOppIds = new Set<String>();
        List<OppIdsToUpdate__mdt> lstOppMdt= [SELECT Label,OppIds__c  FROM OppIdsToUpdate__mdt];
        for(OppIdsToUpdate__mdt oppmdt:lstOppMdt)
        {
            if(!String.isBlank(oppmdt.OppIds__c))
            {
                List<String> lstOppIds= oppmdt.OppIds__c.Split(',');
                for(String oppid:lstOppIds)
                {
                    setOppIds.add(oppid);
                }
            }
        }        
        if(Test.isRunningTest())
        {
            setOppIds.Clear();
            Opportunity opp = [select id , Market_Project__c from Opportunity  where Market_Project__c!= null limit 1];
            setOppIds.add(opp.id);
        }       
        
        UpdateOpportunityField updateOpp = new UpdateOpportunityField();
        updateOpp.setOppIds = setOppIds;
        updateOpp.query = 'select id,Pardot_Campaign_Type__c, Market_Project__c from Opportunity where id in :setOppIds AND Market_Project__c!= null';
        Database.executeBatch(updateOpp,batchsize);

    }
}