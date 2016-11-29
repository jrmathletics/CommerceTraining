param($installPath, $toolsPath, $package, $project)

#Import Modules
Import-Module (Join-Path $toolsPath "Copy-DB.psm1")
Import-Module (Join-Path $toolsPath "Copy-EcfConfigsIfNotExist.psm1")
Import-Module (Join-Path $toolsPath "Get-Config.psm1")
Import-Module (Join-Path $toolsPath "Get-ConfigPath.psm1")
Import-Module (Join-Path $toolsPath "Get-ConnectionConfigPath.psm1")
Import-Module (Join-Path $toolsPath "Get-EPiServerCommerceConnectionString.psm1")
Import-Module (Join-Path $toolsPath "Get-PackagesToolPath.psm1")
Import-Module (Join-Path $toolsPath "Set-CommerceManagerSearchIndexBasePath.psm1")
Import-Module (Join-Path $toolsPath "Set-NameSpace.psm1")

Function Get-InstalledPackage
{
	param ([string]$projectName, [string]$packageId)

	return Get-Package -ProjectName $projectName | Where-Object { $_.id -eq $packageId} | Sort-Object -Property Version -Descending | Select-Object -First 1
}

$projectFilePath = Get-ChildItem $project.Fullname

$sitePath = $projectFilePath.Directory.FullName

$WebConfigFile = Get-ConfigPath $project

$epiConnection = Get-EPiServerCommerceConnectionString($WebConfigFile)
if ($epiConnection -eq $null)
{
	Write-Host "Starting Deploy into $($project.ProjectName)"

	#Get the Framework package
	$frameworkPackage = Get-InstalledPackage $project.ProjectName "EPiServer.Framework"

	# Get EPiDeploy.exe Path
	$frameworkToolPath = Get-PackagesToolPath $installPath "EPiServer.Framework" $frameworkPackage.Version
	$deployEXEPath = Join-Path ($frameworkToolPath) "epideploy.exe"

	$episerverWebConfig = Join-Path $toolsPath "EPiServer.Commerce.config"
	# Deploy Web Config
	&$deployEXEPath  -a config -s $sitePath  -p $episerverWebConfig

	# Make unique DB name
	$seed = [GUID]::NewGuid()
	$uniqueDB = "EcfSqlConnection_" + $seed.ToString("N").Substring(0,8)

	# Copying DB -> App_Data
	Write-Host "Copying $($uniqueDB) To $($project.ProjectName) -> App_Data"
	$emptyMdfFile = Join-Path $toolsPath "EPiServer.Commerce.mdf"

	Copy-DB $toolsPath $sitePath "$($uniqueDB).mdf" $emptyMdfFile

	$connectionPath = Get-ConnectionConfigPath $sitePath
	$connectionContent = Get-Content -Path $connectionPath

    # Modify ConnectionString if version only supports LocalDB\v11.0
    $vsVersion = [System.Version]::Parse($project.DTE.Version)
    $localDBDataSource = if ($vsVersion.Major -lt 14) { "(LocalDb)\v11.0" } else { "(LocalDb)\MSSQLLocalDB" }
    $connectionContent = $connectionContent -replace "{LocalDB_DataSource}", $localDBDataSource

	# Modify ConnectionString according to seed
	$connectionContent = $connectionContent -replace "{EcfSqlConnection_SEED}", $uniqueDB

	Set-Content $connectionContent -path $connectionPath

	$commerceCorePackage = $frameworkPackage = Get-InstalledPackage $project.ProjectName "EPiServer.Commerce.Core"
	$commerceCoreToolsPath = Get-PackagesToolPath $installPath "EPiServer.Commerce.Core" $commerceCorePackage.Version
	$commerceCoreDbPath = Join-Path ($commerceCoreToolsPath) "EPiServer.Commerce.Core.sql"

	#Update search config
	$searchConfigPath = Join-Path $toolsPath "Configs\Mediachase.Search.Config"
	$searchIndexBasePath = "[appDataPath]\Search\ECApplication\"
	$searchConfig = Get-Config $searchConfigPath
	Set-CommerceManagerSearchIndexBasePath $searchConfig $searchIndexBasePath
	$searchConfig.Save($searchConfigPath)

    #Copy ecf Configs to the site if not exist
	Copy-EcfConfigsIfNotExist $project $toolsPath $sitePath

	# Modify initialization module namespace
    $infrastructureSourcePath = Join-Path $toolsPath ".\Infrastructure"
	$infrastructurePath = Join-Path $sitePath "\Infrastructure"
	if (-Not (Test-Path $infrastructurePath))
	{
		Copy-Item $infrastructureSourcePath $infrastructurePath -Recurse
		Add-ProjectItems $project $infrastructurePath
	}
	$initializationModulePath = Join-Path $sitePath "\Infrastructure\InitializationModule.cs"
	Set-NameSpace $initializationModulePath $project.Properties.Item("DefaultNamespace").Value.ToString();

	# Run Script
	Write-Host "Running $($commerceCoreDbPath) into $($uniqueDB)"
	&$deployEXEPath -a sql -s $sitePath -p $commerceCoreDbPath -v false -c "EcfSqlConnection"

	Write-Host "EPiServer.Commerce is installed"
}

