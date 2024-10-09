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
    $archiveDirectoryName1 = 'archive1'
    $archiveDirectoryName2 = 'archive2'
    $configName1 = 'configName1'
    $configName2 = 'configName2'
    $sourceName1 = 'sourceName1'
    $sourceName2 = 'sourceName2'
    $fileToArchive = Join-Path -Path $envSettings.TestDataDirectory -ChildPath "$($envSettings.LogPrefix)-temp"
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
}
Describe "Add-FileToArchive" -Tag 'function','public'{
    BeforeEach {
        if (Test-Path $fileToArchive) {

        } else {
            $null = New-Item -Path $fileToArchive -ItemType File -Force
        }
    }
    It 'should have complete help section' {
        Write-Host $envSettings
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named ArchiveDirectory that is mandatory and accepts a string' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ArchiveDirectory -Mandatory -Type [String]
    }
    It 'should have a parameter named FileToArchive that is mandatory and accepts a string' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter FileToArchive -Mandatory -Type [String]
    }
    It 'should have a parameter named ConfigurationName that is mandatory and accepts a string' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter ConfigurationName -Mandatory -Type [String]
    }
    It 'should have a parameter named SourceName that is mandatory and accepts a string' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter SourceName -Mandatory -Type [String]
    }
    It 'should throw if file to archive does not exist' {
        $tempParams = @{
            ArchiveDirectory = $envSettings.TestDataDirectory
            FileToArchive = (Join-Path -Path $envSettings.TestDataDirectory -ChildPath "$($envSettings.LogPrefix)-temp2")
            ConfigurationName = $configName1
            SourceName = $sourceName1
        }
        {Add-FileToArchive @tempParams} | Should -Throw
    }
    It 'should NOT throw' {
        $tempParams = @{
            ArchiveDirectory = $envSettings.TestDataDirectory
            FileToArchive = $fileToArchive
            ConfigurationName = $configName1
            SourceName = $sourceName1
        }
        {Add-FileToArchive @tempParams} | Should -Not -Throw
    }
    It 'should copy a file to archive' {
        $tempParams = @{
            ArchiveDirectory = $envSettings.TestDataDirectory
            FileToArchive = $fileToArchive
            ConfigurationName = $configName1
            SourceName = $sourceName1
        }
        Add-FileToArchive @tempParams
        Get-ChildItem -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath $configName1) -Include "*$($envSettings.LogPrefix)-temp*" -Recurse -File | Should -Not -BeNullOrEmpty
    }
    AfterEach {
        $tempParams = $null
        Remove-Item -Path $fileToArchive -Confirm:$false -ErrorAction SilentlyContinue -Force
        Get-ChildItem -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath $configName1) -Recurse -File | Remove-Item -Confirm:$false -Force
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include $configName1 -Directory -Force | Remove-Item -Confirm:$false -Force -Recurse
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
