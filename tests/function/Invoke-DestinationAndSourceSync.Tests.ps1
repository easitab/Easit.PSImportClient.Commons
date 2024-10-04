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
    $destination1 = [PSCustomObject]@{
        name = "destination1name"
        url = "destination1url"
        apikey = "destination1apikey"
    }
    $destination2 = [PSCustomObject]@{
        name = "destination2name"
        url = ""
    }
    $destination3 = [PSCustomObject]@{
        name = "destination3name"
        url = "destination3url"
        apikey = ""
    }
    $destination4 = [PSCustomObject]@{
        name = "destination4name"
        url = "destination4url"
        apikey = "destination4apikey"
        writeXML = $true
        dryRun = $true
        batchSize = 100
        batchDelay = 100
    }
}
Describe "Invoke-DestinationAndSourceSync" -Tag 'function','public'{
    BeforeEach {
        $source1 = [PSCustomObject]@{
            name = "source1name"
            importHandlerIdentifier =  "source1importHandlerIdentifier"
            configurationType = "source1configurationType"
            icConfigurationIdentifier = "source1icConfigurationIdentifier"
        }
        $source2 = [PSCustomObject]@{
            name = "source2name"
            importHandlerIdentifier =  "source2importHandlerIdentifier"
            configurationType = "source2configurationType"
            icConfigurationIdentifier = ""
        }
        $source3 = [PSCustomObject]@{
            name = "source1name"
            importHandlerIdentifier =  "source1importHandlerIdentifier"
            configurationType = "source1configurationType"
            icConfigurationIdentifier = "source1icConfigurationIdentifier"
            writeXML = $false
            dryRun = $false
        }
        $source4 = [PSCustomObject]@{
            name = "source1name"
            importHandlerIdentifier =  "source1importHandlerIdentifier"
            configurationType = "source1configurationType"
            icConfigurationIdentifier = "source1icConfigurationIdentifier"
            batchSize = 75
            batchDelay = 75
        }
    }
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named Destination that is not mandatory' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter Destination -Not -Mandatory
    }
    It 'should have a parameter named Source that is not mandatory' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter Source -Not -Mandatory
    }
    It 'should throw if source and destination is null' {
        {Invoke-DestinationAndSourceSync -Destination $null -Source $null} | Should -Throw
    }
    It 'should throw if source.url and destination.url is null' {
        {Invoke-DestinationAndSourceSync -Destination $destination2 -Source $source1} | Should -Throw
    }
    It 'should throw if source.apikey and destination.apikey is null' {
        {Invoke-DestinationAndSourceSync -Destination $destination3 -Source $source1} | Should -Throw
    }
    It 'should throw if source.icConfigurationIdentifier is null' {
        {Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source2} | Should -Throw
    }
    It 'should set source.url to destination1url' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source1
        $source1.url | Should -BeExactly 'destination1url'
    }
    It 'should set source.apikey to destination1apikey' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source1
        $source1.apikey | Should -BeExactly 'destination1apikey'
    }
    It 'should NOT add source.writeXML if not specified' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source1
        Get-Member -InputObject $source1 -Name 'writeXML' | Should -BeNullOrEmpty
    }
    It 'should add source.writeXML and set it to true' {
        Invoke-DestinationAndSourceSync -Destination $destination4 -Source $source1
        $source1.writeXML | Should -BeExactly $true
    }
    It 'should return source.writeXML with false as its value' {
        Invoke-DestinationAndSourceSync -Destination $destination4 -Source $source3
        $source3.writeXML | Should -BeExactly $false
    }
    It 'should NOT add source.dryRun if not specified' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source1
        Get-Member -InputObject $source1 -Name 'dryRun' | Should -BeNullOrEmpty
    }
    It 'should add source.dryRun and set it to true' {
        Invoke-DestinationAndSourceSync -Destination $destination4 -Source $source1
        $source1.dryRun | Should -BeExactly $true
    }
    It 'should return source.dryRun with false as its value' {
        Invoke-DestinationAndSourceSync -Destination $destination4 -Source $source3
        $source3.dryRun | Should -BeExactly $false
    }
    It 'should NOT add source.batchSize if not specified' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source1
        Get-Member -InputObject $source1 -Name 'batchSize' | Should -BeNullOrEmpty
    }
    It 'should add source.batchSize and set it to 75' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source4
        $source4.batchSize | Should -BeExactly 75
    }
    It 'should add source.batchSize and set it to 100' {
        Invoke-DestinationAndSourceSync -Destination $destination4 -Source $source1
        $source1.batchSize | Should -BeExactly 100
    }
    It 'should NOT add source.batchDelay if not specified' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source1
        Get-Member -InputObject $source1 -Name 'batchDelay' | Should -BeNullOrEmpty
    }
    It 'should add source.batchDelay and set it to 75' {
        Invoke-DestinationAndSourceSync -Destination $destination1 -Source $source4
        $source4.batchDelay | Should -BeExactly 75
    }
    It 'should add source.batchDelay and set it to 100' {
        Invoke-DestinationAndSourceSync -Destination $destination4 -Source $source1
        $source1.batchDelay | Should -BeExactly 100
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
