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
    $combine1 = [PSCustomObject]@{
        attributes = @('Name1','Name2')
        character = '-'
        combineAttributeOutputName = 'outputName'
    }
    $combine2 = [PSCustomObject]@{
        attributes = @('Name1','Name4')
        character = '-'
        combineAttributeOutputName = 'outputName'
    }
    $combine3 = [PSCustomObject]@{
        attributes = @('Name1','Name2')
        character = ''
        combineAttributeOutputName = 'outputName'
    }
    $combine4 = [PSCustomObject]@{
        attributes = @('Name1','Name4')
        character = ''
        combineAttributeOutputName = 'outputName'
    }
    $combine5 = [PSCustomObject]@{
        attributes = @('Name1','Name3')
        character = '-'
        combineAttributeOutputName = 'outputName'
    }
    $combine6 = [PSCustomObject]@{
        attributes = @('Name1','Name3')
        character = ''
        combineAttributeOutputName = 'outputName'
    }
}
Describe "New-PropertyValue" -Tag 'function','public'{
    BeforeEach {
        $customObject = [PSCustomObject]@{
            Name1 = "Value1"
            Name2 = 2
            Name3 = @('string1','string2','string3')
        }
    }
    It 'should have complete help section' {
        {Test-HelpSection -CommandName "$($envSettings.CommandName)"} | Should -Not -Throw
    }
    It 'should return Value1-2' {
        $result = New-PropertyValue -Object $customObject -Attributes $combine1.attributes -CombineCharacter $combine1.character
        $result | Should -BeExactly 'Value1-2'
    }
    It 'should return Value1' {
        $result = New-PropertyValue -Object $customObject -Attributes $combine2.attributes -CombineCharacter $combine2.character
        $result | Should -BeExactly 'Value1'
    }
    It 'should return Value12' {
        $result = New-PropertyValue -Object $customObject -Attributes $combine3.attributes -CombineCharacter $combine3.character
        $result | Should -BeExactly 'Value12'
    }
    It 'should return Value1' {
        $result = New-PropertyValue -Object $customObject -Attributes $combine4.attributes -CombineCharacter $combine4.character
        $result | Should -BeExactly 'Value1'
    }
    It 'should return Value1-string1 string2 string3' {
        $result = New-PropertyValue -Object $customObject -Attributes $combine5.attributes -CombineCharacter $combine5.character
        $result | Should -BeExactly 'Value1-string1 string2 string3'
    }
    It 'should return Value1string1 string2 string3' {
        $result = New-PropertyValue -Object $customObject -Attributes $combine6.attributes -CombineCharacter $combine6.character
        $result | Should -BeExactly 'Value1string1 string2 string3'
    }
    AfterEach {
        $customObject = $null
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
