﻿param($installPath, $toolsPath, $package, $project)

Import-Module (Join-Path $toolsPath "Get-ConfigPath.psm1")
Import-Module (Join-Path $toolsPath "Remove-AutoInstallModuleRegistration.psm1")
Import-Module (Join-Path $toolsPath "Remove-CustomIEHeader.psm1")
Import-Module (Join-Path $toolsPath "Get-Config.psm1")
Import-Module (Join-Path $toolsPath "Update-AssemblyBinding.psm1")
Import-Module (join-path $toolsPath  "Get-PackagesToolPath.psm1")

Function RemoveObsoleteFiles([String] $sitePath)
{
	#Remove obsolete files relate to Mediachase.Cms			
	$mediachaseCmsConfigPath = Join-Path $sitePath "Configs\ecf.cms.config";
	if(Test-Path($mediachaseCmsConfigPath)) {
		Write-Host "Removing file $mediachaseCmsConfigPath"
		Remove-Item $mediachaseCmsConfigPath
	}		
}

#Get the Framework package
$thePackage = Get-package -ProjectName $project.ProjectName | where-object { $_.id -eq "EPiServer.Framework"} | Sort-Object -Property Version -Descending | select-object -first 1
#Get EPiDeploy.exe Path
$frameWorkToolPath = Get-PackagesToolPath $installPath "EPiServer.Framework" $thePackage.Version
$deployEXEPath =  join-Path ($frameWorkToolPath) "epideploy.exe"
$commerceConfigBaselinePath =[System.IO.Path]::Combine($installPath, "tools\webconfig-baseline.config")
$projectFilePath = Get-ChildItem $project.Fullname
$sitePath = $projectFilePath.Directory.FullName

#Remove AutoInstallMetaDataModule registrations
$bafConfigPath = Join-Path $sitePath "Configs\baf.data.manager.config"
if (Test-Path $bafConfigPath)
{
    $bafConfig = Get-Config $bafConfigPath
    Remove-AutoInstallModuleRegistration $bafConfig
    $bafConfig.Save($bafConfigPath)
}

#add/update binding redirects for assemblies in the current package
$configPath = Get-ConfigPath $project
if ($configPath -eq $null)
{
    Write-Host "Unable to find a configuration file, binding redirect not configured."
}
else
{
    $config = Get-Config $configPath
    Remove-CustomIEHeader $config | Out-Null
    Update-AssemblyBinding $config $installPath | Out-Null
	$config.Save($configPath)
	
    ## Install baseline if not already added
    if(-not (Test-Path (Join-Path $sitePath "web.config")))
    {
        Write-Host "Unable to find web.config file, Commerce baseline configuration not added."
    }
    elseif ($config.configuration.CommerceFramework -eq $null)
    {
        Write-Host "Adding Commerce baseline configuration"
        & $deployEXEPath -s $sitePath -a config -p $commerceConfigBaselinePath
    }
}
RemoveObsoleteFiles $sitePath


