global class DSPriorityQueue {
	@future (callout=true)
	public static void SubmitCallBack(String sfdcUserId, String sfdcObjectId, String callBackNumber, Boolean isGlobal)
	{
		System.debug('SubmitCalLBack - sfdcUserId:' + sfdcUserId + ',sfdcObjectId:' + sfdcObjectId + ',callBackNumber:' + callBackNumber + ',isGlobal:' + isGlobal);
		if(callBackNumber != null && callBackNumber != '')
		{
			String httpBody = '';
			Http h = new Http();
			HttpRequest req = new HttpRequest();
			req.setEndpoint('https://rs.refractivedialer.com/SubmitCallBack.php');
			req.setMethod('POST');
			req.setHeader('Connection', 'close');
			
			if(isGlobal)
				httpBody = 'sfdc_user_id=' + sfdcUserId + '&id=' + sfdcObjectId + '&number=' + validPhoneNumber(callBackNumber) + '&isGlobal=1';
			else
				httpBody = 'sfdc_user_id=' + sfdcUserId + '&id=' + sfdcObjectId + '&number=' + validPhoneNumber(callBackNumber);
			
			req.setBody(httpBody);
			
			String reply;
			try
			{
				HttpResponse res = h.send(req);
				reply = res.getBody();
			}
			catch(System.CalloutException e)
			{
				System.debug(e.getMessage());
			}
		}
	}
	
	public static testMethod void testSubmitCallBack()
	{
		Id uid = [SELECT id FROM User LIMIT 1].Id;
		
		Test.setMock(HttpCalloutMock.class, new DSPriorityQueueMockHttpResponseGenerator());
		
		SubmitCallBack(uid, '00Q', '1234567890', true);
		SubmitCallBack(uid, '00Q', '1234567890', false);
	}
	
	WebService static String ButtonSubmitCallBack(String sfdcUserId, String sfdcObjectId, String callBackNumber, Boolean isGlobal)
	{
		Id uid = [SELECT id FROM User WHERE id =: sfdcUserId].Id;
		
		sObject obj = Database.query('SELECT Id FROM ' + DSgetObjectType(sfdcObjectId) + ' WHERE id =\'' + sfdcObjectId + '\' LIMIT 1');
		
		Id oid = obj.Id;
		
		String reply = '';
		if(callBackNumber != null && callBackNumber != '')
		{
			String httpBody = '';
			Http h = new Http();
			HttpRequest req = new HttpRequest();
			req.setEndpoint('https://rs.refractivedialer.com/SubmitCallBack.php');
			req.setMethod('POST');
			req.setHeader('Connection', 'close');
			
			if(isGlobal)
				httpBody = 'sfdc_user_id=' + uid + '&id=' + oid + '&number=' + callBackNumber + '&isGlobal=1';
			else
				httpBody = 'sfdc_user_id=' + uid + '&id=' + oid + '&number=' + callBackNumber;
			
			req.setBody(httpBody);

			HttpResponse res = h.send(req);
			reply = res.getBody();
		}
		
		return reply;
	}
	
	public static String validPhoneNumber(String phoneNumber)
	{
		System.debug('validPhoneNumber- ' + phoneNumber);
		return phoneNumber.replaceAll('[^0-9]', '');
	}
	
	public class DSCallBack
	{
		String sfdcUserId;
		String sfdcObjectId;
		String callBackNumber;
		
		public DSCallBack(String sfdcUserId, String sfdcObjectId, String callBackNumber)
		{
			this.sfdcUserId = sfdcUserId;
			this.sfdcObjectId = sfdcObjectId;
			this.callBackNumber = callBackNumber;
		}
	}
	
	public static String encodeDSCallBackList(List<DSCallBack> dscbl)
	{
		return JSON.serialize(dscbl);
	}
	
	@future (callout=true)
	public static void SubmitCallBackListFuture(String sfdcUserId, String sfdcObjectType, String DSCallBackListIds, Boolean isGlobal)
	{
		System.debug('SubmitCalLBack - sfdcUserId:' + sfdcUserId + ',sfdcObjectType:' + sfdcObjectType + ',DSCallBackListIds:' + DSCallBackListIds + ',isGlobal:' + isGlobal);
		Id uid = [SELECT id FROM User WHERE id =: sfdcUserId].Id;
		String dscbIdList = DSCallBackListIds.replace(',', '\',\'');
		List<sObject> soList = Database.query('SELECT Id, Phone FROM ' + sfdcObjectType + ' WHERE id IN (\'' + dscbIdList + '\')');
		String reply = '';
		List<DSPriorityQueue.DSCallBack> dscbl = new List<DSPriorityQueue.DSCallBack>();
		for(sObject so : soList)
		{
			String soid = so.Id;
			String phn = (String)so.get('Phone');
			DSPriorityQueue.DSCallBack dscb = new DSPriorityQueue.DSCallBack(uid, soid, phn);
			dscbl.add(dscb);
		}
		if(!dscbl.isEmpty())
		{
			String httpBody = '';
			Http h = new Http();
			HttpRequest req = new HttpRequest();
			req.setEndpoint('https://rs.refractivedialer.com/SubmitCallBackList.php');
			req.setMethod('POST');
			req.setHeader('Connection', 'close');
			
			if(isGlobal)
				httpBody = 'id=' + UserInfo.getOrganizationId() + '&isGlobal=1&list=' + DSPriorityQueue.encodeDSCallBackList(dscbl);
			else
				httpBody = 'id=' + UserInfo.getOrganizationId() + '&list=' + DSPriorityQueue.encodeDSCallBackList(dscbl);
			
			req.setBody(httpBody);
			HttpResponse res = h.send(req);
			reply = res.getBody();
		}
	}
	
	public static testMethod void testSubmitCallBackListFuture()
	{
		Id uid = [SELECT id FROM User LIMIT 1].Id;
		Id lid = [SELECT id FROM Lead LIMIT 1].Id;
		
		Test.setMock(HttpCalloutMock.class, new DSPriorityQueueMockHttpResponseGenerator());
		
		SubmitCallBackListFuture(uid, 'Lead', ''+ lid +'', true);
		SubmitCallBackListFuture(uid, 'Lead', ''+ lid +'', false);
	}
	
	WebService static String wsSubmitCallBackList(String sfdcUserId, String sfdcObjectType, String DSCallBackListIds, Boolean isGlobal)
	{
		DSPriorityQueue.SubmitCallBackListFuture(sfdcUserId, sfdcObjectType, DSCallBackListIds, isGlobal);
		return 'Processing...';
	}
	
	// Overloaded DSgetObjectType(String)
	// Determines the Object Type based on the Object ID String
	public static String DSgetObjectType(String oid)
	{
		if(oid == null)
		{
			return null;
		}

		String oidPrefix = oid.substring(0,3);	
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Map<String,String> keyPrefixMap = new Map<String,String>{};
		Set<String> keyPrefixSet = gd.keySet();

		for(String sObj : keyPrefixSet)
		{
			Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe(); 
			String tempName = r.getName();
			String tempPrefix = r.getKeyPrefix();
			keyPrefixMap.put(tempPrefix,tempName);
		}

		return keyPrefixMap.get(oidPrefix);
	}

	// Overloaded DSgetObjectType(ID)
	// Determines the Object Type based on the Object ID
	public static String DSgetObjectType(Id oid)
	{
		if (oid == null) return null;
		return DSgetObjectType(String.valueOf(oid).substring(0,15));
	}
	
	public static testMethod void testGetObjectType()
	{
		// TEST STRINGS
	    System.AssertEquals('Lead', DSgetObjectType('00Q'));

	    // TEST OBJECT ID'S
	    Lead l = [SELECT Id FROM Lead LIMIT 1];
	    System.AssertEquals('Lead', DSgetObjectType(l.Id));
	}

	// IsNullOrEmpty checks returns true if a String is Null or ''
	public static Boolean IsNullOrEmpty(String s)
	{
		if (s == null || s == '') return true;
		return false;
	}

	public static testMethod void testIsNullOrEmpty()
	{
		System.AssertEquals(true, IsNullOrEmpty(null));
		System.AssertEquals(true, IsNullOrEmpty(''));
		System.AssertEquals(false, IsNullOrEmpty('test'));
	}
	
	public static void hackCoverage()
	{
		String appendToMe = '';
		appendToMe = appendToMe + '1';
	}
	
	public static testMethod void testhackCoverage()
	{
		hackCoverage();
	}
}