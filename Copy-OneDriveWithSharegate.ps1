[CmdletBinding()]
param (
    [Parameter (Mandatory = $true, ParameterSetName = "Username", Position = 0)]
    [Parameter (Mandatory = $true, ParameterSetName = "Credential", Position = 0)]
    [string] $CSVFile,

    [Parameter (Mandatory = $true, ParameterSetName = "Username")]
    [string] $SourceSpoAdminUpn,

    [Parameter (Mandatory = $true, ParameterSetName = "Username")]
    [string] $DestinationSpoAdminUpn,

    [Parameter (Mandatory = $true, ParameterSetName = "Credential")]
    [System.Management.Automation.PSCredential] $SourceCredential,

    [Parameter (Mandatory = $true, ParameterSetName = "Credential")]
    [System.Management.Automation.PSCredential] $DestinationCredential,

    [Parameter (Mandatory = $true, ParameterSetName = "Username")]
    [Parameter (Mandatory = $true, ParameterSetName = "Credential")]
    [string] $SourceTenant,

    [Parameter (Mandatory = $true, ParameterSetName = "Username")]
    [Parameter (Mandatory = $true, ParameterSetName = "Credential")]
    [string] $DestinationTenant,

    [Parameter (Mandatory = $false, ParameterSetName = "Username")]
    [Parameter (Mandatory = $false, ParameterSetName = "Credential")]
    [bool] $IsSiteCollectionAdminOnSource = $true,

    [Parameter (Mandatory = $false, ParameterSetName = "Username")]
    [Parameter (Mandatory = $false, ParameterSetName = "Credential")]
    [bool] $IsSiteCollectionAdminOnDestination = $true
)

#------------------------------------------------[Function]-------------------------------------------------------

function New-LogFile {
    param (
        [Parameter(Mandatory = $true)]
        [String] $Path,

        [Parameter(Mandatory = $true)]
        [String] $FileName,

        [Parameter(Mandatory = $false)]
        [String] $TimeStamp,

        [Parameter(Mandatory = $false)]
        [String] $Key
    )

    if (!(Test-Path -Path $Path)) { New-Item -Path $Path -ItemType Directory -Force }
    if ($TimeStamp -eq "") {
        $PathLogFile = $Path + $(Get-Date -Format "yyyyMMdd-HHmmss") + "_$FileName.log"
    }
    else {
        if ($Key -ne "") {
            $PathLogFile = $Path + $TimeStamp + "_" + $FileName + "_" + $Key + ".log"
        }
        else {
            $PathLogFile = $Path + $TimeStamp + "_$FileName.log"
        }
    }
    return $PathLogFile
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$LogMessage,

        [Parameter(Mandatory = $true)]
        [String]$LogFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info", "Ok", "Failed", "Success")][String]$LogLevel
    )

    $arr = @()

    # Set Date/Time
    $dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $arr += $dateTime
    # Set log level
    switch ($LogLevel) {
        'Error' {
            $arr += 'ERROR    '
        }
        'Warn' {
            $arr += 'WARN     '
        }
        'Info' {
            $arr += 'INFO     '
        }
        'Ok' {
            $arr += 'OK       '
        }
        'Failed' {
            $arr += 'FAILED   '
        }
        'Success' {
            $arr += 'SUCCESS  '
        }
        Default {
            $arr += '         '
        }
    } # switch: Set log level

    # Set message
    $arr += $LogMessage

    # Build line from array
    $line = [System.String]::Join(" ", $arr)

    # Write to log
    if ($LogFile -ne "") { $line | Out-File -FilePath $LogFile -Append }

    # Write to host
    Write-Host $line
}

function Add-SpoAdminAsSca {
    param(
        [Parameter (Mandatory = $true)]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter(Mandatory = $true)]
        [String] $Tenant,

        [Parameter(Mandatory = $true)]
        [ValidateSet("source", "destination")] [String] $Target,

        [Parameter(Mandatory = $true)]
        [String] $LogFile
    )

    Write-Log "Add service account to each personal OD4B storage to the $Target." -LogFile $LogFile -LogLevel Info

    # Connect to SPO Service
    try {
        Connect-SPOService -Url https://$Tenant-admin.sharepoint.com -Credential $Credential
        Write-Log "Connection to $Target tenant is done." -LogFile $LogFile
    }
    catch {
        Write-Log "Connection to $Target tenant was not successful!" -LogFile $LogFile -LogLevel Error
        return $false
    }
    
    foreach ($item in $table) {
        try {
            switch ($Target) {
                "source" { Set-SPOUser -Site $item.SourceSite -LoginName $Credential.UserName -IsSiteCollectionAdmin $true }
                "destination" { Set-SPOUser -Site $item.DestinationSite -LoginName $Credential.UserName -IsSiteCollectionAdmin $true }
            }
            
        }
        catch {
            Write-Log "SPO Admin not added as SCA: $($item.SourceSite)" -LogFile $LogFile -LogLevel Error
        }
    }
    Disconnect-SPOService
    Write-Log "Add SPO Admin as SCA is completed." -LogFile $LogFile -LogLevel Success

    return $true
}