# SIG # Begin signature block
# MIIXpAYJKoZIhvcNAQcCoIIXlTCCF5ECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsdOlo+5SvDJ1JQX1TfcAB5oy
# HV6gghLKMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggTQMIIDuKADAgECAhASn/W83LmZkqPf6+aeK2mOMA0GCSqGSIb3DQEBCwUAMH8x
# CzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0G
# A1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMg
# Q2xhc3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBMB4XDTE2MDExMzAwMDAwMFoX
# DTE5MDQxMzIzNTk1OVowYzELMAkGA1UEBhMCU0UxEjAQBgNVBAgTCVNUT0NLSE9M
# TTESMBAGA1UEBxMJU1RPQ0tIT0xNMRUwEwYDVQQKFAxFUGlTZXJ2ZXIgQUIxFTAT
# BgNVBAMUDEVQaVNlcnZlciBBQjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBALWsGwJJX/DKwasEkA9qAsdlsqP8SjVHN7lXwAt2CfBjDI0rN8DO20OfCgos
# Dw1rsSAs1iNNFrB6tdzM+wXZQrHE+bJAYvEXzmZM1kSQfCLz6qIwxx3cRIz8u3Wb
# lH391Dqz03Hf6Ds8N42QKv3m9gQP6g1OIPwlziVkgZ4ANdAP4CfTKPmg0kFqW+az
# WQs+ccYOZEWBi4oPIvPv1uwAbAKIK9fArAtrta7vIdtNf2FZftuL/kAjz980wDFY
# moYR4IGY2eT0FETkoi+dQOhxIbZEl5ziPr5cpiHDWt3J5gueoQCEhiKFg9Uzoquj
# 07IyexmtsjtDsMenkwOSGt2aefMCAwEAAaOCAWIwggFeMAkGA1UdEwQCMAAwDgYD
# VR0PAQH/BAQDAgeAMCsGA1UdHwQkMCIwIKAeoByGGmh0dHA6Ly9zdi5zeW1jYi5j
# b20vc3YuY3JsMGYGA1UdIARfMF0wWwYLYIZIAYb4RQEHFwMwTDAjBggrBgEFBQcC
# ARYXaHR0cHM6Ly9kLnN5bWNiLmNvbS9jcHMwJQYIKwYBBQUHAgIwGQwXaHR0cHM6
# Ly9kLnN5bWNiLmNvbS9ycGEwEwYDVR0lBAwwCgYIKwYBBQUHAwMwVwYIKwYBBQUH
# AQEESzBJMB8GCCsGAQUFBzABhhNodHRwOi8vc3Yuc3ltY2QuY29tMCYGCCsGAQUF
# BzAChhpodHRwOi8vc3Yuc3ltY2IuY29tL3N2LmNydDAfBgNVHSMEGDAWgBSWO1Pw
# eTOXr32D7y4rzMq3hh5yZjAdBgNVHQ4EFgQUlelWRKcMMuDX80+oWbXEPaHUd7sw
# DQYJKoZIhvcNAQELBQADggEBAIaGfEvw4rJgaEDow3Aea6Fg4LGxAtezhs6bjDZi
# h/IJdcWV1nEc/uhZ5XegmRXn3LaP2RL+ZHmjWrQxv4/aK/ZCFxBV0omny3VnIXsY
# UldnW8589S3a83Dtb3cpF+P57M8Z+Fwt+gyvQJYAyDrpMvgMdOotVFWUVVDESXV/
# ttYmhg3MC0ZLuWHREKR9Jrqe9aFjjbGbQlb8jKBOBDPSykjR2nnb5lBgXyfDG9Gf
# zfzz/ed2V95/NSyk2RQD3Wo/IiR/TMABuJEXzsGIMBGSHe6Yz58IxXox4WNyn26o
# 8NklVx6UVsquwXFANU0b4Z/FDTt0cr4PjxNb/Ww/ogKdSBMwggVZMIIEQaADAgEC
# AhA9eNf5dklgsmF99PAeyoYqMA0GCSqGSIb3DQEBCwUAMIHKMQswCQYDVQQGEwJV
# UzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsTFlZlcmlTaWduIFRy
# dXN0IE5ldHdvcmsxOjA4BgNVBAsTMShjKSAyMDA2IFZlcmlTaWduLCBJbmMuIC0g
# Rm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxRTBDBgNVBAMTPFZlcmlTaWduIENsYXNz
# IDMgUHVibGljIFByaW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkgLSBHNTAe
# Fw0xMzEyMTAwMDAwMDBaFw0yMzEyMDkyMzU5NTlaMH8xCzAJBgNVBAYTAlVTMR0w
# GwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMg
# VHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xhc3MgMyBTSEEyNTYg
# Q29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# l4MeABavLLHSCMTXaJNRYB5x9uJHtNtYTSNiarS/WhtR96MNGHdou9g2qy8hUNqe
# 8+dfJ04LwpfICXCTqdpcDU6kDZGgtOwUzpFyVC7Oo9tE6VIbP0E8ykrkqsDoOatT
# zCHQzM9/m+bCzFhqghXuPTbPHMWXBySO8Xu+MS09bty1mUKfS2GVXxxw7hd924vl
# YYl4x2gbrxF4GpiuxFVHU9mzMtahDkZAxZeSitFTp5lbhTVX0+qTYmEgCscwdyQR
# TWKDtrp7aIIx7mXK3/nVjbI13Iwrb2pyXGCEnPIMlF7AVlIASMzT+KV93i/XE+Q4
# qITVRrgThsIbnepaON2b2wIDAQABo4IBgzCCAX8wLwYIKwYBBQUHAQEEIzAhMB8G
# CCsGAQUFBzABhhNodHRwOi8vczIuc3ltY2IuY29tMBIGA1UdEwEB/wQIMAYBAf8C
# AQAwbAYDVR0gBGUwYzBhBgtghkgBhvhFAQcXAzBSMCYGCCsGAQUFBwIBFhpodHRw
# Oi8vd3d3LnN5bWF1dGguY29tL2NwczAoBggrBgEFBQcCAjAcGhpodHRwOi8vd3d3
# LnN5bWF1dGguY29tL3JwYTAwBgNVHR8EKTAnMCWgI6Ahhh9odHRwOi8vczEuc3lt
# Y2IuY29tL3BjYTMtZzUuY3JsMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcD
# AzAOBgNVHQ8BAf8EBAMCAQYwKQYDVR0RBCIwIKQeMBwxGjAYBgNVBAMTEVN5bWFu
# dGVjUEtJLTEtNTY3MB0GA1UdDgQWBBSWO1PweTOXr32D7y4rzMq3hh5yZjAfBgNV
# HSMEGDAWgBR/02Wnwt3su/AwCfNDOfoCrzMxMzANBgkqhkiG9w0BAQsFAAOCAQEA
# E4UaHmmpN/egvaSvfh1hU/6djF4MpnUeeBcj3f3sGgNVOftxlcdlWqeOMNJEWmHb
# cG/aIQXCLnO6SfHRk/5dyc1eA+CJnj90Htf3OIup1s+7NS8zWKiSVtHITTuC5nmE
# FvwosLFH8x2iPu6H2aZ/pFalP62ELinefLyoqqM9BAHqupOiDlAiKRdMh+Q6EV/W
# pCWJmwVrL7TJAUwnewusGQUioGAVP9rJ+01Mj/tyZ3f9J5THujUOiEn+jf0or0oS
# vQ2zlwXeRAwV+jYrA9zBUAHxoRFdFOXivSdLVL4rhF4PpsN0BQrvl8OJIrEfd/O9
# zUPU8UypP7WLhK9k8tAUITGCBEQwggRAAgEBMIGTMH8xCzAJBgNVBAYTAlVTMR0w
# GwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMg
# VHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xhc3MgMyBTSEEyNTYg
# Q29kZSBTaWduaW5nIENBAhASn/W83LmZkqPf6+aeK2mOMAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBTTIVux4IQpmT355GfcoXpkY+nJTjANBgkqhkiG9w0BAQEFAASCAQAjaOTWJr6U
# OHXdm0wlV9GPw93TBstDSUoyMc9WHZ8ScqhZbFwOgo1z+k7UQ1aKcVTWN6QjK0P9
# Fm/jj5sPBAEqWJPmUFIwdzlNGa82MBqfHF0WYYK8qJwvEXrcLOKIMqtGmKPK4Thz
# 8YOggTFEj+qNlcjLhTWPJy6fRQ4kXOKukGUii1jQYg1zDpFSaR79GQKjP0hIQghL
# 3v9+kWF246y1VuvjcPBpqtrELvEmEjeY3+l2uh6NPln/oH/jFm9e0BOBolq6riQv
# 6yliQ4qJziUk6OlCQmF9HkdO19cgWY+veHVVyu/OdzrHJW3aCIIHauE+wb/dEwYo
# T2IoSjM5PGLloYICCzCCAgcGCSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkG
# A1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQD
# EydTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI
# /r81bgTYapgbGlAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0B
# BwEwHAYJKoZIhvcNAQkFMQ8XDTE2MTEyODEwMTU0M1owIwYJKoZIhvcNAQkEMRYE
# FN+d25GHpMTrYx+EDGDVFXWdJgpqMA0GCSqGSIb3DQEBAQUABIIBAAahV6Yurdch
# W/JBI/aUcwVu5eC4XfO+idipjPVXyTRZLzjapJKbn9XZft7WhpqZ9WtYsWX2xVUF
# 1UXDXrnQ/eXSLJmBhp0e6FugAhbMnnANVa27K8jU+b54bF7kwlfcai7jk5qYb61Z
# ouP7E1ouB0Y1MKtA287qeaGEAat76adDadJmSTOuSKazZXF7KqqdLu/vBBzpG/5s
# rJhoROcCpXV/k+odtW/KiP0R4/lFeeBBpwgSVZ+dDw8co+qcwE8Oq9+/Dupl7Nhc
# g4WKIVuoih3h9s5Hs1VlUzhj30+DDEPLVRcgsWPdZ6LtunzkIkQNFRI97vvnlkzE
# luZmD9UEyiE=
# SIG # End signature block
