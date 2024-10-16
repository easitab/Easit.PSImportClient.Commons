function Get-Configuration {
    <#
    .SYNOPSIS
        Reads the content from configuration file(s) and returns as array of configuration objects.
    .DESCRIPTION
        The *Get-Configuration* function gets the contents of one or more configuration file, validates it against a schema and returns the content as a PSCustomObejct in an array.

        If a path to a directory is supplied via the **PsImportClientDirectory** parameter all configuration files in that is read, validated and returned as an array of PSCustomObejcts.

        If NO input is supplied via the **PsImportClientDirectory** parameter, the configuration files provided via the **ConfigurationFile** parameter is read, validated and returned as an array of PSCustomObejcts.

        If no configurations are found, the function returns an empty array.
    .PARAMETER PsImportClientDirectory
        Path to directory where the directory *configurations* lives.
    .PARAMETER ConfigurationFile
        Full path to one or more configuration files.
    .EXAMPLE
        Get-Configuration

        In this example no input is provided and we will get back an empty array.
    .EXAMPLE
        Get-Configuration -PsImportClientDirectory "Path\To\PSImportClient"

        In this example we supply a custom directory which contains a directory called configurations. All configuration files will be returned as an array.
    .EXAMPLE
        Get-Configuration -ConfigurationFile "Path\To\ConfigurationFile1.json", "Path\To\ConfigurationFile2.json"

        In this example we specify what configuration we would like to be returned in the array.
    .INPUTS
        [System.String](https://learn.microsoft.com/en-us/dotnet/api/system.string)

        [String[]](https://learn.microsoft.com/en-us/dotnet/api/system.array)
    .OUTPUTS
        [System.Array](https://learn.microsoft.com/en-us/dotnet/api/system.array)
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/getconfiguration/')]
    [OutputType([System.Array])]
    param (
        [Parameter()]
        [String]$PsImportClientDirectory,
        [Parameter()]
        [String[]]$ConfigurationFile
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    process {
        if (([String]::IsNullOrEmpty($PsImportClientDirectory)) -and ([String]::IsNullOrEmpty($ConfigurationFile))) {
            Write-CustomLog -Message "Both parameters are null" -Level ERROR
            throw
        }
        $configObjects = @()
        if ($PsImportClientDirectory) {
            if (!(Test-Path -Path "$PsImportClientDirectory")) {
                Write-CustomLog -Message "Unable to find configurations directory ($PsImportClientDirectory)" -Level ERROR
                throw
            }
            $configurationsDirectory = Join-Path -Path $PsImportClientDirectory -ChildPath 'configurations'
            if (!(Test-Path -Path "$configurationsDirectory")) {
                Write-CustomLog -Message "Unable to find configurations directory ($configurationsDirectory)" -Level ERROR
                throw
            }
            try {
                Get-ChildItem -Path "$configurationsDirectory\*" -Include '*.json' | ForEach-Object {
                    $ConfigurationFile += $_.FullName
                }
            } catch {
                Write-CustomLog -Message "Failed to get configurations file from $configurationsDirectory" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        }
        if ($ConfigurationFile) {
            foreach ($file in $ConfigurationFile) {
                if (Test-Path -Path "$file") {
                    Write-CustomLog -Message "Processing configuration file $file" -Level VERBOSE
                    try {
                        $configContent = Get-Content -Path $file -Raw
                        Write-CustomLog -Message "Read configuration from file OK" -Level DEBUG
                    } catch {
                        Write-CustomLog -Message "Failed to get configuration from file $file" -Level WARN
                        Write-CustomLog -InputObject $_ -Level ERROR
                        continue
                    }
                    try {
                        Test-Configuration -Json $configContent
                        Write-CustomLog -Message "Configuration passed validation against schema" -Level DEBUG
                    } catch {
                        # Warn and errors are logged by Test-Configuration, catch block only to suppress output from throw
                        continue
                    }
                    try {
                        $configObjects += $configContent | ConvertFrom-Json
                        Write-CustomLog -Message "Converted configuration from JSON and added to list of configurations" -Level DEBUG
                    } catch {
                        Write-CustomLog -InputObject $_ -Level ERROR
                        continue
                    }
                    Write-CustomLog -Message "Done processing configuration file" -Level VERBOSE
                } else {
                    Write-CustomLog -Message "Unable to find $file" -Level WARN
                }
            }
        }
        return $configObjects
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}