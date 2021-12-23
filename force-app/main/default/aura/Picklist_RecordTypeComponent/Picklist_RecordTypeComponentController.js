({
	doInit: function (component, event, helper) {
		component.set('v.showSpinner', true)
		console.log(component.get('v.selectedRecordTypeId'))

		console.log(component.get('v.selectedRecordTypeId'))
		console.log(component.get('v.objectApiName'))
		console.log(component.get('v.fieldApiName'))

		let action = component.get('c.queryForPicklistValues')
		action.setParams({
			recordType: component.get('v.selectedRecordTypeId'),
			objectName: component.get("v.objectApiName"),
			field: component.get("v.fieldApiName")
		})

		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === 'SUCCESS') {
				component.set('v.picklistValues', response.getReturnValue());
				component.set('v.showSpinner', false)
			} else {
				console.log('state: ' + state)
				if (state === 'ERROR') {
					console.log(response.getError())
				}
			}
		})
		$A.enqueueAction(action)
	}
})