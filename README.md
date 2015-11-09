# yummy-spork
There are two scripts as a part of this reporsitory, xxx copies the files from your integration environment to a location in production & deploy-code.ps1 performs a series of tasks to perform a rolling deployment. XXX is ran from your machine & it assumes that you already have deploy-code.ps1 saved on the production VM.

#xxx:
Copies The Build folder from integration to production server
Invokes remote script(YYY) on production server with parameters

#deploy-code.ps1:
Here are the defaults for parameters that this scripts accepts: 
[string]$SiteName = "TestOjas"
[string]$WebsitePath = "http://localhost:8090/"
[string]$AppPoolName = "Test--Ojas"
[string]$public=""
[string]$PSEmailServer = "smtp.google.com"
[string]$old_build_folder = ""
[string]$new_build_folder = ""

Steps taken by this script:
i. Take parameters from user, if nothing entered for a variable then take defaults

ii. Declare SendEmail function. You can define the to & from email addresses here
iii. If old & new build folders are not specified by the user then quit the script and send an email to the user
iv. Copy web.config & client_secret.json from old builds folder to new builds folder
v. Limit number of connections to 0 & get performance counters
vi. Monitor number of connections until it reaches 0
vii. Change the physical path in IIS to new_builds_folder
viii. Reset connection limit
ix. Recycle application pool
x. Check if the website is up (check for status 200)
xi. Send email with the execution results
