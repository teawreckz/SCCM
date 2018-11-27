#Parameters
$SQL_Server = '<your SCCM SQL server>'
$Database ='<your SCCM Database>'
$Server_Collection = '<your server collection ID>'
$Workstation_Collection = '<your workstation collection ID>'

#Clients queries
$sqlCmd = "
DECLARE @date DATETIME;
SELECT @date = DATEADD([hh], -12, GETDATE());
SELECT
       (
       SELECT @date
       ) AS date,
       (
       SELECT COUNT(DISTINCT [ResourceID]) AS [cmg_updates_scan]
              FROM [v_updatescanstatus]
              WHERE [LastScanTime] > @date
                    AND 
              [LastScanPackageLocation] LIKE '%cmg%'
              GROUP BY [LastScanPackageLocation]
       ) AS [cmg_updates_scan],
       (
       SELECT COUNT(DISTINCT [Name]) [cmg_clients]
              FROM [v_CombinedDeviceResources]
              WHERE [CNIsOnInternet] = 1
                    AND [CNIsOnline] = 1
                    AND [CNAccessMP] LIKE '%cmg%'
       ) AS [cmg_clients],
       (
       SELECT COUNT(DISTINCT [Name]) [MP_Clients]
              FROM [v_CombinedDeviceResources]
              WHERE [CNIsOnInternet] = 0
                    AND [CNIsOnline] = 1
       ) AS [MP_Clients];
"
try {
    $result = Invoke-Sqlcmd $sqlCmd  -server $SQL_Server -Database $Database
}
catch {
    return $false
}
foreach ($row in $result){
    $body='Clients CMG_Updates_Scan='+$row.cmg_updates_scan+',CMG_Clients='+$row.cmg_clients+',MP_Clients='+$row.mp_clients
    write-host $body
}
$sqlCmd1 = "
DECLARE @UserSIDs VARCHAR(16)= 'disabled';
SELECT [SYS].[Client_Version0] Client_Version,
        --[SYS].[Client_Type0],
        COUNT(*) AS 'Count'
        FROM [fn_rbac_R_System](@UserSIDs) AS [SYS]
            LEFT JOIN [fn_rbac_FullCollectionMembership](@UserSIDs) [coll] ON [coll].[ResourceID] = [sys].[ResourceID]
        WHERE [SYS].[Client0] = 1
                AND [coll].[CollectionID] = '$Server_Collection'
        GROUP BY [SYS].[Client_Version0],
                [SYS].[Client_Type0]
ORDER BY [SYS].[Client_Version0],
            [SYS].[Client_Type0]
"
try {
    $result = Invoke-Sqlcmd $sqlCmd1 -server $SQL_Server -Database $Database
}
catch {
    return $false
}
$sqlCmd2 = "
DECLARE @UserSIDs VARCHAR(16)= 'disabled';
SELECT [SYS].[Client_Version0] Client_Version,
        --[SYS].[Client_Type0],
        COUNT(*) AS 'Count'
        FROM [fn_rbac_R_System](@UserSIDs) AS [SYS]
            LEFT JOIN [fn_rbac_FullCollectionMembership](@UserSIDs) [coll] ON [coll].[ResourceID] = [sys].[ResourceID]
        WHERE [SYS].[Client0] = 1
                AND [coll].[CollectionID] = '$Workstation_Collection'
        GROUP BY [SYS].[Client_Version0],
                [SYS].[Client_Type0]
ORDER BY [SYS].[Client_Version0],
            [SYS].[Client_Type0]
