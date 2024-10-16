function Invoke-JdbcHandler {
    <#
    .SYNOPSIS
        Handles imports from JDCB sources.
    .DESCRIPTION
        This function acts as a "controller" of the flow for imports from a JDCB source, for example a CSV file.

        This function is responsible for importing the modules necessary for reading data from the source and applying the settings specified in the Easit GO ImportClient configuration and / or source coonfiguration.

        General flow:

        * Import JDBC dependency module
        * Convert ImportClient configuration (ConvertFrom-ReliqueJdbcCsvCsvDriver).
        * Read data from source
        * Update data with settings provided via combineSourceAttributes.
        * Return source data.
    .PARAMETER SourceDirectory
        Path to directory where module for handling JDBC configuration exist.
    .PARAMETER ImportClientConfiguration
        ImportClient configuration object (From Easit GO or custom).
    .PARAMETER ConfigurationSourceSettings
        Source configuration settings.
    .EXAMPLE
        if ($importClientConfiguration.ConfigurationType -eq 'jdbcConfiguration') {
            $ijhParams = @{
                SourceDirectory = $srcDirectory
                ImportClientConfiguration = $importClientConfiguration
                ConfigurationSourceSettings = $source
            }
            try {
                $sourceObjects = Invoke-JdbcHandler @ijhParams
            } catch {
                Write-Error $_
                continue
            }
        }
    .INPUTS
        [System.String](https://learn.microsoft.com/en-us/dotnet/api/system.string)

        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        [System.Collections.ArrayList](https://learn.microsoft.com/en-us/dotnet/api/system.collections.arraylist)
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/invokejdbchandler/')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory)]
        [String]$SourceDirectory,
        [Parameter(Mandatory)]
        [PSCustomObject]$ImportClientConfiguration,
        [Parameter(Mandatory)]
        [PSCustomObject]$ConfigurationSourceSettings
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    process {
        $modulePath = Join-Path -Path $SourceDirectory -ChildPath $psImportClientSettings.dependencyModules.jdbcConfiguration
        $highestModuleVersion = Get-ChildItem -Path $modulePath -Directory | Sort-Object -Property 'Name' -Descending -Top 1
        $moduleFile = Get-ChildItem -Path $highestModuleVersion -Recurse -Include '*.psm1'
        try {
            Import-Module $moduleFile.FullName -Force -Global -ErrorAction Stop
        } catch {
            Write-CustomLog -Message "Failed to import dependency modules for jdbcConfiguration" -Level WARN
            Write-CustomLog -InputObject $_ -Level ERROR
            throw
        }
        if ($ImportClientConfiguration.DriverClassName -eq 'org.relique.jdbc.csv.CsvDriver') {
            try {
                $sourceSettingsObject = ConvertFrom-ReliqueJdbcCsvCsvDriver -ImportClientConfiguration $ImportClientConfiguration -ErrorAction Stop
                $ImportClientConfiguration | Add-Member -MemberType NoteProperty -Name 'UpdateArchive' -Value $false -Force
                $ImportClientConfiguration | Add-Member -MemberType NoteProperty -Name 'SourceSettingsObject' -Value $sourceSettingsObject -Force
            } catch {
                # Warn and errors are logged by ConvertFrom-ReliqueJdbcCsvCsvDriver
                throw
            }
        } else {
            throw "Unknown DriverClassName: $($ImportClientConfiguration.DriverClassName)"
        }
        try {
            $returnObjects = [System.Collections.ArrayList]::new()
            $sourcebjects = Import-FromCsvSource -SourceSettings $sourceSettingsObject -ErrorAction Stop
        } catch {
            # Warn and errors are logged by Import-FromCsvSource
            throw
        }
        if ($sourcebjects.Count -eq 1) {
            [void]$returnObjects.Add($sourcebjects)
        }
        if ($sourcebjects.Count -gt 1) {
            [void]$returnObjects.AddRange($sourcebjects)
        }
        Write-CustomLog -Message "Got $($returnObjects.Count) object(s) from source"
        if ($ConfigurationSourceSettings.combineSourceAttributes.enabled -eq 'true') {
            Write-CustomLog -Message "combineSourceAttributes.enabled = $($ConfigurationSourceSettings.combineSourceAttributes.enabled), updating objects with combines" -Level VERBOSE
            $counter = 1
            foreach ($returnObject in $returnObjects) {
                Write-CustomLog -Message "Updating object $counter of $($returnObjects.Count)" -Level DEBUG
                $counter++
                foreach ($combine in $ConfigurationSourceSettings.combineSourceAttributes.combines) {
                    if (Get-Member -InputObject $returnObject -Name "$($combine.combineAttributeOutputName)" -ErrorAction SilentlyContinue) {
                        Write-CustomLog -Message "Object already have a property named $($combine.combineAttributeOutputName)" -Level WARN
                    } else {
                        try {
                            Add-NewCombineProperty -InputObject $returnObject -Combine $combine
                        } catch {
                            Write-CustomLog -Message "Failed to combine $($combine.attributes[0]) and $($combine.attributes[1]) to $($combine.combineAttributeOutputName)" -Level WARN
                            Write-CustomLog -InputObject $_ -Level ERROR
                            continue
                        }
                    }
                }
            }
            Write-CustomLog -Message "All objects updated" -Level DEBUG
        }
        return $returnObjects
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}