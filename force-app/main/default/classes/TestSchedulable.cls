global class TestSchedulable implements Schedulable {
  global static String INSTANCE = 'CS170';
  public List<String> orderIds;

  public TestSchedulable(List<String> ids) {
    orderIds = ids;
  }

  global void execute(SchedulableContext sc) {
    System.debug('test schedule');
    System.debug(orderIds);
    System.debug('is batch: ' + System.isBatch());
    System.debug('is future: ' + System.isFuture());
    // if ( System.isBatch() && System.isFuture() == false ) {
      emailOrders(orderIds);
    // }
  }

  @future(callout=true) 
  public static void emailOrders(List<String> orderIds) {
    System.debug('email orders');
    String url = 'https://' + INSTANCE + '.my.salesforce.com/services/apexrest/attachments';
    System.debug(url);

    Map<String, List<String>> reqBody = new Map<String, List<String>>{
      'ids' => orderIds
    };

    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('POST');
    req.setHeader('Authorization', 'OAuth' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');
    req.setBody(JSON.serialize(reqBody));
    System.debug(reqBody);
    Http h = new Http();
    HttpResponse response = h.send(req);

    System.debug(response.getStatusCode());
    if ( response.getStatusCode() == 307 ) {
      System.debug('have a 307 error');
    }
  }
}