"
try {
    $result2 = Invoke-Sqlcmd $sqlCmd2 -server $SQL_Server -Database $Database
}
catch {
    return $false
}
foreach ($row in $result){
    $cv=$row.client_version
    $c=$row.count
    $time=get-date -Format filedatetime
    $body="Servers,ClientVersion="+$cv+" Count="+$c
    write-host $body.trim()
}
foreach ($row in $result2){
    $cv=$row.client_version
    $c=$row.count
    $time=get-date -Format filedatetime
    $body="Workstations,ClientVersion="+$cv+" Count="+$c
    write-host $body.trim()
}
$sqlCmd = "
SELECT CASE
           WHEN [a].[operatingSystem0] LIKE '%Windows 10%'
           THEN 'Windows10'
           WHEN [a].[operatingSystem0] LIKE '%Windows 7%'
           THEN 'Windows7'
           WHEN [a].[operatingSystem0] LIKE '%Windows 8.1%'
           THEN 'Windows8_1'
           WHEN [a].[operatingSystem0] LIKE '%Windows 8%'
           THEN 'Windows8'
           WHEN [a].[operatingSystem0] LIKE '%Windows Vista%'
           THEN 'WindowsVista'
           WHEN [a].[operatingSystem0] LIKE '%Windows xp%'
           THEN 'WindowsXP'
       END AS [OS],
       iif([C].[Value] is null,0,[C].[Value]) AS [Build],
       COUNT(DISTINCT [A].[Name0]) AS [count]
       FROM [v_R_System] [A]
            LEFT OUTER JOIN [vSMS_WindowsServicingStates] [B] ON [B].[Build] = [A].[Build01]
                                                                 AND (([B].[Branch] = [A].[OSBranch01])
                                                                      OR ([A].[OSBranch01] = ''
                                                                          AND [B].[Branch] = 0))
            LEFT OUTER JOIN [vSMS_WindowsServicingLocalizedNames] [C] ON [B].[Name] = [C].[Name]
       WHERE [a].[operatingSystem0] IS NOT NULL
             AND [a].[operatingSystem0] NOT LIKE '%server%'
             AND [a].[operatingSystem0] LIKE '%windows%'
       GROUP BY CASE
                    WHEN [a].[operatingSystem0] LIKE '%Windows 10%'
                    THEN 'Windows10'
                    WHEN [a].[operatingSystem0] LIKE '%Windows 7%'
                    THEN 'Windows7'
                    WHEN [a].[operatingSystem0] LIKE '%Windows 8.1%'
                    THEN 'Windows8_1'
                    WHEN [a].[operatingSystem0] LIKE '%Windows 8%'
                    THEN 'Windows8'
                    WHEN [a].[operatingSystem0] LIKE '%Windows Vista%'
                    THEN 'WindowsVista'
                    WHEN [a].[operatingSystem0] LIKE '%Windows xp%'
                    THEN 'WindowsXP'
                END,
                [c].[Value]
"
try {
    $result = Invoke-Sqlcmd $sqlCmd -server $SQL_Server -Database $Database
}
catch {
    return $false
}
foreach ($row in $result){
    $body=$row.OS+',Build=_'+$row.build+' Count='+$row.count
    write-host $body
}
$sqlCmd = "
SELECT distinct
--[a].[operatingSystem0],
 CASE
           WHEN [a].[operatingSystem0] LIKE '%2008 R2%'
           THEN '2008R2'
           WHEN [a].[operatingSystem0] LIKE '%2008%'
           THEN '2008'
           WHEN [a].[operatingSystem0] LIKE '%2003%'
           THEN '2003'
           WHEN [a].[operatingSystem0] LIKE '%2012 R2%'
           THEN '2012_R2'
           WHEN [a].[operatingSystem0] LIKE '%2012%'
           THEN '2012'
           WHEN [a].[operatingSystem0] LIKE '%2016%'
           THEN '2016'
		   WHEN [a].[operatingSystem0] LIKE '%2019%'
           THEN '2019'
       END AS [OS],
       --iif([C].[Value] is null,0,[C].[Value]) AS [Build],
       COUNT(DISTINCT [A].[Name0]) AS [count]
       FROM [v_R_System] [A]
            LEFT OUTER JOIN [vSMS_WindowsServicingStates] [B] ON [B].[Build] = [A].[Build01]
                                                                 AND (([B].[Branch] = [A].[OSBranch01])
                                                                      OR ([A].[OSBranch01] = ''
                                                                          AND [B].[Branch] = 0))
            LEFT OUTER JOIN [vSMS_WindowsServicingLocalizedNames] [C] ON [B].[Name] = [C].[Name]
       WHERE [a].[operatingSystem0] IS NOT NULL
             AND [a].[operatingSystem0] LIKE '%server %'
