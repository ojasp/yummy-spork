#Replace Write-Host to Write-Output to export the output to a file

param(
    [string]$SiteName = "TestOjas",                           #<---------Name of the website in IIS
    [string]$WebsitePath = "http://localhost:8090/",          #<---------Port number to check if website is online
    [string]$AppPoolName = "Test--Ojas",                      #<---------Name of the Application Pool
    [string]$public="", #"_PublishedWebsites\Public"          #<---------Relative path pf public website; relative to build folder as asked below (old_build_folder/new_build_folder)
    [string]$PSEmailServer = "onewire-web06.ny.fsvs.com",     #<---------This variable sets SMTP server. It's a system variable.
    [string]$old_build_folder = "",                           #<---------This variable saved the old build folder that is entered by user
    [string]$new_build_folder = ""                            #<---------This variable saved the new build folder that is entered by user
)

$deploymentresult = @()                                       #<---------This variable saves the output of commands & is added as body in the email
$Webconfigcopyerror=@()                                       #<---------This variable saves the error(if any) when copying web.config
$jsoncopyerror=@()                                            #<---------This variable saves the error(if any) when copying client_secret.json
#$SiteName = "TestOjas"                                        #<---------Name of the website in IIS
#$WebsitePath = "http://localhost:8090/"                       #<---------Port number to check if website is online
#$AppPoolName = "Test--Ojas"                                   #<---------Name of the Application Pool
$build_folder="C:\inetpub\wwwroot\"                           #<---------Not needed?
#$public="" #"_PublishedWebsites\Public"                       #<---------Relative path pf public website; relative to build folder as asked below (old_build_folder/new_build_folder)
$globalerror = 0                                              #<---------This variable tracks if error(s) occured during the script
$PSEmailServer = "onewire-web06.ny.fsvs.com"                  #<---------This variable sets SMTP server. It's a system variable.
$timeelapsedmonitoring = 0                                    #<---------This variable is used to see how many seconds have elapsed since the start of monitoring for number of current active connections
$buildcopyerror=@()                                           #<---------This variable is used to track if an error occured when changing physical directory
$wordstoskip = 0                                              #<---------This variable is used to filter out all the other details when pulling number of current connections counters

## CHANGE STRING LENGTH 60 TO USE SITE Name            ---Done
## MOVE RECYCLE                                        ---Done

$deploymentresult += Write-Output "`nStarting deployment on $env:computername, here are the user-entered parameters:"
#$old_build_folder= Read-Host 'Old Build Folder excluding trailing slash'
#$new_build_folder= Read-Host 'New Build Folder excluding trailing slash'

$deploymentresult += Write-Output "SiteName: $SiteName"
$deploymentresult += Write-Output "WebsitePath: $WebsitePath"
$deploymentresult += Write-Output "AppPoolName: $AppPoolName"
$deploymentresult += Write-Output "Public(Path): $Public"
$deploymentresult += Write-Output "PSEmailServer(SMTP Server): $PSEmailServer"
$deploymentresult += Write-Output "Old_build_folder: $old_build_folder"
$deploymentresult += Write-Output "New_build_folder: $new_build_folder`n"
#$deploymentresult += Write-Output "`nYou entered:`nOld Build Folder: $old_build_folder"
#$deploymentresult += Write-Output "New Build Folder: $new_build_folder"

#
###########     FUNCTIONS     ###########
#

# Convert the variable's output to string & send email

Function SendEmail($deploymentresult)
    {
    $deploymentresult = Out-String -InputObject $deploymentresult
    Send-MailMessage -To "ojas@onewire.com" -From "ojas@onewire.com" -Subject "Production Deployment result" -Body $deploymentresult
    }

#
###########     Make sure that old_builds_folder or new_builds_folder variables aren't empty     ###########
#

if (($old_build_folder.Length -eq 0) -or ($new_build_folder.Length -eq 0))
    {
        $deploymentresult += "`nHalting script, either old_script_folder or new_build_folder is empty!"
        SendEmail $deploymentresult
        Exit
    }
    

#
###########     Copy Public Stuff -- Web.config, client_secret.json     ###########
#

$deploymentresult += Write-Output "`nCopying web.config and client_secret.json from $old_build_folder\$public to $new_build_folder\$public..."
Copy-Item -Force $old_build_folder'\'$public'\web.config' -Destination $new_build_folder'\'$public -ErrorVariable Webconfigcopyerror -ErrorAction SilentlyContinue
Copy-Item -Force $old_build_folder'\'$public'\App_Data\client_secret.json' -Destination $new_build_folder'\'$public'\App_Data\' -ErrorVariable jsoncopyerror -ErrorAction SilentlyContinue
if ($Webconfigcopyerror.Count -ne 0)
    {
    $deploymentresult += Write-Output "`nERROR OCCURED copying webconfig, here are the details:`n`n$Webconfigcopyerror`n"
    $globalerror +=1
    }
elseif($Webconfigcopyerror.Count -le 0)
    {
     $deploymentresult += Write-Output "Successfully copied web.config!"
    }
if ($jsoncopyerror.Count -ne 0)
    {
    $deploymentresult += Write-Output "`nERROR OCCURED copying client_secret.json, here are the details:`n`n$jsoncopyerror`n" 
    $globalerror +=1
    }
elseif($jsoncopyerror.Count -le 0)
    {
    $deploymentresult += Write-Output "Successfully copied client_json.json!`n"
    }

#
###########     Fun Powershell stuff -- limit number of connections for $SiteName to 0 & get performance counters      ###########
#

