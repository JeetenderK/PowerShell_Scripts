
### Testing comment

$ScriptFolder = split-path -parent $MyInvocation.MyCommand.Path
$ScriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path 


$MissingEntry_flag = $false

$Server = (Read-Host "Enter name of server").trim()
$Sites_Path = "\\" + $Server + "\e$\inetpub\wwwroot"

if(test-path -Path $Sites_Path)
{
    $site_list = Get-ChildItem -Path $Sites_Path
    $Host = "\\" + $Server + "\c$\windows\system32\drivers\etc\hosts"
        
    $host.ui.RawUI.WindowTitle = "$ScriptName -- $Server"

    foreach($site in $site_list)
    {
        $site_name = $site.Name
        $config_path = "$Sites_Path" + "\$site_name\" + "web.config"

        if(test-path -Path $config_path)
        {
            $SourceConfig = Get-Content $config_path
            $Address_list = @()
            $continue = 0

            foreach($line in $SourceConfig)
            {
                if($line -match "<endpoint" -or $continue)
                {
                    if($line -notmatch '<!--.+endpoint')
                    {
                        $test = $test + $line

                        if($test -notmatch ">")
                        {
                            $continue=1
                            continue
                        }

                        $continue = 0
                        $address = $test -replace '<.address="',''
                        $address = ($address -replace '".+','').trim()
                        $Entry = ($address -replace 'ht.+://', "") -replace "/.+", "" -replace ":.+",""

                        ####### correct it #########
                        if($Entry -match ":" -and $Entry.Substring(0,1) -match )
                        {
                            $Entry = $Entry.Split(':')[0]
                        }

                        if($Entry -match '\w')
                        {
                            $Address_list += $Entry
                        }

                        $test = $null
                    }
                }
            }

            Write-host "$Site : "

            foreach($address in $Address_list)
            {
                if(!(Select-String -Path $Host -Pattern $address))
                {
                    Write-host "Host entry absnet in Host : $address"
                    $MissingEntry_flag = $True
                }
            }
            Write-Host ""
        }
    }

    Write-Host ""
}

Write-Host "Complete `n" -ForegroundColor Green

if($MissingEntry_flag)
{
    Write-Host "want to open host file ? (y/n)"
    if((Read-Host "").Trim().ToUpper() -eq "Y")
    {
        Set-Alias Np "C:\windows\system32\notepad.exe"
        Np "\\$Server\c$\windows\system32\drivers\etc\hosts"
    }
}

