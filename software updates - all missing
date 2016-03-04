declare @AuthListLocalID as int
select @AuthListLocalID=CI_ID from v_AuthListInfo
   
SELECT DISTINCT
rs.NetBios_Name0 AS Name,
case
 when os.Caption0 like '%2003%' then '2003'
 when os.Caption0 like '%2008 R2%' then '2008 R2'
 when os.Caption0 like '%2008%' then '2008'
 when os.Caption0 like '%2012 R2%' then '2012 R2'
 when os.Caption0 like '%2012%' then '2012'
 else 'Other'
end as Osys,
case
 when cs.Roles0 like '%Domain_Controller%' then 'DC'
 when rs.Distinguished_Name0 like '%DC=company,DC=net%' then 'company.net'
 when rs.Resource_Domain_OR_Workgr0 like '%domain%' then 'domain'
 else 'Other'
end as Role,
case
 when os.CSDVersion0 like '%1%' then '1'
 when os.CSDVersion0 like '%2%' then '2'
 when os.CSDVersion0 like '%3%' then '3'
 when os.CSDVersion0 like '%4%' then '4'
 when os.CSDVersion0 like '%5%' then '5'
end as SP,
ucsa.ResourceID,
ui.BulletinID,
ui.ArticleID,
ui.Title,
ui.Description,
ui.DateRevised,
    CASE ui.Severity
      WHEN 10 THEN 'Critical'
      WHEN 8 THEN 'Important'
      WHEN 6 THEN 'Moderate'
      WHEN 2 THEN 'Low'
      Else '(Unknown)'
END AS [Severity]
FROM v_UpdateComplianceStatus ucsa
INNER JOIN v_CIRelation cir ON ucsa.CI_ID = cir.ToCIID
INNER JOIN v_UpdateInfo ui ON ucsa.CI_ID = ui.CI_ID
JOIN v_R_System rs ON ucsa.ResourceID = rs.ResourceID
left JOIN dbo.v_GS_COMPUTER_SYSTEM CS on rs.ResourceID = CS.ResourceID
JOIN v_GS_OPERATING_SYSTEM AS os ON ucsa.ResourceID = os.ResourceID
WHERE
cir.RelationType=1
AND
ucsa.ResourceID in (Select vc.ResourceID FROM v_FullCollectionMembership vc WHERE vc.CollectionID = @CollID)
AND
ucsa.Status = '2' --Required
