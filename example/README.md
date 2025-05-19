# dry.module.ad example
The folder **domain-config** contains an example configuration.

The configuration contains *replacement patterns* that must/will be replaced by variables. Most variables are automatic variables (they will be automatically created based on domain name etc), but the file **domain-config-variables.json** contains the missing variables in this example config. 

Replacements patterns in the configuration files use the pattern '###MyName###'. A variable `{ "name": "MyName", "value": "MyValue"}` will replace '###MyName###' with 'MyValue'. 


You can change the values in the file **domain-config-variables.json** or just run as-is to test. This config is just an example, do not run in production. 
```powershell
Import-Module .\path\to\dry.module.ad\dry.module.ad.psd1
Import-DryADConfiguration -$ConfigurationPath .\path\to\dry.module.ad\example\domain-config -VariablesPath .\path\to\dry.module.ad\example\domain-config-variables.json

```