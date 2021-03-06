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
component output="false" accessors="true" extends="Slatwall.org.Hibachi.HibachiScope" {

	// Slatwall specific request entity properties
	property name="brand" type="any";
	property name="cart" type="any";
	property name="content" type="any";
	property name="product" type="any";
	property name="productType" type="any";
	property name="site" type="any";
	
	// Slatwall specific request smartList properties
	property name="productSmartList" type="any";
	
	// Slatwall Specific queue properties
	property name="emailQueue" type="array";
	
	// Deprecated Properties
	property name="currentAccount";
	property name="currentBrand";
	property name="currentCart";
	property name="currentContent";
	property name="currentProduct";
	property name="currentProductType";
	
	property name="currentProductSmartList";
	
	// ================= Overrides =================================
	
	public string function renderJSObject() {
		var config = {};
		config[ 'baseURL' ] = getApplicationValue('baseURL');
		config[ 'action' ] = getApplicationValue('action');
		config[ 'dateFormat' ] = setting('globalDateFormat');
		config[ 'timeFormat' ] = setting('globalTimeFormat');
		
		var returnHTML = '';
		returnHTML &= '<script type="text/javascript" src="#getApplicationValue('baseURL')#/org/Hibachi/HibachiAssets/js/hibachi-scope.js"></script>';
		returnHTML &= '<script type="text/javascript">(function( $ ){$.#lcase(getApplicationValue('applicationKey'))# = new Hibachi(#serializeJSON(config)#);})( jQuery );</script>';
		return returnHTML;
	}
	
	// ================= Entity Helper Methods =====================
	
	// Brand
	public any function getBrand() {
		if(!structKeyExists(variables, "brand")) {
			variables.brand = getService("brandService").newBrand();
		}
		return variables.brand;
	}

	// Cart
	public any function getCart() {
		return getSession().getOrder();
	}

	// Content
	public any function getContent() {
		if(!structKeyExists(variables, "content")) {
			variables.content = getService("contentService").newContent();
		}
		return variables.content;
	}
	
	// Product
	public any function getProduct() {
		if(!structKeyExists(variables, "product")) {
			variables.product = getService("productService").newProduct();
		}
		return variables.product;
	}
	
	// Product Type
	public any function getProductType() {
		if(!structKeyExists(variables, "productType")) {
			variables.productType = getService("productService").newProductType();
		}
		return variables.productType;
	}
	
	// Site
	public any function getSite() {
		if(!structKeyExists(variables, "site")) {
			variables.site = getService("siteService").newSite();
		}
		return variables.site;
	}
	
	// ================= Smart List Helper Methods =====================
	
	// Product Smart List
	public any function getProductSmartList() {
		if(!structKeyExists(variables, "productSmartList")) {
			variables.productSmartList = getService("productService").getProductSmartList(data=url);
			variables.productSmartList.setSelectDistinctFlag( 1 );
			variables.productSmartList.addFilter('activeFlag', 1);
			variables.productSmartList.addFilter('publishedFlag', 1);
			variables.productSmartList.addRange('calculatedQATS', '1^');
			if(isBoolean(getContent().getProductListingPageFlag()) && getContent().getProductListingPageFlag() && isBoolean(getContent().setting('contentIncludeChildContentProductsFlag')) && getContent().setting('contentIncludeChildContentProductsFlag')) {
				variables.productSmartList.addWhereCondition(" EXISTS(SELECT sc.contentID FROM SlatwallContent sc INNER JOIN sc.listingProducts slp WHERE sc.contentIDPath LIKE '%#getContent().getContentID()#%' AND slp.productID = aslatwallproduct.productID) ");
			} else if(isBoolean(getContent().getProductListingPageFlag()) && getContent().getProductListingPageFlag()) {
				variables.productSmartList.addFilter('listingPages.contentID',getContent().getContentID());
			}
		}
		return variables.productSmartList;
	}
	
	// ================= Queue Helper Methods =====================
	
	// Email
	public array function getEmailQueue() {
		if(!structKeyExists(variables, "emailQueue")) {
			variables.emailQueue = [];
		}
		return variables.emailQueue;
	}
	
	// Print
	public array function getPrintQueue() {
		if(!hasSessionValue('printQueue')) {
			setSessionValue('printQueue', []);
		}
		return getSessionValue('printQueue');
	}
	
	// Clear Email & Print
	public void function clearPrintQueue() {
		setSessionValue('printQueue', []);
	}
	
	public void function clearEmailAndPrintQueue() {
		variables.emailQueue = [];
		setSessionValue('printQueue', []);
	}
	
	// =================== Image Access ===========================
	
	public string function getBaseImageURL() {
		return getURLFromPath(setting('globalAssetsImageFolderPath'));
	}
	
	public string function getResizedImage() {
		return getService("imageService").getResizedImage(argumentCollection=arguments);
	}
	
	public string function getResizedImagePath() {
		return getService("imageService").getResizedImagePath(argumentCollection=arguments);
	}
	
	// =================== Setting Access =========================
	
	// @hint helper function to return a Setting
	public any function setting(required string settingName, array filterEntities=[], formatValue=false) {
		return getService("settingService").getSettingValue(settingName=arguments.settingName, object=this, filterEntities=arguments.filterEntities, formatValue=arguments.formatValue);
	}

	// @hint helper function to return the details of a setting
	public struct function getSettingDetails(required any settingName, array filterEntities=[]) {
		return getService("settingService").getSettingDetails(settingName=arguments.settingName, object=this, filterEntities=arguments.filterEntities);
	}
	
	// ================== onMissingMethod =========================
	public any function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
		
		// xxx() will do getXXX() and then either get a property, set a property, or return the entire object
		if(structKeyExists(variables, "get#arguments.missingMethodName#")) {
			if( structKeyExists(arguments.missingMethodArguments, "1") && structKeyExists(arguments.missingMethodArguments, "2")) {
				return this.invokeMethod("get#arguments.missingMethodName#").invokeMethod("set#arguments.missingMethodArguments.1#", {1=arguments.missingMethodArguments.2});
			} else if ( structKeyExists(arguments.missingMethodArguments, "1") ) {
				return this.invokeMethod("get#arguments.missingMethodName#").invokeMethod("get#arguments.missingMethodArguments.1#");
			} else {
				return this.invokeMethod("get#arguments.missingMethodName#");
			}
		}
		
	}
	
	// ========================== Deprecated ================= * DO NOT UES!!!!!
	
	public any function getCurrentAccount() {
		return getAccount();
	}
	
	public any function getCurrentBrand() {
		return getBrand();
	}
	
	public any function getCurrentContent() {
		return getContent();
	}
	
	public any function getCurrentProduct() {
		return getProduct();
	}
	
	public any function getCurrentProductType() {
		return getProductType();
	}
	
	public any function getCurrentSession() {
		return getSession();
	}
	
	public any function getCurrentCart() {
		return getCart();
	}
	
	public any function getProductList() {
		return getProductSmartList();
	}
	
	public any function getCurrentProductSmartList() {
		return getProductSmartList();
	}
	
	public string function getSlatwallRootDirectory() {
		return expandPath("/Slatwall");
	}
	
	public any function getSlatwallRootURL() {
		return getBaseURL();
	}
	
	public any function getSlatwallRootPath() {
		return getBaseURL();
	}
	
	public any function sessionFacade(string property, string value) {
		if(structKeyExists(arguments, "property") && structKeyExists(arguments, "value")) {
			return setSessionValue(arguments.property, arguments.value);
		} else if (structKeyExists(arguments, "property")) {
			return getSessionValue(arguments.property);
		}
	}
	
	
}
