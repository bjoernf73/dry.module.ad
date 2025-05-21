# dry.module.ad example
The folder **domain-config** contains an example configuration, and **minimal** another. 

The configurations contains *replacement patterns* that must/will be replaced by variables. Most variables are automatic variables (they will be automatically created based on domain name etc), but the files **domain-config-vars.json** and **minimal-vars.json** contains the missing variables in these example configs. 

Replacements patterns in the configuration files use the pattern '###MyName###'. A variable `{ "name": "MyName", "value": "MyValue"}` will replace '###MyName###' with 'MyValue'. 


## run on a domain controller
Copy Module to a domain controller, then put the example config in some directory, and modify the vars in **domain-config-vars.json** or **minimal-vars.json**.  
```powershell
Import-Module .\path\to\dry.module.ad\dry.module.ad.psd1
Import-DryADConfiguration -ConfigurationPath .\path\to\dry.module.ad\example\domain-config -VariablesPath .\path\to\dry.module.ad\example\domain-config-vars.json -DomainController 'localhost'
```

## run remotely
You may also run over a pssession. 

```powershell
$Credential = Get-Credential -UserName "MYDOMAIN\Administrator" -Message "something"
$PSSession = New-PSSession -ComputerName "<FQDN-to-domain-controller>" -Credential $Credential -UseSsl
Import-Module .\path\to\dry.module.ad\dry.module.ad.psd1
Import-DryADConfiguration -ConfigurationPath .\path\to\dry.module.ad\example\domain-config -VariablesPath .\path\to\dry.module.ad\example\domain-config-vars.json -PSSession $PSSession
```