#----------------------------------------------[Declarations]-----------------------------------------------------

Import-Module Sharegate

# Get root folder and the name of the script
$rootFolder = Get-Location
$scriptName = $MyInvocation.MyCommand.Name

# Log file in script folder
$logPath = $rootFolder.Path + "\"
$logFileName = $scriptName.Split(".")[0]
$logFile = New-LogFile -Path $logPath -FileName $logFileName

#------------------------------------------------[Execution]------------------------------------------------------

Write-Log "*** Start PowerShell script $scriptName ***" -LogFile $logFile

# Read CSV File
if (Test-Path -Path $CSVFile) {
    $table = Import-Csv $CSVFile -Delimiter ","
    Write-Log "Reading file '$CSVFile' completed. $($table.Count) lines are detected." -LogFile $logFile
}
else {
    # CSV file is not available
    Write-Log "Didn't find the csv file: $CSVFile" -LogFile $logFile -LogLevel Error
    Write-Log "*** Stop PowerShell script $scriptName ***" -LogFile $logFile
    exit
}

# if credential not sent as paramater
if ($PsCmdlet.ParameterSetName -ne "Credential") {
    $SourceCredential = Get-Credential -Message "SharePoint Online Administrator source tenant" -UserName $SourceSpoAdminUpn
    $DestinationCredential = Get-Credential -Message "SharePoint Online Administrator source tenant" -UserName $DestinationSpoAdminUpn
}

# Service account must be added to each OneDrive storage in the source
if (!$IsSiteCollectionAdminOnSource) {
    # This is required to copy the content from the source
    $success = Add-SpoAdminAsSca -Credential $SourceCredential -Tenant $SourceTenant -Target source -LogFile $logFile
    if (!$success) {
        Write-Log "*** Stop PowerShell script $scriptName ***" -LogFile $logFile
        exit
    }
}

if (!$IsSiteCollectionAdminOnDestination) {
    # This is required to copy the content to the destination
    $success = Add-SpoAdminAsSca -Credential $DestinationCredential -Tenant $DestinationTenant -Target destination -LogFile $logFile
    if (!$success) {
        Write-Log "*** Stop PowerShell script $scriptName ***" -LogFile $logFile
        exit
    }
}

# Migration with ShareGate
if (!(Test-Path $rootFolder\MyReports)) {
    $directory = New-Item -Path $rootFolder -Name MyReports -ItemType Directory
    Write-Log "Directory ist created to copy reports: $rootFolder\$($directory.Name)" -LogFile $logFile
}
Write-Log "Migration with Sharegate ..." -LogFile $logFile
Set-Variable srcSite, dstSite, srcList, dstList
foreach ($row in $table) {
    try {
        Write-Log "Source:       $($row.SourceSite)" -LogFile $logFile -LogLevel Info
        Write-Log "Desrtination: $($row.DestinationSite)" -LogFile $logFile -LogLevel Info
        Clear-Variable srcSite
        Clear-Variable dstSite
        Clear-Variable srcList
        Clear-Variable dstList

        $srcSite = Connect-Site -Url $row.SourceSite -Credential $SourceCredential
        Write-Log "Connected to source." -LogFile $logFile
        $dstSite = Connect-Site -Url $row.DestinationSite -Credential $DestinationCredential
        Write-Log "Connected to destination." -LogFile $logFile
        $srcList = Get-List -Site $srcSite -Name "Documents"
        $dstList = Get-List -Site $dstSite -Name "Documents"
        if (($null -eq $srcList) -or ($null -eq $dstList)) {
            # Not all targets are loaded
            Write-Log "Source and / or destination is not loaded correctly!" -LogFile $logFile -LogLevel Error
            Write-Log "Continue with next line ..." -LogFile $logFile -LogLevel Warn
            continue
        }
        Write-Log "Start Copy with ShareGate ..." -LogFile $logFile -LogLevel Ok
        $time = Measure-Command {
            $result = Copy-Content -SourceList $srcList -DestinationList $dstList
        }
        Write-Log "Total time to migrate this personal site: $($time.TotalSeconds) seconds" -LogFile $logFile -LogLevel Ok
        $reportFile = "$rootFolder\MyReports\$($srcSite.Title).xlsx"
        try {
            Export-Report $result -Path $reportFile
            Write-Log "Report file is exported." -LogFile $logFile
        }
        catch {
            Write-Log "Report is not exported!" -LogFile $logFile -LogLevel Warn
        }
        try {
            Remove-SiteCollectionAdministrator -Site $srcSite
        }
        catch {
            Write-Log "Service account not removed as SCA from source!" -LogFile $logFile -LogLevel Error
        }
        try {
            Remove-SiteCollectionAdministrator -Site $dstSite
        }
        catch {
            Write-Log "Service account not removed as SCA from destination!" -LogFile $logFile -LogLevel Error
        }
    }
    catch {
        Write-Log "Copy content with ShareGate was running into an issue!!!" -LogFile $logFile -LogLevel Failed
    }
}

Write-Log "*** Stop PowerShell script $scriptName ***" -LogFile $logFile