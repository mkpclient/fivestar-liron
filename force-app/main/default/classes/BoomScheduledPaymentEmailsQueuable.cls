global class BoomScheduledPaymentEmailsQueuable implements Queueable{
    private List<SObject> records;

    global BoomScheduledPaymentEmailsQueuable(List<SObject> records) {
        this.records = records;
    }

    global void execute (QueueableContext qCntxt) {
        if(this.records.size() > 0) {
            PaymentBatchableHelper.processEmails(this.records);
        }
    }
}
