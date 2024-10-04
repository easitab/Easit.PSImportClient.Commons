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
    $customObject = [PSCustomObject]@{
        Name1 = "Value1"
        Name2 = 2
        Name3 = @('string1','string2','string3')
    }
}
Describe "Convert-PsObjectToHashtable" -Tag 'function','public'{
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should NOT throw' {
        {Convert-PsObjectToHashtable -InputObject $customObject} | Should -Not -Throw
    }
    It 'should NOT write errors or warnings' {
        $null = Convert-PsObjectToHashtable -InputObject $customObject
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
    }
    It 'should return a hashtable' {
        $hashtable = Convert-PsObjectToHashtable -InputObject $customObject
        $hashtable | Should -BeOfType [System.Collections.Hashtable]
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
