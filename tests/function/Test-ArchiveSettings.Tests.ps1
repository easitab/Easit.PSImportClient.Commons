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
    $archiveSettingsFromFile = (Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'PSImportClientSettings.json') -Raw | ConvertFrom-Json)
}
Describe "Test-ArchiveSettings" -Tag 'function','public'{
    BeforeEach {
        $tempArchiveSettings = $archiveSettingsFromFile.archiveSettings
    }
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should have a parameter named Settings that is mandatory and accepts a PSCustomObject' {
        Get-Command "$($envSettings.CommandName)" | Should -HaveParameter Settings -Mandatory -Type [PSCustomObject]
    }
    It 'should NOT throw' {
        {Test-ArchiveSettings -Settings $tempArchiveSettings} | Should -Not -Throw
    }
    It 'should set directory to archive if value is empty' {
        $tempArchiveSettings.directory = ""
        Test-ArchiveSettings -Settings $tempArchiveSettings
        $tempArchiveSettings.directory | Should -BeExactly 'archive'
    }
    AfterEach {
        $tempArchiveSettings = $null
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