# SIG # Begin signature block
# MIIXpAYJKoZIhvcNAQcCoIIXlTCCF5ECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUk8ViwhUY1k2BAuySYUVdvz9M
# e62gghLKMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# BBS7bSPjxYXG7gg3xTv92zAkuHGtGzANBgkqhkiG9w0BAQEFAASCAQB3q/pL11hw
# msMSu/EPP54wnecJTqHa3zCWV6sIUBhdiSfX3/RREn11T7lGxZ7Sw0+hXBeGQxD5
# Sn5KAFFD1wk2NMMFHdT3Bog/lJFNuZKtb7m38qOsGM3LgAPS+VoeRX1M+yjI3Vq6
# HQGb5ATPCcrG28bZwOFyLOBrAPQXV9TkQSa/qfZB7JX+6Nhh0+zhr9RRYRMWuuX2
# 7gOKDpybq30n4vJkWr9jxd8gz0u2tKcqY7dF70yA/ht9iCvrdXRQvfJgSKEim24/
# RfnFmeNzhna1I+NA+BmWVMj/8tk1CZSjNkHrCLF3aezMqaVj3d7Y5LjoImUU8qqt
# vu/n/1lkXoByoYICCzCCAgcGCSqGSIb3DQEJBjGCAfgwggH0AgEBMHIwXjELMAkG
# A1UEBhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTAwLgYDVQQD
# EydTeW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIENBIC0gRzICEA7P9DjI
# /r81bgTYapgbGlAwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0B
# BwEwHAYJKoZIhvcNAQkFMQ8XDTE2MTEyODEwMTU0NVowIwYJKoZIhvcNAQkEMRYE
# FGrLEKfyotC4x07OVWmzy1y3fPGwMA0GCSqGSIb3DQEBAQUABIIBAEmvlaPy17D/
# +tOA0KtAkjOCIAkUSZYE/VLC/s/C3Ls30NZnqcJ5EPRtqhf+SeiJvPHcVknmwkOq
# h/WkFch8F4GPt0XsGm7rKQytdY++c0w6YE3y8RI7GvhrRMbyYDLQAJ13uHw3X+/Q
# sGgYctd9CFgCYhZqBCc6W9IWPLTYn20h3d9WH9+iSscWMXELgN2/nNYCGp0TSlmZ
# veISByp55tb4R1mV3D5f1UM1xP/GuAq/CitA1bYq49M3DHudhiUVwI2AMVRue+a+
# qunBNObx4x5nhIbFOEN9olXE6GwlDsovi26S579QVCzCeH/SkN+hYMxOtOH1ctIA
# D53dZOcv+8E=
# SIG # End signature block
