function Send-Notification {
    <#
    .SYNOPSIS
        Sends an notification.
    .DESCRIPTION
        The **Send-Notification** function sends a notification with the notification settings. It acts a wrapper for the Send-MailMessage cmdlet.
    .PARAMETER Settings
        Object with settings for how to send the notification.
    .EXAMPLE
        if ($settings.notificationSettings.sendNotification -and $settings.notificationSettings.enabled) {
            Send-Notification -Settings $settings.notificationSettings
        }
    .INPUTS
        [PSCustomObject](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.pscustomobject)
    .OUTPUTS
        None. This function returns no output.
    #>
    [CmdletBinding(HelpUri='https://docs.easitgo.com/techspace/psmodules/psimportclientcommons/functions/sendnotification/')]
    param (
        [Parameter(Mandatory,Position=0)]
        [PSCustomObject]$Settings
    )
    begin {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) initialized" -Level VERBOSE
        <#
            As we only support notifications via SMTP we have implemented the functionality directly in this function.
            If any more notification types are added, this function should only act as a dispatcher calling other
            functions to do the actual sending (For example, Send-SmtpNotification or Invoke-SmtpNotification).
        #>
    }
    process {
        if ($Settings.type -eq 'smtp') {
            if ([string]::IsNullOrEmpty($Settings.Subject)) {
				$settings.Subject = "PSImportClient notification"
            }
            if ([string]::IsNullOrEmpty($Settings.username)) {
				throw [System.ArgumentNullException]::new("username")
            } else {
                $userName = "$($Settings.username)"
            }
            if ([String]::IsNullOrEmpty($Settings.password)) {
                throw [System.ArgumentNullException]::new("password")
            }
			if (!([string]::IsNullOrEmpty($Settings.password))) {
                $userPassword = "$($Settings.password)"
            }
            if (!([string]::IsNullOrEmpty($Settings.apikey))) {
                $userPassword = "$($Settings.apikey)"
            }
            $sendMailParameters = @{
                To = "$($Settings.To)"
                From = "$($Settings.From)"
                SmtpServer = "$($Settings.SmtpServer)"
                Port = $Settings.Port
                Encoding = 'utf8'
                Subject = "$($Settings.Subject)"
                Body = "Log from running psImportClient on ${env:COMPUTERNAME}"
                ErrorAction = 'Stop'
            }
			if (!([string]::IsNullOrEmpty($userName)) -and !([string]::IsNullOrEmpty($userPassword))) {
				try {
					[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
					[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
				} catch {
                    Write-CustomLog -Message "Failed to create PSCredentails" -Level WARN
                    Write-CustomLog -InputObject $_ -Level ERROR
					throw
				}
                if ($null -eq $credObject) {
                    Write-CustomLog -Message "Failed to create PSCredentails, credObject is null" -Level WARN
                    throw
                }
				$sendMailParameters.Add('Credential',$credObject)
			}
            if ($Settings.UseSsl -eq 'true') {
                $sendMailParameters.Add('UseSsl',$true)
            }
            $log = Get-ChildItem -Path "$($loggerSettings.LogDirectory)\*" -Recurse -Include "$($loggerSettings.LogName)*.log"
            if (!($log.Count -eq 1)) {
				$log = $log | Sort-Object -Descending | Select-Object -First 1
			}
			if ($log) {
				$sendMailParameters.Add('Attachments',"$($log.FullName)")
			}
            try {
                Send-MailMessage @sendMailParameters
            } catch {
                Write-CustomLog -Message "$($_.Exception.Message)" -Level ERROR
            }
        } else {
            throw "Unknown notification type ($($Settings.type))"
        }
    }
    end {
        Write-CustomLog -Message "$($MyInvocation.MyCommand) end" -Level VERBOSE
    }
}