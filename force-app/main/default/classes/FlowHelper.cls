public with sharing class FlowHelper {
	@auraEnabled 
	public static List<String> queryForPicklistValues(String recordType, String objectName, String field) {
		System.debug(recordType + '::' + objectName + '::' + field);


		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setHeader('Authorization', 'Bearer ' + getSessionId());
		req.setHeader('Content-Type', 'application/json; charset=UTF-8');
		req.setHeader('Accept', 'application/json');
		req.setEndpoint(constructEndpoint(recordType, objectName, field));

		if (!Test.isRunningTest()) {
			HttpResponse res = new Http().send(req);
			return handleResponse(res);
		}
		return null;
	}
	
	public static List<String> handleResponse(HttpResponse res) {
		List<String> vals = new List<String>();

		System.debug(res.getBody());

		responseWrapper resWrapper = (responseWrapper)JSON.deserialize(res.getBody(), responseWrapper.class);
	
		for (valueWrapper rw : resWrapper.values) {
			vals.add(rw.value);
		}
	
		return vals;

	}

	private static String getSessionId() {
		return UserInfo.getSessionId().substring(15);
	}

	public static String constructEndpoint(String recordType, String objectName, String field) {
		System.debug(recordType + '::' + objectName + '::' + field);

		return System.Url.getOrgDomainUrl().toExternalForm() + '/services/data/v44.0/ui-api/object-info/' + objectName + '/picklist-values/' + recordType + '/' + field;
	}

	public class responseWrapper {
		@auraEnabled public List<valueWrapper> values;
	}

	public class valueWrapper {
		@auraEnabled public String label;
		@auraEnabled public String value;
	}
}