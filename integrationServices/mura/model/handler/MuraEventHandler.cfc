<!---

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
	
--->
<cfcomponent extends="Handler" output="false" accessors="true">
	
	<cfscript>
		
		// ========================== FRONTENT EVENT HOOKS =================================
		public void function onSiteRequestStart( required any $ ) {
			// Setup the slatwallScope into the muraScope
			verifySlatwallRequest( $=$ );
			
			// Update Login / Logout if needed
			autoLoginLogoutFromSlatwall( $=$ );
			
			// Setup the correct local in the request object for the current site
			$.slatwall.setRBLocale( $.siteConfig('javaLocale') );
			
			// Setup the correct site in the request object
			$.slatwall.setSite( $.slatwall.getService("siteService").getSiteByCMSSiteID( $.event('siteID') ) );
			
			// Call any public slatAction methods that are found
			if(len($.event('slatAction')) && listFirst($.event('slatAction'), ":") != "frontend") {
				
				// This allows for multiple actions to be called
				var actionsArray = listToArray( $.event('slatAction') );
				
				// This loops over the actions that were passed in
				for(var a=1; a<=arrayLen(actionsArray); a++) {
				
					// Call the correct public controller
					$.slatwall.doAction( actionsArray[a] );
					
				}
				
			}
			
			// If we aren't on the homepage we can do our own URL inspection
			if( len($.event('path')) ) {
				
				// Inspect the path looking for slatwall URL key, and then setup the proper objects in the slatwallScope
				var brandKeyLocation = 0;
				var productKeyLocation = 0;
				var productTypeKeyLocation = 0;
				
				// First look for the Brand URL Key
				if (listFindNoCase($.event('path'), $.slatwall.setting('globalURLKeyBrand'), "/")) {
					brandKeyLocation = listFindNoCase($.event('path'), $.slatwall.setting('globalURLKeyBrand'), "/");
					if(brandKeyLocation < listLen($.event('path'),"/")) {
						$.slatwall.setBrand( $.slatwall.getService("brandService").getBrandByURLTitle(listGetAt($.event('path'), brandKeyLocation + 1, "/"), true) );
					}
				}
				
				// Look for the Product URL Key
				if(listFindNoCase($.event('path'), $.slatwall.setting('globalURLKeyProduct'), "/")) {
					productKeyLocation = listFindNoCase($.event('path'), $.slatwall.setting('globalURLKeyProduct'), "/");
					if(productKeyLocation < listLen($.event('path'),"/")) {
						$.slatwall.setProduct( $.slatwall.getService("productService").getProductByURLTitle(listGetAt($.event('path'), productKeyLocation + 1, "/"), true) );	
					}
				}
				
				// Look for the Product Type URL Key
				if (listFindNoCase($.event('path'), $.slatwall.setting('globalURLKeyProductType'), "/")) {
					productTypeKeyLocation = listFindNoCase($.event('path'), $.slatwall.setting('globalURLKeyProductType'), "/");
					if(productTypeKeyLocation < listLen($.event('path'),"/")) {
						$.slatwall.setProductType( $.slatwall.getService("productService").getProductTypeByURLTitle(listGetAt($.event('path'), productTypeKeyLocation + 1, "/"), true) );
					}
				}
				
				// Setup the proper content node and populate it with our FW/1 view on any keys that might have been found, use whichever key was farthest right
				if( productKeyLocation && productKeyLocation > productTypeKeyLocation && productKeyLocation > brandKeyLocation && !$.slatwall.getProduct().isNew() && $.slatwall.getProduct().getActiveFlag() && ($.slatwall.getProduct().getPublishedFlag() || $.slatwall.getProduct().setting('productShowDetailWhenNotPublishedFlag'))) {
					
					// Attempt to load up the content template node, based on this products setting
					var productTemplateContent = $.slatwall.getService("contentService").getContent( $.slatwall.getProduct().setting('productDisplayTemplate', [$.slatwall.getSite()]) );
					
					// As long as the content is not null, and has all the necessary values we can continue
					if(!isNull(productTemplateContent) && !isNull(productTemplateContent.getCMSContentID()) && !isNull(productTemplateContent.getSite()) && !isNull(productTemplateContent.getSite().getCMSSiteID())) {
						
						// Setup the content node in the slatwallScope
						$.slatwall.setContent( productTemplateContent );
						
						// Override the contentBean for the request
						$.event('contentBean', $.getBean("content").loadBy( contentID=$.slatwall.getContent().getCMSContentID(), siteID=$.slatwall.getContent().getSite().getCMSSiteID() ) );
						$.event('muraForceFilename', false);
						
						// Change Title, HTMLTitle & Meta Details of page
						$.content().setTitle( $.slatwall.getProduct().getTitle() );
						if(len($.slatwall.getProduct().setting('productHTMLTitleString'))) {
							$.content().setHTMLTitle( $.slatwall.getProduct().stringReplace( $.slatwall.getProduct().setting('productHTMLTitleString') ) );	
						} else {
							$.content().setHTMLTitle( $.slatwall.getProduct().getTitle() );
						}
						$.content().setMetaDesc( $.slatwall.getProduct().stringReplace( $.slatwall.getProduct().setting('productMetaDescriptionString') ) );
						$.content().setMetaKeywords( $.slatwall.getProduct().stringReplace( $.slatwall.getProduct().setting('productMetaKeywordsString') ) );
						
						// DEPRECATED*** If LegacyInjectFlag is set to true then add the body
						if($.slatwall.setting('integrationMuraLegacyInjectFlag')) {
							$.content('body', $.content('body') & $.slatwall.doAction('frontend:product.detail'));
						}
						
						// Setup CrumbList
						if(productKeyLocation > 2) {
							var listingPageFilename = left($.event('path'), find("/#$.slatwall.setting('globalURLKeyProduct')#/", $.event('path'))-1);
							listingPageFilename = replace(listingPageFilename, "/#$.event('siteID')#/", "", "all");
							var crumbDataArray = $.getBean("contentManager").getActiveContentByFilename(listingPageFilename, $.event('siteid'), true).getCrumbArray();
						} else {
							var crumbDataArray = $.getBean("contentManager").getCrumbList(contentID="00000000000000000000000000000000001", siteID=$.event('siteID'), setInheritance=false, path="00000000000000000000000000000000001", sort="asc");
						}
						arrayPrepend(crumbDataArray, $.slatwall.getProduct().getCrumbData(path=$.event('path'), siteID=$.event('siteID'), baseCrumbArray=crumbDataArray));
						$.event('crumbdata', crumbDataArray);
						
					// If the template couldn't be found then we throw a custom exception
					} else {
						
						throw("Slatwall has attempted to display a product on your website, however the 'Product Display Template' setting is either blank or invalid.  Please navigate to the Slatwall admin and make sure that there is a valid 'Product Display Template' assigned.");
						
					}
					
				} else if ( productTypeKeyLocation && productTypeKeyLocation > brandKeyLocation && !$.slatwall.getProductType().isNew() && $.slatwall.getProductType().getActiveFlag() ) {
					
					// Attempt to find the productType template
					var productTypeTemplateContent = $.slatwall.getService("contentService").getContent( $.slatwall.getProductType().setting('productTypeDisplayTemplate', [$.slatwall.getSite()]) );
					
					// As long as the content is not null, and has all the necessary values we can continue
					if(!isNull(productTypeTemplateContent) && !isNull(productTypeTemplateContent.getCMSContentID()) && !isNull(productTypeTemplateContent.getSite()) && !isNull(productTypeTemplateContent.getSite().getCMSSiteID())) {
						
						// Setup the content node in the slatwallScope
						$.slatwall.setContent( productTypeTemplateContent );
						
						// Override the contentBean for the request
						$.event('contentBean', $.getBean("content").loadBy( contentID=$.slatwall.getContent().getCMSContentID(), siteID=$.slatwall.getContent().getSite().getCMSSiteID() ) );
						$.event('muraForceFilename', false);
						
						// Change Title, HTMLTitle & Meta Details of page
						$.content().setTitle( $.slatwall.getProductType().getProductTypeName() );
						if(len($.slatwall.getProductType().setting('productTypeHTMLTitleString'))) {
							$.content().setHTMLTitle( $.slatwall.getProductType().stringReplace( $.slatwall.getProductType().setting('productTypeHTMLTitleString') ) );	
						} else {
							$.content().setHTMLTitle( $.slatwall.getProductType().getProductTypeName() );
						}
						$.content().setMetaDesc( $.slatwall.getProductType().stringReplace( $.slatwall.getProductType().setting('productTypeMetaDescriptionString') ) );
						$.content().setMetaKeywords( $.slatwall.getProductType().stringReplace( $.slatwall.getProductType().setting('productTypeMetaKeywordsString') ) );
						
					} else {
						
						throw("Slatwall has attempted to display a 'Product Type' on your website, however the 'Product Type Display Template' setting is either blank or invalid.  Please navigate to the Slatwall admin and make sure that there is a valid 'Product Type Display Template' assigned.");
						
					}
					
				} else if ( brandKeyLocation && !$.slatwall.getBrand().isNew() && $.slatwall.getBrand().getActiveFlag()  ) {
					
					// Attempt to find the productType template
					var brandTemplateContent = $.slatwall.getService("contentService").getContent( $.slatwall.getBrand().setting('brandDisplayTemplate', [$.slatwall.getSite()]) );
					
					// As long as the content is not null, and has all the necessary values we can continue
					if(!isNull(brandTemplateContent) && !isNull(brandTemplateContent.getCMSContentID()) && !isNull(brandTemplateContent.getSite()) && !isNull(brandTemplateContent.getSite().getCMSSiteID())) {
						
						// Setup the content node in the slatwallScope
						$.slatwall.setContent( brandTemplateContent );
						
						// Override the contentBean for the request
						$.event('contentBean', $.getBean("content").loadBy( contentID=$.slatwall.getContent().getCMSContentID(), siteID=$.slatwall.getContent().getSite().getCMSSiteID() ) );
						$.event('muraForceFilename', false);
						
						// Change Title, HTMLTitle & Meta Details of page
						$.content().setTitle( $.slatwall.getBrand().getBrandName() );
						if(len($.slatwall.getBrand().setting('brandHTMLTitleString'))) {
							$.content().setHTMLTitle( $.slatwall.getBrand().stringReplace( $.slatwall.getBrand().setting('brandHTMLTitleString') ) );	
						} else {
							$.content().setHTMLTitle( $.slatwall.getBrand().getBrandName() );
						}
						$.content().setMetaDesc( $.slatwall.getBrand().stringReplace( $.slatwall.getBrand().setting('brandMetaDescriptionString') ) );
						$.content().setMetaKeywords( $.slatwall.getBrand().stringReplace( $.slatwall.getBrand().setting('brandMetaKeywordsString') ) );
						
					} else {
						
						throw("Slatwall has attempted to display a 'Brand' on your website, however the 'Brand Display Template' setting is either blank or invalid.  Please navigate to the Slatwall admin and make sure that there is a valid 'Brand Display Template' assigned.");
						
					}

				}
			}
		}
		
		public void function onRenderStart( required any $ ) {
			
			// Now that there is a mura contentBean in the muraScope for sure, we can setup our content Variable, but only if the current content node is new
			if($.slatwall.getContent().getNewFlag()) {
				var slatwallContent = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( $.content('contentID'), $.event('siteID') );
				
				if( !isNull(slatwallContent.getContentTemplateType()) && ((slatwallContent.getContentTemplateType().getSystemCode() eq "cttProduct" && $.slatwall.getProduct().getNewFlag()) ||
					(slatwallContent.getContentTemplateType().getSystemCode() eq "cttProductType" && $.slatwall.getProductType().getNewFlag()) ||
					(slatwallContent.getContentTemplateType().getSystemCode() eq "cttBrand" && $.slatwall.getBrand().getNewFlag())
					)) {
						
					$.event('contentBean', $.getBean("content"));
					$.event().getHandler('standard404').handle($.event());
					
				} else {
					$.slatwall.setContent( slatwallContent );
				}
			}
			
			// Check for any slatActions that might have been passed in and render that page as the first
			if(len($.event('slatAction')) && listFirst($.event('slatAction'), ":") == "frontend") {
				
				$.content('body', $.content('body') & $.slatwall.doAction($.event('slatAction')));	
				

			// If no slatAction was passed in, and we are in legacy mode... then check for keys in mura to determine what page to render
			} else if ( $.slatwall.setting('integrationMuraLegacyInjectFlag') ) {
				
				// Check to see if the current content is a listing page, so that we add our frontend view to the content body
				if(isBoolean($.slatwall.getContent().getProductListingPageFlag()) && $.slatwall.getContent().getProductListingPageFlag()) {
					$.content('body', $.content('body') & $.slatwall.doAction('frontend:product.listcontentproducts'));
				}
				
				// Render any of the 'special'  pages that might need to be rendered
				if(len($.slatwall.setting('integrationMuraLegacyShoppingCart')) && $.slatwall.setting('integrationMuraLegacyShoppingCart') == $.content('filename')) {
					$.content('body', $.content('body') & $.slatwall.doAction('frontend:cart.detail'));
				} else if(len($.slatwall.setting('integrationMuraLegacyOrderStatus')) && $.slatwall.setting('integrationMuraLegacyOrderStatus') == $.content('filename')) {
					$.content('body', $.content('body') & $.slatwall.doAction('frontend:order.detail'));
				} else if(len($.slatwall.setting('integrationMuraLegacyOrderConfirmation')) && $.slatwall.setting('integrationMuraLegacyOrderConfirmation') == $.content('filename')) {
					$.content('body', $.content('body') & $.slatwall.doAction('frontend:order.confirmation'));
				} else if(len($.slatwall.setting('integrationMuraLegacyMyAccount')) && $.slatwall.setting('integrationMuraLegacyMyAccount') == $.content('filename')) {
					// Checks for My-Account page
					if($.event('showitem') != ""){
						$.content('body', $.content('body') & $.slatwall.doAction('frontend:account.#$.event("showitem")#'));
					} else {
						$.content('body', $.content('body') & $.slatwall.doAction('frontend:account.detail'));
					}
				} else if(len($.slatwall.setting('integrationMuraLegacyCreateAccount')) && $.slatwall.setting('integrationMuraLegacyCreateAccount') == $.content('filename')) {
					$.content('body', $.content('body') & $.slatwall.doAction('frontend:account.create'));
				} else if(len($.slatwall.setting('integrationMuraLegacyCheckout')) && $.slatwall.setting('integrationMuraLegacyCheckout') == $.content('filename')) {
					$.content('body', $.content('body') & $.slatwall.doAction('frontend:checkout.detail'));
				}
			}
			
			
			var accessToContentDetails = $.slatwall.getService("accessService").getAccessToContentDetails( $.slatwall.getAccount(), $.slatwall.getContent() );
			
			// Pass all of the accessDetails into the slatwallScope to be used by templates
			$.slatwall.setValue('accessToContentDetails', accessToContentDetails);
			
			// DEPRECATED (pass in these additional values to slatwallScope so that legacy templates work)
			$.slatwall.setValue("purchasedAccess", accessToContentDetails.purchasedAccessFlag);
			$.slatwall.setValue("subscriptionAccess", accessToContentDetails.subscribedAccessFlag);
			
			// If the user does not have access to this page, then we need to modify the request
			if( !accessToContentDetails.accessFlag ){
				
				// DEPRECATED (save the current content to be used on the barrier page)
				$.event("restrictedContentBody", $.content('body'));
				// DEPRECATED (set slatwallContent in rc to be used on the barrier page)
				$.event("slatwallContent", $.slatwall.getContent());
				
				
				// save the restriced Slatwall content in the slatwallScope to be used on the barrier page
				$.slatwall.setValue('restrictedContent', $.slatwall.getContent());
				
				// save the restriced Mura content in the muraScope to be used on the barrier page
				$.event("restrictedContent", $.content());
				
				// get the barrier page template
				var barrierPage = $.slatwall.getService("contentService").getContent( $.slatwall.getContent().setting('contentRestrictedContentDisplayTemplate'), true );
				
				// Update the slatwall content to use the barrier page
				$.slatwall.setContent( barrierPage );
				
				// Update the mura content to use the barrier page or 404
				if(!isNull(barrierPage.getCMSContentID()) && len(barrierPage.getCMSContentID())) {
					$.event('contentBean', $.getBean("content").loadBy( contentID=barrierPage.getCMSContentID() ) );
				} else {
					$.event('contentBean', $.getBean("content") );
				}
			}
		}
		
		public void function onRenderEnd( required any $ ) {
			if($.slatwall.getLoggedInAsAdminFlag()) {
				// Set up frontend tools
				var fetools = "";
				/*
				savecontent variable="fetools" {
					include "/Slatwall/assets/fetools/fetools.cfm";
				};
				*/
				
				$.event('__muraresponse__', replace($.event('__muraresponse__'), '</body>', '#fetools#</body>'));
			}
		}
		
		public void function onSiteRequestEnd( required any $ ) {
			endSlatwallRequest();
		}
		
		public void function onSiteLoginSuccess( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			// Update Login / Logout if needed
			autoLoginLogoutFromSlatwall( $=$ );
			
			endSlatwallRequest();
		}
		
		public void function onAfterSiteLogout( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			// Update Login / Logout if needed
			autoLoginLogoutFromSlatwall( $=$ );
			
			endSlatwallRequest();
		}
		
		
		// ========================== ADMIN EVENT HOOKS =================================
		
		public void function onGlobalRequestStart( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			// Update Login / Logout if needed
			autoLoginLogoutFromSlatwall( $=$ );
			
			endSlatwallRequest();
		}
		
		// LOGIN / LOGOUT EVENTS
		public void function onGlobalLoginSuccess( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			// Update Login / Logout if needed
			autoLoginLogoutFromSlatwall( $=$ );
			
			endSlatwallRequest();
		}
		public void function onAfterGlobalLogout( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			// Update Login / Logout if needed
			autoLoginLogoutFromSlatwall( $=$ );
			
			endSlatwallRequest();
		}
		
		// RENDERING EVENTS
		
		public void function onContentEdit() {
			verifySlatwallRequest( $=request.muraScope );
			
			// Setup the mura scope
			var $ = request.muraScope;
			
			// Place Slatwall content entity in the slatwall scope
			$.slatwall.setContent( $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( $.content('contentID'), $.event('siteID') ) );
			if($.slatwall.getContent().isNew()) {
				$.slatwall.getContent().setParentContent( $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( $.event('parentID'), $.event('siteID') ) );
			}
			
			// if the site is null, then we can get it out of the request.muraScope
			if(isNull($.slatwall.getContent().getSite())) {
				$.slatwall.getContent().setSite( $.slatwall.getService("siteService").getSiteByCMSSiteID( request.muraScope.event('siteID') ));
			}
			
			include "../../views/muraevent/oncontentedit.cfm";
		}
		
		// SAVE / DELETE EVENTS ===== CATEGORY
		
		public void function onAfterCategorySave( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			var slatwallSite = $.slatwall.getService("siteService").getSiteByCMSSiteID($.event('siteID'));
			syncMuraCategories($=$, slatwallSite=slatwallSite, muraSiteID=$.event('siteID'));
			
			syncMuraContentCategoryAssignment( muraSiteID=$.event('siteID') );
			
			endSlatwallRequest();
		}
		
		public void function onAfterCategoryDelete( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			var slatwallCategory = $.slatwall.getService("contentService").getCategoryByCMSCategoryID($.event('categoryID'));
			if(!isNull(slatwallCategory)) {
				if(slatwallCategory.isDeletable()) {
					$.slatwall.getService("contentService").deleteCategory( slatwallCategory );
					ormFlush();
				} else {
					slatwallCategory.setActiveFlag(0);
				}	
			}
			
			syncMuraContentCategoryAssignment( muraSiteID=$.event('siteID') );
			
			endSlatwallRequest();
		}
		

		// SAVE / DELETE EVENTS ===== CONTENT
		
		public void function onAfterContentSave( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			var data = $.slatwall.getService("hibachiUtilityService").buildFormCollections( form , false );
			
			var slatwallSite = $.slatwall.getService("siteService").getSiteByCMSSiteID($.event('siteID'));
			syncMuraContent($=$, slatwallSite=slatwallSite, muraSiteID=$.event('siteID'));
			
			if(structKeyExists(data, "slatwallData") && structKeyExists(data.slatwallData, "content")) {
				
				var contentData = data.slatwallData.content;
				
				var muraContent = $.event('contentBean');
				var slatwallContent = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( muraContent.getContentID(), muraContent.getSiteID() );
				
				// Check to see if this content should have a parent
				if(muraContent.getParentID() != "00000000000000000000000000000000END") {
					var parentContent = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( muraContent.getParentID(), muraContent.getSiteID() );
					
					// If the parent has changed, we need to update all nested
					if(isNull(slatwallContent.getParentContent()) || parentContent.getContentID() != slatwallContent.getParentContent().getContentID()) {
						
						// Pull out the old IDPath so that we can update all nested nodes
						var oldContentIDPath = slatwallContent.getContentIDPath();
						
						// Setup the parentContent to the correct new one
						slatwallContent.setParentContent( parentContent );
						
						// Regenerate this content's ID Path
						slatwallContent.setContentIDPath( slatwallContent.buildIDPathList( 'parentContent' ) );
						
						// Update all nested content
						updateOldSlatwallContentIDPath(oldContentIDPath=oldContentIDPath, newContentIDPath=slatwallContent.getContentIDPath());
					}
				}
				
				// Populate Basic Values
				slatwallContent.setTitle( muraContent.getTitle() );
				slatwallContent.setSite( slatwallSite );
				if(structKeyExists(contentData, "productListingPageFlag") && isBoolean(contentData.productListingPageFlag)) {
					slatwallContent.setProductListingPageFlag( contentData.productListingPageFlag );	
				}
				if(structKeyExists(contentData, "allowPurchaseFlag") && isBoolean(contentData.allowPurchaseFlag)) {
					slatwallContent.setAllowPurchaseFlag( contentData.allowPurchaseFlag );
				}
				
				// Populate Template Type if it Exists
				if(structKeyExists(contentData, "contentTemplateType") && structKeyExists(contentData.contentTemplateType, "typeID") && len(contentData.contentTemplateType.typeID)) {
					var type = $.slatwall.getService("settingService").getType( contentData.contentTemplateType.typeID );
					slatwallContent.setContentTemplateType( type );
				} else {
					slatwallContent.setContentTemplateType( javaCast("null","") );
				}
				
				$.slatwall.getService("contentService").saveContent( slatwallContent );
				
				// Populate Setting Values
				param name="contentData.contentIncludeChildContentProductsFlag" default="";
				param name="contentData.contentRestrictAccessFlag" default="";
				param name="contentData.contentRestrictedContentDisplayTemplate" default="";
				param name="contentData.contentRequirePurchaseFlag" default="";
				param name="contentData.contentRequireSubscriptionFlag" default="";
				updateSlatwallContentSetting($=$, contentID=slatwallContent.getContentID(), settingName="contentIncludeChildContentProductsFlag", settingValue=contentData.contentIncludeChildContentProductsFlag);
				updateSlatwallContentSetting($=$, contentID=slatwallContent.getContentID(), settingName="contentRestrictAccessFlag", settingValue=contentData.contentRestrictAccessFlag);
				updateSlatwallContentSetting($=$, contentID=slatwallContent.getContentID(), settingName="contentRestrictedContentDisplayTemplate", settingValue=contentData.contentRestrictedContentDisplayTemplate);
				updateSlatwallContentSetting($=$, contentID=slatwallContent.getContentID(), settingName="contentRequirePurchaseFlag", settingValue=contentData.contentRequirePurchaseFlag);
				updateSlatwallContentSetting($=$, contentID=slatwallContent.getContentID(), settingName="contentRequireSubscriptionFlag", settingValue=contentData.contentRequireSubscriptionFlag);
				
				// Clear the settings cache (in the future this needs to be targeted)
				$.slatwall.getService("settingService").clearAllSettingsCache();
				
				// If the "Add Sku" was selected, then we call that process method
				if(structKeyExists(contentData, "addSku") && contentData.addSku && structKeyExists(contentData, "addSkuDetails")) {
					contentData.addSkuDetails.productCode = muraContent.getFilename();
					slatwallContent = $.slatwall.getService("contentService").processContent(slatwallContent, contentData.addSkuDetails, "createSku");
				}
			}
			
			// Sync all content category assignments
			syncMuraContentCategoryAssignment( muraSiteID=$.event('siteID') );
			
			endSlatwallRequest();
		}
		
		public void function onAfterContentDelete( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			var slatwallContent = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( $.event('contentID'), $.event('siteID') );
			if(!isNull(slatwallContent)) {
				if(slatwallContent.isDeletable()) {
					$.slatwall.getService("contentService").deleteContent( slatwallContent );
				} else {
					slatwallContent.setActiveFlag(0);
				}
			}
			
			// Sync all content category assignments
			syncMuraContentCategoryAssignment( muraSiteID=$.event('siteID') );
			
			endSlatwallRequest();
		}
		
		
		// SAVE / DELETE EVENTS ===== USER
		public void function onAfterUserSave( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			syncMuraAccounts($=$, accountSyncType=$.slatwall.setting('integrationMuraAccountSyncType'), superUserSyncFlag=$.slatwall.setting('integrationMuraSuperUserSyncFlag'), muraUserID=$.event('userID'));
			
			endSlatwallRequest();
		}
		
		public void function onAfterUserDelete( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			var slatwallAccount = $.slatwall.getService("accountService").getAccountByCMSAccountID( $.event('userID') );
			
			if(!isNull(slatwallAccount)) {
				
				// Delete account if we can
				if(slatwallAccount.isDeletable()) {
					$.slatwall.getService("accountService").deleteAccount( slatwallAccount );
					
				// Otherwise just remove the cmsAccountID & account authentication
				} else {
					
					slatwallAccount.setCMSAccountID( javaCase("null", "") );
					
					for(var i=arrayLen(account.getAccountAuthentications()); i>=1; i--) {
						if(!isNull(account.getAccountAuthentications()[i].getIntegration()) && account.getAccountAuthentications()[i].getIntegration().getIntegrationPackage() eq "mura") {
							$.slatwall.getService("accountService").deleteAccountAuthentication(account.getAccountAuthentications()[i]);
						}
					}
				}
			}
			
			endSlatwallRequest();
		}
		
		// ========================== MANUALLY CALLED MURA =================================
		
		public void function autoLoginLogoutFromSlatwall( required any $ ) {
			
			// Check to see if the current mura user is logged in (or logged out), and if we should automatically login/logout the slatwall account
			if( $.slatwall.setting("integrationMuraAccountSyncType") != "none"
					&& !$.slatwall.getLoggedInFlag()
					&& $.currentUser().isLoggedIn()
					&& (
						$.slatwall.setting("integrationMuraaccountSyncType") == "all"
						|| ($.slatwall.setting("integrationMuraAccountSyncType") == "systemUserOnly" && $.currentUser().getUserBean().getType() eq 2) 
						|| ($.slatwall.setting("integrationMuraAccountSyncType") == "siteUserOnly" && $.currentUser().getUserBean().getType() eq 1)
					)) {
				
				
				// Sync this account (even though it says all, it is just going to sync this single mura user)
				syncMuraAccounts( $=$, accountSyncType="all", superUserSyncFlag=$.slatwall.setting("integrationMuraSuperUserSyncFlag"), muraUserID=$.currentUser('userID'));
				
				// Login Slatwall Account
				var account = $.slatwall.getService("accountService").getAccountByCMSAccountID($.currentUser('userID'));
				var accountAuth = ormExecuteQuery("SELECT aa FROM SlatwallAccountAuthentication aa WHERE aa.integration.integrationID = ? AND aa.account.accountID = ?", [getMuraIntegrationID(), account.getAccountID()]);
				if (!isNull(account) && arrayLen(accountAuth)) {
					$.slatwall.getService("hibachiSessionService").loginAccount(account=account, accountAuthentication=accountAuth[1]);
				}
				
			} else if ( $.slatwall.getLoggedInFlag()
					&& !$.currentUser().isLoggedIn()
					&& !isNull($.slatwall.getSession().getAccountAuthentication())
					&& !isNull($.slatwall.getSession().getAccountAuthentication().getIntegration())
					&& $.slatwall.getSession().getAccountAuthentication().getIntegration().getIntegrationPackage() eq "mura") {
				
				// Logout Slatwall Account
				$.slatwall.getService("hibachiSessionService").logoutAccount();
			}
		}
		
		// This method is explicitly called during application reload from the conntector plugins onApplicationLoad() event
		public void function verifySetup( required any $ ) {
			verifySlatwallRequest( $=$ );
			
			var assignedSitesQuery = getMuraPluginConfig().getAssignedSites();
			var populatedSiteIDs = getMuraPluginConfig().getCustomSetting("populatedSiteIDs");
			
			var integration = $.slatwall.getService("integrationService").getIntegrationByIntegrationPackage("mura");
			if(!integration.getFW1ActiveFlag()) {
				integration.setFW1ActiveFlag(1);
				var ehArr = integration.getIntegrationCFC().getEventHandlers();
				for(var e=1; e<=arrayLen(ehArr); e++) {
					$.slatwall.getService("hibachiEventService").registerEventHandler(ehArr[e]);
				}
			}
			if(isNull(integration.getAuthenticationActiveFlag()) || !integration.getAuthenticationActiveFlag()) {
				integration.setAuthenticationActiveFlag(1);
			}
			
			// Flush the ORM Session
			$.slatwall.getDAO("hibachiDAO").flushORMSession();
			
			$.slatwall.getService("integrationService").clearActiveFW1Subsystems();
			
			// Sync all of the settings defined in the plugin with the integration
			syncMuraPluginSetting( $=$, settingName="accountSyncType", settingValue=getMuraPluginConfig().getSetting("accountSyncType") );
			syncMuraPluginSetting( $=$, settingName="createDefaultPages", settingValue=getMuraPluginConfig().getSetting("createDefaultPages") );
			syncMuraPluginSetting( $=$, settingName="superUserSyncFlag", settingValue=getMuraPluginConfig().getSetting("superUserSyncFlag") );
			
			// Clear the setting cache so that these new setting values get pulled in
			$.slatwall.getService("settingService").clearAllSettingsCache();
			
			for(var i=1; i<=assignedSitesQuery.recordCount; i++) {
				var cmsSiteID = assignedSitesQuery["siteid"][i];
				var siteDetails = $.getBean("settingsBean").loadBy(siteID=cmsSiteID);
				var cmsSiteName = siteDetails.getSite();
				var cmsThemeName = siteDetails.getTheme();
				
				// Check if this is a default site, and there is no setting defined for the globalAssetsImageFolderPath
				if(cmsSiteID == "default") {
					
					var assetSetting = $.slatwall.getService("settingService").getSettingBySettingName("globalAssetsImageFolderPath", true);
					if(assetSetting.isNew()) {
						assetSetting.setSettingValue( replace(expandPath('/muraWRM'), '\', '/', 'all') & '/default/assets/Image/Slatwall' );
						assetSetting.setSettingName('globalAssetsImageFolderPath');
						$.slatwall.getService("settingService").saveSetting( assetSetting );
					}
				}
				
				// First lets verify that this site exists on the Slatwall site
				var slatwallSite = $.slatwall.getService("siteService").getSiteByCMSSiteID( cmsSiteID, true );
				
				var slatwallSiteWasNew = slatwallSite.getNewFlag();
				
				// If this is a new site, then we can set the site name
				if(slatwallSiteWasNew) {
					slatwallSite.setSiteName( cmsSiteName );
					$.slatwall.getService("siteService").saveSite( slatwallSite );
					slatwallSite.setCMSSiteID( cmsSiteID );
					$.slatwall.getDAO("hibachiDAO").flushORMSession();
				}
				
				// If the plugin is set to create default pages, and this siteID has not been populated then we need to populate it with pages & templates
				if(getMuraPluginConfig().getSetting("createDefaultPages") && !listFindNoCase(populatedSiteIDs, cmsSiteID)) {
					
					// Copy views over to the template directory
					var slatwallTemplatePath = getDirectoryFromPath(expandPath("/Slatwall/public/views/templates")); 
					var muraTemplatePath = getDirectoryFromPath(expandPath("/muraWRM/#cmsSiteID#/includes/themes/#cmsThemeName#/templates"));
					$.slatwall.getService("hibachiUtilityService").duplicateDirectory(source=slatwallTemplatePath, destination=muraTemplatePath, overwrite=false, recurse=true, copyContentExclusionList=".svn,.git");
					
					// Create the necessary pages
					var templatePortalCMSID = createMuraPage( 		$=$, muraSiteID=cmsSiteID, pageName="Slatwall Templates", 		filename="slatwall-templates", 							template="", 							isNav="0", type="Folder", 	parentID="00000000000000000000000000000000001" );
					var brandTemplateCMSID = createMuraPage( 		$=$, muraSiteID=cmsSiteID, pageName="Brand Template", 			filename="slatwall-templates/brand-template", 			template="slatwall-brand.cfm", 			isNav="0", type="Page", 	parentID=templatePortalCMSID );
					var productTypeTemplateCMSID = createMuraPage( 	$=$, muraSiteID=cmsSiteID, pageName="Product Type Template", 	filename="slatwall-templates/product-type-template", 	template="slatwall-producttype.cfm", 	isNav="0", type="Page", 	parentID=templatePortalCMSID );
					var productTemplateCMSID = createMuraPage( 		$=$, muraSiteID=cmsSiteID, pageName="Product Template", 		filename="slatwall-templates/product-template", 		template="slatwall-product.cfm", 		isNav="0", type="Page", 	parentID=templatePortalCMSID );
					var accountCMSID = createMuraPage( 				$=$, muraSiteID=cmsSiteID, pageName="My Account", 				filename="my-account", 									template="slatwall-account.cfm", 		isNav="1", type="Page", 	parentID="00000000000000000000000000000000001" );
					var checkoutCMSID = createMuraPage( 			$=$, muraSiteID=cmsSiteID, pageName="Checkout", 				filename="checkout", 									template="slatwall-checkout.cfm", 		isNav="1", type="Page", 	parentID="00000000000000000000000000000000001" );
					var shoppingCartCMSID = createMuraPage( 		$=$, muraSiteID=cmsSiteID, pageName="Shopping Cart", 			filename="shopping-cart", 								template="slatwall-shoppingcart.cfm", 	isNav="1", type="Page", 	parentID="00000000000000000000000000000000001" );
					var productListingCMSID = createMuraPage(		$=$, muraSiteID=cmsSiteID, pageName="Product Listing", 			filename="product-listing", 							template="slatwall-productlisting.cfm", isNav="1", type="Page", 	parentID="00000000000000000000000000000000001" );
					
					// Sync all missing content for the siteID
					syncMuraContent( $=$, slatwallSite=slatwallSite, muraSiteID=cmsSiteID );
					
					// Update the correct settings on the slatwall side for some of the new content nodes
					var productListing = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( productListingCMSID, cmsSiteID );
					productListing.setProductListingPageFlag( true );
					
					var productTemplate = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( productTemplateCMSID, cmsSiteID );
					productTemplate.setContentTemplateType( $.slatwall.getService("settingService").getTypeBySystemCode("cttProduct") );
					
					var productTypeTemplate = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( productTypeTemplateCMSID, cmsSiteID );
					productTypeTemplate.setContentTemplateType( $.slatwall.getService("settingService").getTypeBySystemCode("cttProductType") );
					
					var brandTemplate = $.slatwall.getService("contentService").getContentByCMSContentIDAndCMSSiteID( brandTemplateCMSID, cmsSiteID );
					brandTemplate.setContentTemplateType( $.slatwall.getService("settingService").getTypeBySystemCode("cttBrand") );
					
					// If the site was new, then we can added default template settings for the site
					if(slatwallSiteWasNew) {
						var productTemplateSetting = $.slatwall.getService("settingService").newSetting();
						productTemplateSetting.setSettingName( 'productDisplayTemplate' );
						productTemplateSetting.setSettingValue( productTemplate.getContentID() );
						productTemplateSetting.setSite( slatwallSite );
						$.slatwall.getService("settingService").saveSetting( productTemplateSetting );
						
						var productTypeTemplateSetting = $.slatwall.getService("settingService").newSetting();
						productTypeTemplateSetting.setSettingName( 'productTypeDisplayTemplate' );
						productTypeTemplateSetting.setSettingValue( productTypeTemplate.getContentID() );
						productTypeTemplateSetting.setSite( slatwallSite );
						$.slatwall.getService("settingService").saveSetting( productTypeTemplateSetting );
						
						var brandTemplateSetting = $.slatwall.getService("settingService").newSetting();
						brandTemplateSetting.setSettingName( 'brandDisplayTemplate' );
						brandTemplateSetting.setSettingValue( brandTemplate.getContentID() );
						brandTemplateSetting.setSite( slatwallSite );
						$.slatwall.getService("settingService").saveSetting( brandTemplateSetting );
					}
					
					// Flush these changes to the content
					$.slatwall.getDAO("hibachiDAO").flushORMSession();
					
					// Now that it has been populated we can add the siteID to the populated site id's list
					getMuraPluginConfig().setCustomSetting("populatedSiteIDs", listAppend(populatedSiteIDs, cmsSiteID));
				}
				
				// Sync all missing content for the siteID
				syncMuraContent( $=$, slatwallSite=slatwallSite, muraSiteID=cmsSiteID );
				
				// Sync all missing categories
				syncMuraCategories( $=$, slatwallSite=slatwallSite, muraSiteID=cmsSiteID );
				
				// Sync all content category assignments
				syncMuraContentCategoryAssignment( muraSiteID=cmsSiteID );
				
				// Sync all missing accounts
				syncMuraAccounts( $=$, accountSyncType=getMuraPluginConfig().getSetting("accountSyncType"), superUserSyncFlag=getMuraPluginConfig().getSetting("superUserSyncFlag") );
				
				// Now that accounts are synced be sure to call the autoLoginLogout
				autoLoginLogoutFromSlatwall( $=$ );
			}
		}
		
	</cfscript>
	
	<!--- ==================== TAG BASED HELPER METHODS TYPICALLY FOR DB STUFF ==================== --->
	<cffunction name="createMuraPage">
		<cfargument name="$" />
		<cfargument name="muraSiteID" type="string" required="true" />
		<cfargument name="pageName" type="string" required="true" />
		<cfargument name="filename" type="string" required="true" />
		<cfargument name="template" type="string" required="true" />
		<cfargument name="isNav" type="numeric" required="true" />
		<cfargument name="type" type="string" required="true" />
		<cfargument name="parentID" type="string" required="true" />
		
		<cfset var thisPage = $.getBean("contentManager").getActiveContentByFilename(filename=arguments.filename, siteid=arguments.muraSiteID) />
		<cfif thisPage.getIsNew()>
			<cfset thisPage.setDisplayTitle(arguments.pageName) />
			<cfset thisPage.setHTMLTitle(arguments.pageName) />
			<cfset thisPage.setMenuTitle(arguments.pageName) />
			<cfset thisPage.setIsNav(arguments.isNav) />
			<cfset thisPage.setActive(1) />
			<cfset thisPage.setApproved(1) />
			<cfset thisPage.setIsLocked(0) />
			<cfset thisPage.setParentID(arguments.parentID) />
			<cfset thisPage.setFilename(arguments.filename) />
			<cfset thisPage.setType(arguments.type) />
			<cfif len(arguments.template)>
				<cfset thisPage.setTemplate(arguments.template) />
			</cfif>
			<cfset thisPage.setSiteID(arguments.muraSiteID) />
			<cfset thisPage.save() />
		</cfif>
		
		<cfreturn thisPage.getContentID() />
	</cffunction>

	<cffunction name="syncMuraContent">
		<cfargument name="$" />
		<cfargument name="slatwallSite" type="any" required="true" />
		<cfargument name="muraSiteID" type="string" required="true" />
		
		<cfset var parentMappingCache = {} />
		<cfset var missingContentQuery = "" />
		
		<cfquery name="missingContentQuery">
			SELECT
				tcontent.contentID,
				tcontent.parentID,
				tcontent.menuTitle
			FROM
				tcontent
			WHERE
				tcontent.active = <cfqueryparam cfsqltype="cf_sql_bit" value="1" />
			  AND
			  	tcontent.siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.muraSiteID#" />
			  AND
    			tcontent.path LIKE '00000000000000000000000000000000001%'
			  AND
				NOT EXISTS( SELECT contentID FROM SlatwallContent WHERE SlatwallContent.cmsContentID = tcontent.contentID AND SlatwallContent.siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.slatwallSite.getSiteID()#" /> )
			ORDER BY
				<cfif $.slatwall.getApplicationValue("databaseType") eq "MySQL">
					LENGTH( tcontent.path )
				<cfelse>
					LEN( tcontent.path )
				</cfif>
		</cfquery>
		
		<cfset var allParentsFound = true />
		<cfloop query="missingContentQuery">
			
			<cfset var rs = "" />
			
			<!--- Creating Home Page --->
			<cfif missingContentQuery.parentID eq "00000000000000000000000000000000END">
				<cfset var newContentID = $.slatwall.createHibachiUUID() />
				<cfquery name="rs">
					INSERT INTO SlatwallContent (
						contentID,
						contentIDPath,
						activeFlag,
						siteID,
						cmsContentID,
						title,
						allowPurchaseFlag,
						productListingPageFlag
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#newContentID#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#newContentID#" />,
						<cfqueryparam cfsqltype="cf_sql_bit" value="1" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.slatwallSite.getSiteID()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingContentQuery.contentID#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingContentQuery.menuTitle#" />,
						<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
						<cfqueryparam cfsqltype="cf_sql_bit" value="0" />
					)
				</cfquery>
			<!--- Creating Internal Page, or resetting if parent can't be found --->	
			<cfelse>
				
				<cfif not structKeyExists(parentMappingCache, missingContentQuery.parentID)>
					<cfset var parentContentQuery = "" />
					<cfquery name="parentContentQuery">
						SELECT contentID, contentIDPath FROM SlatwallContent WHERE SlatwallContent.cmsContentID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingContentQuery.parentID#" /> AND SlatwallContent.siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.slatwallSite.getSiteID()#" />  
					</cfquery>
					<cfif parentContentQuery.recordCount>
						<cfset parentMappingCache[ missingContentQuery.parentID ] = {} />
						<cfset parentMappingCache[ missingContentQuery.parentID ].contentID = parentContentQuery.contentID />
						<cfset parentMappingCache[ missingContentQuery.parentID ].contentIDPath = parentContentQuery.contentIDPath />
					</cfif>
				</cfif>
				
				<cfif structKeyExists(parentMappingCache,  missingContentQuery.parentID)>
					<cfset var newContentID = $.slatwall.createHibachiUUID() />
					<cfquery name="rs">
						INSERT INTO SlatwallContent (
							contentID,
							contentIDPath,
							parentContentID,
							activeFlag,
							siteID,
							cmsContentID,
							title,
							allowPurchaseFlag,
							productListingPageFlag
						) VALUES (
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#newContentID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#parentMappingCache[ missingContentQuery.parentID ].contentIDPath#,#newContentID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#parentMappingCache[ missingContentQuery.parentID ].contentID#" />,
							<cfqueryparam cfsqltype="cf_sql_bit" value="1" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.slatwallSite.getSiteID()#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingContentQuery.contentID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingContentQuery.menuTitle#" />,
							<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
							<cfqueryparam cfsqltype="cf_sql_bit" value="0" />
						)
					</cfquery>
				<cfelse>
					<cfset allParentsFound = false />
				</cfif>
			</cfif>
		</cfloop>
		
		<!--- Move Recursively through the entire site tree --->
		<cfif !allParentsFound>
			<cfset syncMuraContent(argumentcollection=arguments) />
		</cfif>
	</cffunction>
	
	<cffunction name="updateOldSlatwallContentIDPath">
		<cfargument name="oldContentIDPath" type="string" default="" />
		<cfargument name="newContentIDPath" type="string" default="" />
		
		<cfset var rs = "" />
		<cfset var rs2 = "" />
		
		<!--- Select any content that is a desendent of the old contentIDPath, and update them to the new path --->
		<cfquery name="rs">
			SELECT
				contentID,
				contentIDPath
			FROM
				SlatwallContent
			WHERE
				contentIDPath <> <cfqueryparam cfsqltype="cf_sql_varchar" value="#oldContentIDPath#" />
			  AND
				contentIDPath LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#oldContentIDPath#%" />
		</cfquery>
		
		<cfloop query="rs">
			<cfquery name="rs2">
				UPDATE
					SlatwallContent
				SET
					contentIDPath = <cfqueryparam cfsqltype="cf_sql_varchar" value="#replace(rs.contentIDPath, arguments.oldContentIDPath, arguments.newContentIDPath)#">
				WHERE
					contentID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#rs.contentID#">
			</cfquery>
		</cfloop>
		
	</cffunction>
	
	<cffunction name="syncMuraCategories">
		<cfargument name="$" />
		<cfargument name="slatwallSite" type="any" required="true" />
		<cfargument name="muraSiteID" type="string" required="true" />
		
		<cfset var parentMappingCache = {} />
		<cfset var missingCategoryQuery = "" />
		
		<cfif $.slatwall.getApplicationValue("databaseType") eq "MySQL">
			<cfquery name="missingCategoryQuery">
				SELECT
					tcontentcategories.categoryID,
					tcontentcategories.parentID,
					tcontentcategories.name
				FROM
					tcontentcategories
				WHERE
					NOT EXISTS( SELECT categoryID FROM SlatwallCategory WHERE SlatwallCategory.cmsCategoryID = tcontentcategories.categoryID )
				ORDER BY
					LENGTH(tcontentcategories.path)
			</cfquery>
		<cfelse>
			<cfquery name="missingCategoryQuery">
				SELECT
					tcontentcategories.categoryID,
					tcontentcategories.parentID,
					tcontentcategories.name
				FROM
					tcontentcategories
				WHERE
					NOT EXISTS( SELECT categoryID FROM SlatwallCategory WHERE SlatwallCategory.cmsCategoryID = tcontentcategories.categoryID )
				ORDER BY
					LEN(tcontentcategories.path)
			</cfquery>
		</cfif>
		
		<cfset var allParentsFound = true />
		<cfloop query="missingCategoryQuery">
			
			<cfset var rs = "" />
			
			<!--- Creating Home Page --->
			<cfif !len(missingCategoryQuery.parentID)>
				<cfset var newCategoryID = $.slatwall.createHibachiUUID() />
				<cfquery name="rs">
					INSERT INTO SlatwallCategory (
						categoryID,
						categoryIDPath,
						siteID,
						cmsCategoryID,
						categoryName
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#newCategoryID#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#newCategoryID#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.slatwallSite.getSiteID()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingCategoryQuery.categoryID#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingCategoryQuery.name#" />
					)
				</cfquery>
			<!--- Creating Internal Page, or resetting if parent can't be found --->	
			<cfelse>
				
				<cfif not structKeyExists(parentMappingCache, missingCategoryQuery.parentID)>
					<cfset var parentCategoryQuery = "" />
					<cfquery name="parentCategoryQuery">
						SELECT categoryID, categoryIDPath FROM SlatwallCategory WHERE cmsCategoryID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingCategoryQuery.parentID#" /> 
					</cfquery>
					<cfif parentCategoryQuery.recordCount>
						<cfset parentMappingCache[ missingCategoryQuery.parentID ] = {} />
						<cfset parentMappingCache[ missingCategoryQuery.parentID ].categoryID = parentCategoryQuery.categoryID />
						<cfset parentMappingCache[ missingCategoryQuery.parentID ].categoryIDPath = parentCategoryQuery.categoryIDPath />
					</cfif>
				</cfif>
				
				<cfif structKeyExists(parentMappingCache,  missingCategoryQuery.parentID)>
					<cfset var newCategoryID = $.slatwall.createHibachiUUID() />
					<cfquery name="rs">
						INSERT INTO SlatwallCategory (
							categoryID,
							categoryIDPath,
							parentCategoryID,
							siteID,
							cmsCategoryID,
							categoryName
						) VALUES (
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#newCategoryID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#parentMappingCache[ missingCategoryQuery.parentID ].categoryIDPath#,#newCategoryID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#parentMappingCache[ missingCategoryQuery.parentID ].categoryID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.slatwallSite.getSiteID()#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingCategoryQuery.categoryID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingCategoryQuery.name#" />
						)
					</cfquery>
				<cfelse>
					<cfset allParentsFound = false />
				</cfif>
			</cfif>
		</cfloop>
		
		<!--- Move Recursively through the entire site tree --->
		<cfif !allParentsFound>
			<cfset syncMuraCategories(argumentcollection=arguments) />
		</cfif>
	</cffunction>
	
	<cffunction name="syncMuraContentCategoryAssignment">
		<cfargument name="muraSiteID" type="string" required="true" />
		
		<cfset var allMissingAssignments = "" />
		<cfset var rs = "" />
		
		<!--- Get the missing assingments --->
		<cfquery name="allMissingAssignments">
			SELECT
				SlatwallContent.contentID,
				SlatwallCategory.categoryID
			FROM
				tcontentcategoryassign
			  INNER JOIN
			  	SlatwallContent on tcontentcategoryassign.contentID = SlatwallContent.cmsContentID
			  INNER JOIN
			  	SlatwallCategory on tcontentcategoryassign.categoryID = SlatwallCategory.cmsCategoryID
			WHERE
				tcontentcategoryassign.siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#muraSiteID#" />
			  AND
			  	NOT EXISTS(
				  	SELECT
				  		SlatwallContentCategory.contentID
				  	FROM
				  		SlatwallContentCategory
				  	  INNER JOIN
				  	  	SlatwallContent on SlatwallContentCategory.contentID = SlatwallContent.contentID
				  	  INNER JOIN
				  	  	SlatwallCategory on SlatwallContentCategory.categoryID = SlatwallCategory.categoryID
				  	WHERE
				  		SlatwallContent.cmsContentID = tcontentcategoryassign.contentID
				  	  AND
				  	  	SlatwallCategory.cmsCategoryID = tcontentcategoryassign.categoryID
			  	)
		</cfquery>
		
		<!--- Loop over missing assignments --->
		<cfloop query="allMissingAssignments">
			<cfquery name="rs">
				INSERT INTO SlatwallContentCategory (
					contentID,
					categoryID
				) VALUES (
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#allMissingAssignments.contentID#" />,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#allMissingAssignments.categoryID#" />
				)
			</cfquery>
		</cfloop>
			
		<!--- Delete unneeded assignments --->
		<cfquery name="rs">
			DELETE FROM
				SlatwallContentCategory
			WHERE
				NOT EXISTS(
					SELECT
						tcontentcategoryassign.contentID
					FROM
						tcontentcategoryassign
					  INNER JOIN
					  	SlatwallContent on tcontentcategoryassign.contentID = SlatwallContent.cmsContentID
					  INNER JOIN
					  	SlatwallCategory on tcontentcategoryassign.categoryID = SlatwallCategory.cmsCategoryID
					WHERE
						SlatwallContentCategory.contentID = SlatwallContent.contentID
					  AND
					  	SlatwallContentCategory.categoryID = SlatwallCategory.categoryID
			  	)
		</cfquery>
	</cffunction>
	
	<cffunction name="syncMuraAccounts">
		<cfargument name="$" />
		<cfargument name="accountSyncType" type="string" required="true" />
		<cfargument name="superUserSyncFlag" type="boolean" required="true" />
		<cfargument name="muraUserID" type="string" />
		
		<cfif arguments.accountSyncType neq "none">
			
			<cfset var missingUsersQuery = "" />
			
			<cfquery name="missingUsersQuery">
				SELECT
					UserID,
					S2,
					Fname,
					Lname,
					Email,
					Company,
					MobilePhone,
					isPublic
				FROM
					tusers
				WHERE
					tusers.type = <cfqueryparam cfsqltype="cf_sql_integer" value="2" />
				<cfif arguments.accountSyncType eq "systemUserOnly">
					AND tusers.isPublic = <cfqueryparam cfsqltype="cf_sql_integer" value="0" /> 
				<cfelseif arguments.accountSyncType eq "siteUserOnly">
					AND tusers.isPublic = <cfqueryparam cfsqltype="cf_sql_integer" value="1" />
				</cfif>
				
				<cfif structKeyExists(arguments, "muraUserID") and len(arguments.muraUserID)>
					AND tusers.userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.muraUserID#" />
				<cfelse>
					AND NOT EXISTS( SELECT cmsAccountID FROM SlatwallAccount WHERE SlatwallAccount.cmsAccountID = tusers.userID )
				</cfif>
			</cfquery>
			
			<!--- Loop over all accounts to sync --->
			<cfloop query="missingUsersQuery">
				
				<cfset var slatwallAccountID = "" />
				<cfset var primaryEmailAddressID = "" />
				<cfset var primaryPhoneNumberID = "" />
				
				<cfset var rs = "" />
				<cfset var rs2 = "" />
				
				<cfquery name="rs">
					SELECT
						SlatwallAccount.accountID,
						(SELECT SlatwallAccountAuthentication.accountAuthenticationID FROM SlatwallAccountAuthentication WHERE SlatwallAccountAuthentication.accountID = SlatwallAccount.accountID AND SlatwallAccountAuthentication.integrationID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#getMuraIntegrationID()#" />) as 'accountAuthenticationID'
					FROM
						SlatwallAccount
					WHERE
						SlatwallAccount.cmsAccountID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.UserID#" />
				</cfquery>
				
				<cfif rs.recordCount>
					<cfset slatwallAccountID = rs.accountID />
				<cfelse>
					
					<cfset slatwallAccountID = $.slatwall.createHibachiUUID() />
					
					<!--- Create Account --->
					<cfquery name="rs2">
						INSERT INTO SlatwallAccount (
							accountID,
							firstName,
							lastName,
							company,
							cmsAccountID,
							superUserFlag
						) VALUES (
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#slatwallAccountID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Fname#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Lname#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Company#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.UserID#" />,
							<cfif arguments.superUserSyncFlag and missingUsersQuery.s2>
								<cfqueryparam cfsqltype="cf_sql_bit" value="1" />	
							<cfelse>
								<cfqueryparam cfsqltype="cf_sql_bit" value="0" />
							</cfif>
						)
					</cfquery>
					
				</cfif>
				
				<!--- Insert Account Auth if Needed --->
				<cfif not rs.recordCount or (rs.recordCount and not len(rs.accountAuthenticationID))>
					
					<!--- Create Authentication --->
					<cfquery name="rs2">
						INSERT INTO SlatwallAccountAuthentication (
							accountAuthenticationID,
							accountID,
							integrationID,
							integrationAccessToken,
							integrationAccountID
						) VALUES (
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#$.slatwall.createHibachiUUID()#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#slatwallAccountID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#getMuraIntegrationID()#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.UserID#" />,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.UserID#" />
						)
					</cfquery>
					
				</cfif> 
				
				<!--- Check / Create Email --->
				<cfif len(missingUsersQuery.Email)>
					<cfquery name="rs">
						SELECT
							accountEmailAddressID,
							accountID
						FROM
							SlatwallAccountEmailAddress
						WHERE
							emailAddress = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Email#" />
						  AND
						  	EXISTS ( SELECT SlatwallAccountAuthentication.accountAuthenticationID FROM SlatwallAccountAuthentication WHERE SlatwallAccountAuthentication.accountID = SlatwallAccountEmailAddress.accountID)
					</cfquery>
					
					<cfif rs.recordCount and rs.accountID eq slatwallAccountID>
						
						<cfset primaryEmailAddressID = rs.accountEmailAddressID />
						
					<cfelseif not rs.recordCount>
						
						<cfset primaryEmailAddressID = $.slatwall.createHibachiUUID() />
						
						<cfquery name="rs2">
							INSERT INTO SlatwallAccountEmailAddress (
								accountEmailAddressID,
								accountID,
								emailAddress
							) VALUES (
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#primaryEmailAddressID#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#slatwallAccountID#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Email#" />
							)
						</cfquery>
						
					</cfif>
				</cfif>
				
				<!--- Check / Create Phone --->
				<cfif len(missingUsersQuery.MobilePhone)>
					<cfquery name="rs">
						SELECT
							accountPhoneNumberID,
							accountID
						FROM
							SlatwallAccountPhoneNumber
						WHERE
							phoneNumber = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.MobilePhone#" />
						  AND
						  	EXISTS ( SELECT SlatwallAccountAuthentication.accountAuthenticationID FROM SlatwallAccountAuthentication WHERE SlatwallAccountAuthentication.accountID = SlatwallAccountPhoneNumber.accountID)
					</cfquery>
					
					<cfif rs.recordCount and rs.accountID eq slatwallAccountID>
						
						<cfset primaryPhoneNumberID = rs.accountPhoneNumberID />
						
					<cfelseif not rs.recordCount>
						
						<cfset primaryPhoneNumberID = $.slatwall.createHibachiUUID() />
						
						<cfquery name="rs2">
							INSERT INTO SlatwallAccountPhoneNumber (
								accountPhoneNumberID,
								accountID,
								phoneNumber
							) VALUES (
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#primaryPhoneNumberID#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#slatwallAccountID#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.MobilePhone#" />
							)
						</cfquery>
						
					</cfif>
				</cfif>
				
				<!--- Update Account --->
				<cfquery name="rs2">
					UPDATE
						SlatwallAccount
					SET
						firstName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Fname#" />
						,lastName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Lname#" />
						,company = <cfqueryparam cfsqltype="cf_sql_varchar" value="#missingUsersQuery.Company#" />
						<cfif len(primaryEmailAddressID)>
							,primaryEmailAddressID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#primaryEmailAddressID#" />
						</cfif>
						<cfif len(primaryPhoneNumberID)>
							,primaryPhoneNumberID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#primaryPhoneNumberID#" />
						</cfif>
						<cfif arguments.superUserSyncFlag and missingUsersQuery.s2>
							,superUserFlag = <cfqueryparam cfsqltype="cf_sql_bit" value="1" />	
						<cfelse>
							,superUserFlag = <cfqueryparam cfsqltype="cf_sql_bit" value="0" />
						</cfif>
					WHERE
						accountID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#slatwallAccountID#" />
				</cfquery>
				
			</cfloop>
		</cfif>
	</cffunction>
	
	<cffunction name="updateSlatwallContentSetting">
		<cfargument name="$" required="true" />
		<cfargument name="contentID" required="true" />
		<cfargument name="settingName" required="true" />
		<cfargument name="settingValue" default="" />
		
		<cfset var rs = "" />
		<cfset var rsResult = "" />
		
		<cfif len(arguments.settingValue)>
			<cfquery name="rs" result="rsResult">
				UPDATE
					SlatwallSetting
				SET
					settingValue = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.settingValue#" />
				WHERE
					contentID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentID#" /> AND settingName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.settingName#" />
			</cfquery>
			<cfif not rsResult.recordCount>
				<cfquery name="rs">
					INSERT INTO SlatwallSetting (
						settingID,
						settingValue,
						settingName,
						contentID
					) VALUES (
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#$.slatwall.createHibachiUUID()#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.settingValue#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.settingName#" />,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentID#" />
					)
				</cfquery>
			</cfif>
		<cfelse>
			<cfquery name="rs">
				DELETE FROM SlatwallSetting WHERE contentID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.contentID#" /> AND settingName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.settingName#" />
			</cfquery>
		</cfif> 
	</cffunction>
	
	<cffunction name="syncMuraPluginSetting">
		<cfargument name="$" />
		<cfargument name="settingName" />
		<cfargument name="settingValue" />
		
		<cfset var rs = "" />
		<cfset var rs2 = "" />
		
		<cfquery name="rs">
			SELECT settingID, settingValue FROM SlatwallSetting WHERE settingName = <cfqueryparam cfsqltype="cf_sql_varchar" value="integrationMura#arguments.settingName#" />
		</cfquery>
		
		<cfif rs.recordCount>
			<cfquery name="rs2">
				UPDATE SlatwallSetting SET settingValue = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.settingValue#" /> WHERE settingID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#rs.settingID#" /> 
			</cfquery>
		<cfelse>
			<cfquery name="rs2">
				INSERT INTO SlatwallSetting (
					settingID,
					settingName,
					settingValue
				) VALUES (
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#$.slatwall.createHibachiUUID()#" />,
					 <cfqueryparam cfsqltype="cf_sql_varchar" value="integrationMura#arguments.settingName#" />,
					 <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.settingValue#" />
				) 
			</cfquery>
		</cfif>

	</cffunction>
</cfcomponent>