import-module 'webAdministration'
$connectionlimit = Get-WebConfigurationProperty "/system.applicationHost/sites/site[@name='$SiteName']" -Name Limits | Select-Object -Property maxConnections
$connectionlimit = $connectionlimit -replace '\D+(\d+)\D+','$1'
$deploymentresult += Write-Output "Current connection limit: $connectionlimit"
$deploymentresult += Write-Output "Changing connection limi to 0..."
Set-WebConfigurationProperty "/system.applicationHost/sites/site[@name='$SiteName']" -Name Limits -Value @{MaxConnections=0}
$deploymentresult += Write-Output "Connection limit set to 0"

$DirtyCounter = Get-Counter "\web service($SiteName)\current connections"
$wordstoskip = 39+$SiteName.Length+$env:COMPUTERNAME.Length
$CleanCounter = $DirtyCounter.Readings.Substring($wordstoskip) -as [int]

#
###########     Check for number of connections     ###########
#

$deploymentresult += Write-Output "`nMonitoring number of connections"
while ($CleanCounter -ne 0)
    {
        $DirtyCounter = Get-Counter "\web service($SiteName)\current connections"
        $CleanCounter = $DirtyCounter.Readings.Substring($wordstoskip) -as [int]
        Start-Sleep -s 5
        $deploymentresult += Write-Output "Number of connections: $CleanCounter"
        $timeelapsedmonitoring += 5
        if ($CleanCounter -eq 0)
            {
            $deploymentresult += Write-Output "Time Elapsed: $timeelapsedmonitoring seconds `n"
            }
        elseif ($timeelapsedmonitoring -ge 300)
            {
            $deploymentresult += Write-Output "`nReached threshold of $timeelapsedmonitoring seconds, restarting $SiteName website!`n"
            $CleanCounter = 0
            Stop-Website $SiteName
            Start-Website $SiteName
            }
    }

#
###########     Change Physical Path     ###########
#

$deploymentresult += Write-Output "`nChanging Physical Path of the Website to $new_build_folder..."
Set-ItemProperty IIS:\Sites\$SiteName -Name physicalPath -Value $new_build_folder -ErrorVariable buildcopyerror
if ($buildcopyerror.count -ne 0)
    {
        $deploymentresult += Write-Output "ERROR OCCURED when changing physical path, here are the details:`n$buildcopyerror"
        $globalerror +=1
    }
else
    {
    $deploymentresult += Write-Output "Successfully changed physical path of teh website to $new_build_folder`n"
    }

#
###########     Reset the connection limit on IIS     ###########
#

$deploymentresult += Write-Output "Resetting the connection limit..."
Set-WebConfigurationProperty "/system.applicationHost/sites/site[@name='$SiteName']" -Name Limits -Value @{MaxConnections=4294967295}
$connectionlimit2 = Get-WebConfigurationProperty "/system.applicationHost/sites/site[@name='$SiteName']" -Name Limits | Select-Object -Property maxConnections
$connectionlimit2 = $connectionlimit2 -replace '\D+(\d+)\D+','$1'

if($connectionlimit2 -eq $connectionlimit)
{
    $deploymentresult += Write-Output "Connection limit successfully reset to defaults"
}
else
{
    $deploymentresult += Write-Output "WARNING! -- CONNECTION LIMIT COULD NOT BE RESET." 
    $globalerror +=1
}

#
###########     Recycle applicationpool     ###########
#

Restart-WebAppPool $AppPoolName

#
###########     Check if website is up     ###########
#

$deploymentresult += "`nChecking if website is up..."

[System.Net.HttpWebRequest]$HTTP_Request = [System.Net.WebRequest]::Create($WebsitePath)
$HTTP_Request.UserAgent = "Mozilla/5.0";
$HTTP_Request.Accept="text/html";
$HTTP_Request.Method="HEAD"

try
    {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
	[System.net.httpWebResponse]$HTTP_Response = $HTTP_Request.GetResponse() 
	} 
catch [System.Net.WebExceptionStatus]
    {
    $HTTP_Response = $_.Exception.Response
    }

$HTTP_Status_Code = $HTTP_Response.StatusCode

If ($HTTP_Status_Code -eq 200) 
    { 
        $deploymentresult += Write-Output "Site is up!`n" 
    }
Else {
        $deploymentresult += Write-Output "`nWARNING! -- DID NOT GET A STATUS OF 200.`nHere is the result:`n$HTTP_Response"
        $globalerror += 1
        $deploymentresult += Write-Output "`nChanging the builds directory back from $new_build_folder to $old_build_folder"
        $buildcopyerror2=@()
        Set-ItemProperty IIS:\Sites\$SiteName -Name physicalPath -Value $old_build_folder -ErrorVariable buildcopyerror2
        if ($buildcopyerror2.count -ne 0)
            {
                $deploymentresult += Write-Output "`nERROR OCCURED when reverting physical path, here are the details:`n$buildcopyerror2"
            }
        else
            {
                $deploymentresult += Write-Output "`nSuccessfully reverted physical path of teh website to $old_build_folder`n"
            }
}

$HTTP_Response.Close()

#
###########     End of script -- closing statement     ###########
#

if ($globalerror -eq 0)
    {
    $deploymentresult += Write-Output  "`nOperation completed without any errors! The $SiteName website is now running from $new_build_folder folder."
    }
elseif ($globalerror -gt 0)
    {
    $deploymentresult += Write-Output "`OPERATION COMPLETED WITH ERRORS!! SEE ABOVE."
    }

#
###########     Convert the variable's output to string & send email     ###########
#

SendEmail $deploymentresult


<#

##################              In case we need it:           ###################

###########     Set Virtual Directories     ###########

New-WebVirtualDirectory -Site "$SiteName" -Name Public -PhysicalPath $new_build_folder'\'$public
#To change physical path of a virtual directory
Set-ItemProperty 'IIS:\Sites\Default Web Site\DemoVirtualDirectory' -Name physicalPath -Value C:\inetpub\newDemoVirtualDirectory

#>
