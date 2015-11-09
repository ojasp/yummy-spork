$pass = "MyPassword" | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Domain\user',$pass)
#Import-Module TaskScheduler

$copyerror =@()
New-PSDrive -Name T -PSProvider FileSystem -Root \\192.168.2.2\c$\Builds\Public -Credential $cred
Copy-Item C:\Builds\Integration\Release1.1 -Recurse T:\ -Force -ErrorAction SilentlyContinue -ErrorVariable copyerror   ##### Remove -Force switch if you want to exit when the folder exists in destination
Remove-PSDrive -Name T
net use "\\192.168.2.2\c$\Builds\Public" /delete

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
            $PSEmailServer = "smtp.google.com",             #<---------This variable sets SMTP server. It's a system variable.
            #>
        Invoke-Command -ComputerName 192.168.2.2 `
            {`
            &"C:\Deploy_Scripts\deploy_code.ps1" `
            -old_build_folder "C:\inetpub\wwwroot" `
            -new_build_folder "C:\inetpub\wwwroot\Test" `
            }
    }
else
    {
        Write-Output "`nThere were copy errors!`n"$copyerror
        Write-Output "`n##############`nExiting Script`n##############"
    }

