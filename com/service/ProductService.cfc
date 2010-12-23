component extends="slat.com.service.BaseService" accessors="true" {
	
	property name="skuDAO" type="any";
	property name="contentManager" type="any";
	property name="settingsManager" type="any";
	
	public this function init(required any entityName, required any dao, required any skuDAO, required any contentManager, required any settingsManager) {
		setEntityName(arguments.entityName);
		setDAO(arguments.DAO);
		setSkuDAO(arguments.skuDAO);
		setContentManager(arguments.contentManager);
		setSettingsManager(arguments.settingsManager);
		
		return this;
	}
	
	public slat.com.entity.SmartList function getSmartList(required struct rc){
		var smartList = createObject("component","slat.com.entity.SmartList").init(entityName=getEntityName(), rc=arguments.rc);
		
		smartList.addKeywordColumn("productCode", 1);
		smartList.addKeywordColumn("productName", 1);
		smartList.addKeywordColumn("productDescription", 1);
		smartList.addKeywordColumn("brand_brandID", 1);
		smartList.addKeywordColumn("brand_brandName", 1);
		
		return getDAO().fillSmartList(smartList=smartList, entityName=getEntityName());	
	}
	
	public any function getProductTemplates() {
		return getSettingsManager().getSite(session.siteid).getTemplates();
	}
}