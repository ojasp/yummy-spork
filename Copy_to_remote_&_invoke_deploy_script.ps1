$pass = "Password1" | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('fsvs\otest',$pass)
#Import-Module TaskScheduler

$copyerror =@()
New-PSDrive -Name T -PSProvider FileSystem -Root \\192.168.22.41\c$\Test -Credential $cred
Copy-Item C:\test\AdobeReaderDCMSI -Recurse T:\ -Force -ErrorAction SilentlyContinue -ErrorVariable copyerror   ##### Remove -Force switch if you want to exit when the folder exists in destination
Remove-PSDrive -Name T
net use "\\192.168.22.41\c$\Test" /delete

if($copyerror.Count -eq 0)
    {
        Write-Output "`nNo Copy errors!!"
            <# 
        
            POWERSHELL SCRIPT ACCEPTS THESE PARAMETERS & HAS THESE DEFAULT VALUES:

            $SiteName = "TestOjas",                         #<---------Name of the website in IIS
            $WebsitePath = "http://localhost:8090/",        #<---------Path to check if website is online
            $AppPoolName = "Test--Ojas",                    #<---------Name of the Application Pool
            $old_build_folder = "",                         #<---------This variable saved the old build folder that is entered by user
            $new_build_folder = ""                          #<---------This variable saved the new build folder that is entered by user
            $public="",                                     #<---------Relative path pf public website; relative to build folder(old_build_folder/new_build_folder)
            $PSEmailServer = "onewire-web06.ny.fsvs.com",   #<---------This variable sets SMTP server. It's a system variable.
            #>
        Invoke-Command -ComputerName onewire-web06 `
            {`
            &"C:\Users\opanwar\Desktop\Automate Production Deployment.ps1" `
            -old_build_folder "C:\inetpub\wwwroot" `
            -new_build_folder "C:\inetpub\wwwroot\Test" `
            }
    }
else
    {
        Write-Output "`nThere were copy errors!`n"$copyerror
        Write-Output "`n##############`nExiting Script`n##############"
    }

