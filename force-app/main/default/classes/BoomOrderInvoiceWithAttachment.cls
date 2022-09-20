public without sharing class BoomOrderInvoiceWithAttachment {
  public static InvoiceTiming__mdt INVOICE_TIMING = [
    SELECT Id, Hours__c, Minutes__c
    FROM InvoiceTiming__mdt
    WHERE Label = 'Default'
    LIMIT 1
  ];
  public static Integer HOURS = Integer.valueOf(INVOICE_TIMING.Hours__c);
  public static Integer MINUTES = Integer.valueOf(INVOICE_TIMING.Minutes__c);

  @InvocableMethod(
    label='Send an email from apex class'
    description='sends an email'
  )
  public static void sendEmailWithAttachment(List<id> listofSalesOrderIds) {
    DateTime todayDate = Datetime.now();
    if (HOURS != null && !System.isBatch()) {
      todayDate = todayDate.addHours(Integer.valueOf(HOURS));
    }
    if (MINUTES != null && !System.isBatch()) {
      todayDate = todayDate.addMinutes(Integer.valueOf(MINUTES));
    } else {
      todayDate = todayDate.addSeconds(15);
    }

    system.debug('listofSalesOrderIds==' + listofSalesOrderIds);
    String scheduleName =
      'BoomOrderInvoiceWithAttachment' +
      System.now().format('mm/dd/yyyy') +
      string.valueOf(todayDate.second()) +
      +string.valueOf(todayDate.millisecond()) +
      '&' +
      listofSalesOrderIds[0];
    String sch =
      todayDate.second() +
      ' ' +
      todayDate.minute() +
      ' ' +
      todayDate.hour() +
      ' ' +
      todayDate.day() +
      ' ' +
      todayDate.month() +
      ' ? ' +
      '  ' +
      todayDate.year();
    System.debug('@@Beforebatch');
    Map<String, CronTrigger> mapSoIdToScName = new Map<String, CronTrigger>();
    mapSoIdToScName = getJobMap();
    System.debug('@@mapSoIdToScName===' + mapSoIdToScName);
    if (
      ((!mapSoIdToScName.containskey(listofSalesOrderIds[0])) ||
      (mapSoIdToScName.containskey(listofSalesOrderIds[0]) &&
      mapSoIdToScName.get(listofSalesOrderIds[0]).state == 'DELETED'))
    ) {
      String jobID = System.schedule(
        scheduleName,
        sch,
        new SendBoomOrderInvoiceAfterOneHour(listofSalesOrderIds)
      );
    }
    System.debug('@@Afterbatch');
  }

  private static Map<String, CronTrigger> getJobMap() {
    String sendEmailJObName = '%BoomOrderInvoiceWithAttachment%';
    List<CronTrigger> lstct = [
      SELECT Id, CronJobDetail.Name, State, CronJobDetail.JobType
      FROM CronTrigger
      WHERE CronJobDetail.Name LIKE :sendEmailJObName
    ];
    Map<String, CronTrigger> mapJobNameToJobId = new Map<String, CronTrigger>();
    for (CronTrigger ct : lstct) {
      System.debug('ct.CronJobDetail.Name==' + ct.CronJobDetail.Name);
      if (
        ct.CronJobDetail.Name != null && ct.CronJobDetail.Name.Contains('&')
      ) {
        /* if(ct.State == 'COMPLETE') {
                      system.abortJob(ct.Id);
                  } else {*/
        String SoId = ct.CronJobDetail.Name.Substring(
          ct.CronJobDetail.Name.indexOf('&') + 1,
          ct.CronJobDetail.Name.length()
        );
        mapJobNameToJobId.put(SoId, ct);
        //  }
      }
    }
    return mapJobNameToJobId;
  }
}