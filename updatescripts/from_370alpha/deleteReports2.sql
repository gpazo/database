DELETE FROM report 
WHERE report_name IN (
'BacklogByCustomerType',
'BacklogByProductCategory',
'BacklogByWarehouse',
'BacklogByParameterList',
'BacklogByCustomer',
'BacklogByItemNumber',
'BacklogBySalesOrder',
'ItemSitesByClassCode',
'ItemSitesByCostCategory',
'ItemSitesByPlannerCode',
'ItemSitesByWarehouse',
'ItemSitesByItem',
'ItemSitesByParameterList',
'CustomersByCustomerType',
'CustomersByCharacteristic') 
AND report_grade=0;