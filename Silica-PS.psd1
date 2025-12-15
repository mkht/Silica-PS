@{
    # Version number of this module.
    ModuleVersion        = '0.0.1'

    # Supported PSEditions
    CompatiblePSEditions = 'Desktop'

    # ID used to uniquely identify this module
    GUID                 = 'f79da113-5544-4960-94c3-21cdf5e13978'

    # Author of this module
    Author               = 'mkht'

    # Script module or binary module file associated with this manifest.
    RootModule           = 'Silica-PS.psm1'

    # Company or vendor of this module
    CompanyName          = ''

    # Copyright statement for this module
    Copyright            = '(c) 2025 mkht. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'Read/Write Felica cards.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '7.4'

    NestedModules        = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies   = @(
        'Libs\FelicaLibCs.dll'
    )

    # Functions to export from this module
    FunctionsToExport    = @(
        'Get-FelicaCard',
        'Read-FelicaBlock',
        'Write-FelicaBlock',
        'Set-SilicaIDm',
        'Set-SilicaSystemCode',
        'Set-SilicaServiceCode'
    )

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    TypesToProcess       = @()

    # Format files (.ps1xml) to be loaded when importing this module.
    FormatsToProcess     = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
}