group by
 CASE
           WHEN [a].[operatingSystem0] LIKE '%2008 R2%'
           THEN '2008R2'
           WHEN [a].[operatingSystem0] LIKE '%2008%'
           THEN '2008'
           WHEN [a].[operatingSystem0] LIKE '%2003%'
           THEN '2003'
           WHEN [a].[operatingSystem0] LIKE '%2012 R2%'
           THEN '2012_R2'
           WHEN [a].[operatingSystem0] LIKE '%2012%'
           THEN '2012'
           WHEN [a].[operatingSystem0] LIKE '%2016%'
           THEN '2016'
		   WHEN [a].[operatingSystem0] LIKE '%2019%'
           THEN '2019'
       END--,[C].[Value]
"
try {
    $result = Invoke-Sqlcmd $sqlCmd -server $SQL_Server -Database $Database
}
catch {
    return $false
}
foreach ($row in $result){
    $body='Servers,Server=_'+$row.OS+' Count='+$row.count
    write-host $body
}
$sqlCmd = "
SELECT UPPER(SUBSTRING([PSD].[ServerNALPath], 13, CHARINDEX('.', [PSd].[ServerNALPath])-13)) AS [DP_Name],
       COUNT(CASE
                 WHEN [PSD].State NOT IN('0', '3', '6')
                 THEN '*'
             END) AS 'Not_Installed',
       COUNT(CASE
                 WHEN [PSD].State IN('3', '6')
                 THEN '*'
             END) AS 'Error',
       (CASE
            WHEN [PSD].State = '0'
            THEN '1'--'OK' 
            WHEN [PSD].State NOT IN('0', '3', '6')
            THEN '2'--'In_Progress'
            WHEN [PSD].State IN('3', '6')
            THEN '3'--'Error'
        END) AS 'Status'
