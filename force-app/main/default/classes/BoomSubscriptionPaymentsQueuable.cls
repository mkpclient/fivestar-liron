global class BoomSubscriptionPaymentsQueuable implements Queueable{
    private List<SObject> records;
    private Boolean sendEmail = false;
    private List<SObject> additionalRecords;

    global BoomSubscriptionPaymentsQueuable(List<SObject> records, Boolean sendEmail) {
        this.records = records;
        this.sendEmail = sendEmail;
    }

    global BoomSubscriptionPaymentsQueuable(List<SObject> records, List<SObject> additionalRecords) {
        this.records = records;
        this.additionalRecords = additionalRecords;
    }

    global void execute (QueueableContext qCntxt) {
        if(this.records.size() > 0) {
            upsert this.records;
            if(this.sendEmail && !test.isRunningTest()) {
                System.enqueueJob(new BoomScheduledPaymentEmailsQueuable(this.records));
            }

            if(this.additionalRecords != null && this.additionalRecords.size() > 0 && !test.isRunningTest()) {
                upsert this.additionalRecords;
            }
        }
    }
}