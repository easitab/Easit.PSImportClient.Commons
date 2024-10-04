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
    function New-PropertyValue {
        param (
            [Parameter()]
            [PSCustomObject]$Object,
            [Parameter()]
            [array]$Attributes,
            [Parameter()]
            [array]$CombineCharacter
        )
        $returnValue = $null
        foreach ($attribute in $Attributes) {
            if ($null -eq $returnValue) {
                $returnValue = "$($Object."$attribute")"
            } else {
                $returnValue = "${returnValue}${CombineCharacter}$($Object."$attribute")"
            }
            Write-CustomLog -Message "returnValue = $returnValue" -Level DEBUG
        }
        if ([String]::IsNullOrEmpty($CombineCharacter)) {

        } else {
            $returnValue = $returnValue.TrimStart($CombineCharacter)
            $returnValue = $returnValue.TrimEnd($CombineCharacter)
        }
        if ([string]::IsNullOrEmpty($returnValue)) {
            Write-CustomLog -Message "returnValue is null" -Level WARN
            return
        } else {
            return $returnValue
        }
    }
    $configurationSettings = (Get-Content -Path (Join-Path -Path $envSettings.TestDataDirectory -ChildPath 'oneConfiguration1CombineSourceAttributes.json') -Raw | ConvertFrom-Json)
    $combine = $configurationSettings.sources[0].combineSourceAttributes.combines[0]
    $invalidCombine = [PSCustomObject]@{
        attributes = @('string1','string2','string3')
        character = 2
        combineAttributeOutputName = @('string1','string2','string3')
    }
}
Describe "Add-NewCombineProperty" -Tag 'function','public'{
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
    It 'should NOT throw or write any errors or warnings' {
        {Add-NewCombineProperty -InputObject $customObject -Combine $combine} | Should -Not -Throw
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -BeNullOrEmpty
    }
    It 'should add a property named userName with a value' {
        Add-NewCombineProperty -InputObject $customObject -Combine $combine
        $customObject.userName | Should -BeExactly 'Value1-2'
    }
    It 'should throw if property already exists' {
        $customObject | Add-Member -MemberType NoteProperty -Name "$($combine.combineAttributeOutputName)" -Value "tempValue"
        {Add-NewCombineProperty -InputObject $customObject -Combine $combine} | Should -Throw
    }
    It 'should write error and warning when it throws' {
        $customObject | Add-Member -MemberType NoteProperty -Name "$($combine.combineAttributeOutputName)" -Value "tempValue"
        {Add-NewCombineProperty -InputObject $customObject -Combine $combine} | Should -Throw
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'WARN' | Should -Not -BeNullOrEmpty
        Get-LogFile -Path $envSettings.TestDataDirectory -Prefix $envSettings.LogPrefix -Suffix 'ERROR' | Should -Not -BeNullOrEmpty
    }
    AfterEach {
        $customObject = $null
    }
}
AfterAll {
    try {
        Get-ChildItem -Path $envSettings.TestDataDirectory -Recurse -Include "$($envSettings.LogPrefix)*" -File | Remove-Item -Confirm:$false
    } catch {
        throw
    }
}