INTO [#tmp_st]
       FROM [$Database].[dbo].[v_PackageStatusDistPointsSumm] [psd],
            [$Database].[dbo].[SMSPackages] [P]
       WHERE [p].[PackageType] != 4
             AND ([p].[PkgID] = [psd].[PackageID])
       GROUP BY [PSd].[ServerNALPath],
                [PSD].State;
SELECT 
       SUM([d].[Not_Installed]) [PKG_Not_Installed],
       SUM([d].[error]) [PKG_Error],
       (
       SELECT COUNT([dp_name])
              FROM [#tmp_st]
              WHERE [status] = '1'
       ) [DP_OK],
       (
       SELECT COUNT([dp_name])
              FROM [#tmp_st]
              WHERE [status] = '2'
       ) [DP_In_Progress],
       (
       SELECT COUNT([dp_name])
              FROM [#tmp_st]
              WHERE [status] = '3'
       ) [DP_Error]
       FROM [#tmp_st] [d];
DROP TABLE [#tmp_st];
"
try {
    $result = Invoke-Sqlcmd $sqlCmd  -server $SQL_Server -Database $Database
}
catch {
    return $false
}
foreach ($row in $result){
    $body='DistributionPoints DP_OK='+$row.DP_OK+',PKG_Not_Installed='+$row.PKG_Not_Installed+',PKG_Error='+$row.PKG_Error+',DP_In_Progress='+$row.DP_In_Progress+',DP_Error='+$row.DP_Error
    write-host $body
}

##distribution
$sqlCmd = "
DECLARE @StartDate DATE;
SET @StartDate = DATEADD([d], -7, GETDATE());
DECLARE @EndDate DATE;
SET @EndDate = GETDATE();
WITH ClientDownloadHist
     AS (
     SELECT [his].[ID],
            [his].[ClientId],
            [his].[StartTime],
            [his].[BytesDownloaded],
            [his].[ContentID],
            [his].[DistributionPointType],
            [his].[DownloadType],
            [his].[HostName],
            [his].[BoundaryGroup]
            FROM [v_ClientDownloadHistoryDP_BG] [his]
            WHERE [his].[DownloadType] = 0
                  AND [his].[StartTime] >= @StartDate
                  AND ([his].[StartTime] >= @StartDate
                       AND [his].[StartTime] <= @EndDate)),
     ClientsDownloadBytes
     AS (
     SELECT [BoundaryGroup],
            ISNULL(SUM([x].[SpBytes]), 0) AS [PeerCacheBytes],
            ISNULL(SUM([x].[DpBytes]), 0) AS [DistributionPointBytes],
            ISNULL(SUM([x].[CloudDpBytes]), 0) AS [CloudDistributionPointBytes],
            ISNULL(SUM([x].[BranchCacheBytes]), 0) AS [BranchCacheBytes],
            ISNULL(SUM([x].[TotalBytes]), 0) AS [TotalBytes]
            FROM
                 (
                 SELECT [BoundaryGroup],
                        [DistributionPointType],
                        [SpBytes] = ISNULL(SUM(IIF([DistributionPointType] = 3, [BytesDownloaded], 0)), 0),
                        [DpBytes] = ISNULL(SUM(IIF([DistributionPointType] = 4, [BytesDownloaded], 0)), 0),
                        [BranchCacheBytes] = ISNULL(SUM(IIF([DistributionPointType] = 5, [BytesDownloaded], 0)), 0),
                        [CloudDpBytes] = ISNULL(SUM(IIF([DistributionPointType] = 1, [BytesDownloaded], 0)), 0),
                        [TotalBytes] = SUM([BytesDownloaded])
                        FROM [ClientDownloadHist]
                        GROUP BY [BoundaryGroup],
                                 [DistributionPointType]
                 ) AS [x]
            GROUP BY [BoundaryGroup]),
     Peers([BoundaryGroup],
           [PeerClientCount])
     AS (
     SELECT [his].[BoundaryGroup],
            COUNT(DISTINCT([ResourceID]))
            FROM [v_SuperPeers] [sp]
                 JOIN [ClientDownloadHist] [his] ON [his].[ClientId] = [sp].[ResourceID]
            GROUP BY [his].[BoundaryGroup]),
     DistPoints([BoundaryGroup],
                [CloudDPCount],
                [DPCount])
     AS (
     SELECT [bgs].[GroupId],
            SUM(IIF([sysres].[NALResType] = 'Windows Azure', 1, 0)),
            SUM(IIF([sysres].[NALResType] <> 'Windows Azure', 1, 0))
            FROM [vSMS_SC_SysResUse] [sysres]
                 JOIN [vSMS_BoundaryGroupSiteSystems] [bgs] ON [bgs].[ServerNALPath] = [sysres].[NALPath]
            WHERE [RoleTypeID] = 3
            GROUP BY [bgs].[GroupId])
     SELECT --[bg].[Name] AS [BoundaryGroupName],
     sum(ISNULL([cdb].[BranchCacheBytes], 0))/1073741824 AS [BranchCache_GB],
     sum(ISNULL([cdb].[CloudDistributionPointBytes], 0))/1073741824 AS [CloudDP_GB],
     sum(ISNULL([cdb].[DistributionPointBytes], 0))/1073741824 AS [DP_GB],
     sum(ISNULL([cdb].[PeerCacheBytes], 0))/1073741824 AS [PeerCache_GB]
            FROM [BoundaryGroup] [bg]
                 LEFT JOIN [Peers] AS [p] ON [p].[BoundaryGroup] = [bg].[GroupID]
                 LEFT JOIN [DistPoints] AS [dp] ON [dp].[BoundaryGroup] = [bg].[GroupID]
                 LEFT JOIN [ClientsDownloadBytes] AS [cdb] ON [cdb].[BoundaryGroup] = [bg].[GroupID]
            WHERE [cdb].[TotalBytes] > 0
			and [bg].[Name] not like '%servers%'
"
try {
    $result = Invoke-Sqlcmd $sqlCmd  -server $SQL_Server -Database $Database
}
catch {
    return $false
}
foreach ($row in $result){
    $body='Content_WKS '+'BranchCache='+$row.BranchCache_GB+',CloudDP='+$row.CloudDP_GB +',DP='+$row.DP_GB+',PeerCache='+$row.PeerCache_GB
    write-host $body
}
