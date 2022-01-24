# od4b.migration-sharegate

![Version]
![Language]

PowerShell script to copy content of the personal storage of OneDrive for Business from one tenant to the other one.

## Table of contents

- [od4b.migration-sharegate](#od4bmigration-sharegate)
  - [Table of contents](#table-of-contents)
  - [Copy-OneDriveWithSharegate](#copy-onedrivewithsharegate)
    - [Command](#command)
    - [Description](#description)
    - [Example](#example)
    - [Parameters](#parameters)
      - [CSVFile `<String>`](#csvfile-string)
      - [SourceSpoAdminUpn `<String>`](#sourcespoadminupn-string)
      - [DestinationSpoAdminUpn `<String>`](#destinationspoadminupn-string)
      - [SourceCredential  `<PSCredential>`](#sourcecredential--pscredential)
      - [DestinationCredential  `<PSCredential>`](#destinationcredential--pscredential)
      - [SourceTenant `<String>`](#sourcetenant-string)
      - [DestinationTenant `<String>`](#destinationtenant-string)
      - [IsSiteCollectionAdminOnSource `<bool>`](#issitecollectionadminonsource-bool)
      - [IsSiteCollectionAdminOnDestination `<bool>`](#issitecollectionadminondestination-bool)
  - [Release History](#release-history)
  - [Versioning](#versioning)
  - [Authors](#authors)
  - [Articles](#articles)
  - [Tools](#tools)

## Copy-OneDriveWithSharegate

This PowerShell script will automate the migration of OneDrive for Business storage to a different tenant. The migration tool which will be used for this setup is **ShareGate**. The template of this script is the documentation published by ShareGate: [Walkthrough - Migrate OneDrive for Business to OneDrive for Business in PowerShell](https://support-desktop.sharegate.com/hc/en-us/articles/115000473134-Walkthrough-Migrate-OneDrive-for-Business-to-OneDrive-for-Business-in-PowerShell).

Please also check the ShareGate documentation because of Insane mode top copy data which is default by using PowerShell: [Insane mode FAQ](https://support-desktop.sharegate.com/hc/en-us/articles/115005752568-Insane-mode-FAQ).

A service account with *SharePoint Online Administrator* role in Microsoft 365 is needed. The service account will be added as Site Collection Admin (SCA) to the personal storage in the source and in the destination. After the files are copied the service account will be removed as SCA.

### Command

``` PowerShell
Copy-OneDriveWithSharegate
```

### Description

This PowerShell script will copy the content of a personal storage of OD4B to a separate OD4B storage of a different tenant.

### Example

Copy content with a list of personal storages from one tenant to the other one. The credentials of source and target (SharePoint Online administrator) will be provided as parameter and the admin must first be added as Site Collection Administrator to source and target. At the end all SharePoint admin accounts will be removed from the personal storages.

``` PowerShell
Copy-OneDriveWithSharegate -CSVFile Sharegate.csv -SourceCredential $srcCred -DestinationCredential $dstCred -SourceTenant 'tenant1' -DestinationTenant 'tenant2' -IsSiteCollectionAdminOnSource $false -IsSiteCollectionAdminOnDestination $false
```

### Parameters

#### CSVFile `<String>`

Include the path to the CSV-file which include the matching of OD4B url of the source with the target tenant.

The CSV-file must looks like this:

```
SourceSite,DestinationSite
https://tenant1-my.sharepoint.com/personal/alias1_tenant1_onmicrosoft_com,https://tenant2-my.sharepoint.com/personal/alias1_tenant2_onmicrosoft_com
```

Description | Value
-- | --
Required? | `$true`
Default value | `None`


#### SourceSpoAdminUpn `<String>`

The upn of the SharePoint Online Administrator of the source tenant. This parameter is mandotory when you are not using the parameter `SourceCredential`.

Description | Value
-- | --
Required? | `$true`
Default value | `None`

#### DestinationSpoAdminUpn `<String>`

The upn of the SharePoint Online Administrator of the destination tenant. This parameter is mandotory when you are not using the parameter `DestinationCredential`.

Description | Value
-- | --
Required? | `$true`
Default value | `None`

#### SourceCredential  `<PSCredential>`

Credential of the SharePoint Online Administrator of the source tenant. This parameter is mandotory when you are not using the parameter `SourceSpoAdminUpn`.

Description | Value
-- | --
Required? | `$true`
Default value | `None`

#### DestinationCredential  `<PSCredential>`

Credential of the SharePoint Online Administrator of the destination tenant. This parameter is mandotory when you are not using the parameter `DestinationSpoAdminUpn`.

Description | Value
-- | --
Required? | `$true`
Default value | `None`

#### SourceTenant `<String>`

The tenant of the source `https://<tenant>.sharepoint.com`.

Description | Value
-- | --
Required? | `$true`
Default value | `None`

#### DestinationTenant `<String>`

The tenant of the destination `https://<tenant>.sharepoint.com`.

Description | Value
-- | --
Required? | `$true`
Default value | `None`

#### IsSiteCollectionAdminOnSource `<bool>`

Parameter is needed to add the SharePoint Online Administrator to all sources. If this is already done the parmater must be set to `$false`.

Description | Value
-- | --
Required? | `$false`
Default value | `$true`

#### IsSiteCollectionAdminOnDestination `<bool>`

Parameter is needed to add the SharePoint Online Administrator to all destinations. If this is already done the parmater must be set to `$false`.

Description | Value
-- | --
Required? | `$false`
Default value | `$true`


## Release History

Please read [release-notes.md](https://bitbucket.biscrum.com/projects/SPO/repos/bi-cs-o365.sharepoint-online.department_migration/browse/release-notes.md) for details on getting them.

## Versioning

We use SemVer for versioning.

## Authors

Stefan Gericke - *Initial work* - <stefan@gericke.name>


## Articles

- ShareGate: [Walkthrough - Migrate OneDrive for Business to OneDrive for Business in PowerShell](https://support-desktop.sharegate.com/hc/en-us/articles/115000473134-Walkthrough-Migrate-OneDrive-for-Business-to-OneDrive-for-Business-in-PowerShell).
- ShareGate: [Insane mode FAQ](https://support-desktop.sharegate.com/hc/en-us/articles/115005752568-Insane-mode-FAQ)

## Tools

- Visual Studio Code
- Windows PowerShell 5.1
- ShareGate

<!-- Shields -->
[Version]: https://img.shields.io/github/v/release/gerickes/od4b.migration-sharegate
[Language]: https://img.shields.io/badge/Language-PowerShell-green?logo=powershell