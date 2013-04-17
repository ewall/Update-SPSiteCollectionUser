<#

Update-SPSiteCollectionUser.ps1 -- by Eric Wallace <e@ewall.org>, 2013-04-17


.SYNOPSIS
User a user's DisplayName and Email fields in every SharePoint site collection.

Requires SharePoint management snapin.


.NOTES

In SharePoint, each site collection stores its own table of user data. When the
user accounts are updated in Active Directory, SharePoint's User Profile Service
application will automatically update the user profile used by the non-free
features, but only site collections where the user is "active" (i.e. recently
edited something, not just read it) will get updated.

If the user has a name change and their AD account and email address are
it can be disconcerting when one SharePoint page shows their new name and email
while another shows the old one. This script exists to help you quickly update
the old DisplayName and Email fields so the user doesn't worry.

Please read carefully before deciding to use this; it *will* make changes to
your SharePoint user data! (Of course, if you want to "undo" you can just run
the command again and put the old info back in.) So far I have only tested this
with SharePoint 2010.

  
.HISTORY

2013-04-17 initial release

#>

# load SharePoint snap-in if not already loaded
If ( (Get-PSSnapin -Name Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PsSnapin Microsoft.SharePoint.Powershell
}

# debug mode shows more detailed output
$ShowDebug = $false

# prompt for user input
$user = Read-Host "`r`nEnter username (domain\username)"
$name = Read-Host "Enter display name (Johnny B. Good)"
$email = Read-Host "Enter email address (user@domain.com)"

Write-Host("`r`nPlease wait while we query the site collections...")

# username may also have the 'i:0#.w|' prefix
$useralt = "i:0#.w|" + $user

# loop thru all site collections except the personal MySites
foreach($site in Get-SPSite -Limit All | ?{$_.url -notlike "*/personal/*"}) { 
  Write-Host("`r`nSite Collection: " + $site.Url)

  # try 2 different username options
  foreach($id in ($user,$useralt)) {
    # try's are nested so we can use the -ErrorAction Stop option
    Try {
      Try {
        Get-SPUser -Identity $id -Web $site.Url -ErrorAction Stop | Out-Null
        If ($ShowDebug) {
          Write-Host "BEFORE:"
          Get-SPUser -Identity $id -Web $site.Url | fl *
        }

        Write-Host ("  Updating user " + $id) -ForegroundColor yellow
        
        # you can add '-WhatIf' to the following line
        Set-SPUser -Identity $id -Web $site.Url -DisplayName $name -Email $email -ErrorAction Stop
        
        Write-Host ("  --> Success!") -ForegroundColor green
        
        If ($ShowDebug) {
          Write-Host "AFTER:"
          Get-SPUser -Identity $id -Web $site.Url | fl *
        }
      }
      Catch {
        # rethrow the "real" exception one level higher
        Throw $_.Exception
      }
    }
    Catch [System.UnauthorizedAccessException] {
      Write-Host "  You do not have permissions on this site collection!" -ForegroundColor red
    }
    Catch [System.Management.Automation.PSArgumentException] {
      Write-Host('  User "' + $id + '" not found.')
    }
    Catch {
      If ($ShowDebug) {
        Write-Error $_
      } Else {
        Write-Host ("  Unexpected Error (use debug mode to show details)") -ForegroundColor red
      }
    }
  }
}
Write-Host "Script complete." -ForegroundColor green
