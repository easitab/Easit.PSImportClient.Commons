BeforeAll {
    $helpersDirectory = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSCommandPath -Parent) -Parent) -ChildPath 'helpers'
    foreach ($helper in (Get-ChildItem -Path $helpersDirectory -Recurse -Include '*.ps1')) {
        . $helper.FullName
    }
    try {
        $envSettings = Get-EnvironmentSetting -Path $PSCommandPath
    } catch {
        throw $_
    }
    if (Test-Path $envSettings.CodeFilePath) {
        . $envSettings.CodeFilePath
    } else {
        Write-Output "Unable to locate code file ($($envSettings.CodeFilePath)) to test against!" -ForegroundColor Red
    }
    function Write-CustomLog {
        param (
            [string]$Message,
            [object]$InputObject,
            [string]$Level = 'INFO',
            [string]$OutputLevel,
            [string]$LogName,
            [string]$LogDirectory,
            [int]$RotationInterval,
            [switch]$Rotate
        )
        $outFilePath = "$($envSettings.ErrorFilePath).${Level}"
        if ($InputObject) {
            $InputObject | Out-File -FilePath $outFilePath -Force -Append
        }
        if ($Message) {
            $Message | Out-File -FilePath $outFilePath -Force -Append
        }
    }
    function Convert-PsObjectToHashtable {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [Object]$InputObject
        )
        
        begin {
            
        }
        
        process {
            $tempHash = @{}
            foreach ($prop in $InputObject.psobject.properties) {
                $tempHash.Add($prop.Name,$prop.Value)
            }
            return $tempHash
        }
        
        end {
            
        }
    }
    $sourceSettings1 = [PSCustomObject]@{
        dummy = "ihIdentifierFromSourceSettings"
        SendInBatchesOf = 45
        DelayBetweenBatches = 25
    }
    $sourceSettings2 = [PSCustomObject]@{
        importHandlerIdentifier = "ihIdentifierFromSourceSettings"
        writeXML = $true
        dryRun = $true
    }
    $destSettings1 = [PSCustomObject]@{
        url = "urlFromDestSettings"
        apikey = "apikeyFromDestSettings"
        importHandlerIdentifier = "ihIdentifierFromDestSettings"
        icConfigurationIdentifier = "icConfigFromDestSettings"
    }
    $destSettings2 = [PSCustomObject]@{
        url = "urlFromDestSettings"
        apikey = "apikeyFromDestSettings"
        InvokeRestMethodParameters = [PSCustomObject]@{
            Name1 = "Value1"
            Name2 = "Value2"
        }
    }
}
Describe "Get-SendToEasitGOParameters" -Tag 'function','public'{
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named SourceSettings that is mandatory and accepts a PSCustomObject' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter SourceSettings -Mandatory -Type [PSCustomObject]
    }
    It 'should have a parameter named DestinationSettings that is mandatory and accepts a PSCustomObject' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter DestinationSettings -Mandatory -Type [PSCustomObject]
    }
    It 'should throw if input to SourceSettings is invalid' {
        {Get-SendToEasitGOParameters -SourceSettings $sourceSettings -DestinationSettings $destSettings1} | Should -Throw
    }
    It 'should throw if input to DestinationSettings is invalid' {
        {Get-SendToEasitGOParameters -SourceSettings $sourceSettings1 -DestinationSettings $destSettings} | Should -Throw
    }
    It 'should NOT throw if all input is valid' {
        {Get-SendToEasitGOParameters -SourceSettings $sourceSettings1 -DestinationSettings $destSettings1} | Should -Not -Throw
    }
    It 'should have values from destination settings' {
        $params = Get-SendToEasitGOParameters -SourceSettings $sourceSettings1 -DestinationSettings $destSettings1
        $params.Url | Should -BeExactly 'urlFromDestSettings'
        $params.Apikey | Should -BeExactly 'apikeyFromDestSettings'
        $params.ImportHandlerIdentifier | Should -BeExactly 'ihIdentifierFromDestSettings'
    }
    It 'should have values from source settings' {
        $params = Get-SendToEasitGOParameters -SourceSettings $sourceSettings2 -DestinationSettings $destSettings1
        $params.ImportHandlerIdentifier | Should -BeExactly 'ihIdentifierFromSourceSettings'
    }
    It 'should return WriteBody = true and DryRun = true' {
        $params = Get-SendToEasitGOParameters -SourceSettings $sourceSettings2 -DestinationSettings $destSettings1
        $params.WriteBody | Should -BeExactly $true
        $params.DryRun | Should -BeExactly $true
    }
    It 'should return WriteBody = false and DryRun = false' {
        $params = Get-SendToEasitGOParameters -SourceSettings $sourceSettings1 -DestinationSettings $destSettings1
        $params.WriteBody | Should -BeNullOrEmpty
        $params.DryRun | Should -BeNullOrEmpty
    }
    It 'InvokeRestMethodParameters should be null' {
        $params = Get-SendToEasitGOParameters -SourceSettings $sourceSettings1 -DestinationSettings $destSettings1
        $params.InvokeRestMethodParameters | Should -BeNullOrEmpty
    }
    It 'InvokeRestMethodParameters should NOT be null' {
        $params = Get-SendToEasitGOParameters -SourceSettings $sourceSettings1 -DestinationSettings $destSettings2
        $params.InvokeRestMethodParameters | Should -Not -BeNullOrEmpty
        $params.InvokeRestMethodParameters.Name1 | Should -BeExactly 'Value1'
        $params.InvokeRestMethodParameters.Name2 | Should -BeExactly 'Value2'
    }
    AfterEach {
        $params = $null
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
