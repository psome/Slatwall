/*

    Slatwall - An Open Source eCommerce Platform
    Copyright (C) ten24, LLC
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
	
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
	
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Linking this program statically or dynamically with other modules is
    making a combined work based on this program.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.
	
    As a special exception, the copyright holders of this program give you
    permission to combine this program with independent modules and your 
    custom code, regardless of the license terms of these independent
    modules, and to copy and distribute the resulting program under terms 
    of your choice, provided that you follow these specific guidelines: 

	- You also meet the terms and conditions of the license of each 
	  independent module 
	- You must not alter the default display of the Slatwall name or logo from  
	  any part of the application 
	- Your custom code must not alter or create any files inside Slatwall, 
	  except in the following directories:
		/integrationServices/

	You may copy and distribute the modified version of this program that meets 
	the above guidelines as a combined work under the terms of GPL for this program, 
	provided that you include the source code of that other code when and as the 
	GNU GPL requires distribution of source code.
    
    If you modify this program, you may extend this exception to your version 
    of the program, but you are not obligated to do so.

Notes:

*/
component accessors="true" extends="Slatwall.org.Hibachi.HibachiService" {

	public any function getSlatwallScope() {
		return getHibachiScope();
	} 
	
	// @hint leverages the getEntityHasAttributeByEntityName() by traverses a propertyIdentifier first using getLastEntityNameInPropertyIdentifier()
	public boolean function getHasAttributeByEntityNameAndPropertyIdentifier( required string entityName, required string propertyIdentifier ) {
		return getEntityHasAttributeByEntityName( entityName=getLastEntityNameInPropertyIdentifier(arguments.entityName, arguments.propertyIdentifier), attributeCode=listLast(arguments.propertyIdentifier, "._") );
	}
	
	// @hint returns true or false based on an entityName, and checks if that entity has an extended attribute with that attributeCode
	public boolean function getEntityHasAttributeByEntityName( required string entityName, required string attributeCode ) {
		if(listFindNoCase(getAttributeService().getAttributeCodesListByAttributeSetType( "ast#getProperlyCasedShortEntityName(arguments.entityName)#" ), arguments.attributeCode)) {
			return true;
		}
		return false; 
	}
	
	public boolean function delete(required any entity){
		
		var deleteOK = super.delete(argumentcollection=arguments);
			
		// If the entity Passes validation
		if(deleteOK) {
			
			// Remove all of the entity settings
			getService("settingService").removeAllEntityRelatedSettings( entity=arguments.entity );
			
			// Remove all of the entity comments and comments related to this entity
			getService("commentService").removeAllEntityRelatedComments( entity=arguments.entity );
			
		}

		return deleteOK;
	}
	
	public any function save(required any entity, struct data={}, string context="save"){
		
		arguments.entity = super.save(argumentcollection=arguments);
		
		// If an entity was saved and the activeFlag is now 0 it needs to be removed from all setting values
		if(!arguments.entity.hasErrors() && arguments.entity.hasProperty('activeFlag')) {
			
			var settingsRemoved = 0;
			if(!arguments.entity.getActiveFlag()) {
				var settingsRemoved = getService("settingService").updateAllSettingValuesToRemoveSpecificID( arguments.entity.getPrimaryIDValue() );	
			}
			
			if(settingsRemoved gt 0 || listFindNoCase("Currency,FulfillmentMethod,OrderOrigin,PaymentTerm,PaymentMethod", arguments.entity.getClassName())) {
				getService("settingService").clearAllSettingsCache();
			}
		}
	
		return arguments.entity;
	}

}
