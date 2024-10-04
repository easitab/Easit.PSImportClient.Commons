function Test-Configuration {
    <#
    .SYNOPSIS
        Tests whether a string is a valid JSON document.
    .DESCRIPTION
        The **Test-Configuration** function tests whether a string is a valid JavaScript Object Notation (JSON) document and verifies that JSON document against a provided schema.
    .PARAMETER Json
        Specifies the JSON string to test for validity.
    .PARAMETER SchemaDirectory
        Full path to directory where schemas are located.
    .PARAMETER SchemaFile
        Name of schema file to test JSON against.
    .EXAMPLE
        $configContent = Get-Content -Path $pathtojson -Raw
        Test-Configuration -Json $configContent
    .INPUTS
        [System.String](https://learn.microsoft.com/en-us/dotnet/api/system.string)
    .OUTPUTS
        None. This function returns no output
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/testconfiguration/')]
    [OutputType()]
    param (
        [Parameter(Mandatory)]
        [string]$Json,
        [Parameter()]
        [string]$SchemaDirectory,
        [Parameter()]
        [string]$SchemaFile
    )
    
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
    }
    
    process {
        if ([String]::IsNullOrEmpty($Json) -or $null -eq $Json) {
            Write-CustomLog -Message "JSON string is null or empty" -Level ERROR
            throw
        }
        if ([String]::IsNullOrEmpty($SchemaFile)) {
            $SchemaFile = 'configuration.schema.json'
        }
        if ([String]::IsNullOrEmpty($SchemaDirectory)) {
            $SchemaDirectory = Join-Path -Path (Get-Location) -ChildPath 'schemas'
        }
        try {
            $configurationSchema = Join-Path -Path $SchemaDirectory -ChildPath $SchemaFile
        } catch {
            Write-Error "Failed to join path $SchemaDirectory with $SchemaFile"
            throw
        }
        if (Test-Path -Path $configurationSchema) {
            try {
                $null = Test-Json -Json $Json -SchemaFile $configurationSchema -ErrorAction Stop
            } catch {
                Write-CustomLog -Message "Json failed validation agains schema" -Level WARN
                Write-CustomLog -InputObject $_ -Level ERROR
                throw
            }
        } else {
            Write-CustomLog -Message "Unable to find configuration schema, $configurationSchema" -Level ERROR
            throw
        }
    }
    
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}