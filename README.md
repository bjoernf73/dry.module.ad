# dry.module.ad

For in-depth documentation, checkout the [wiki](https://github.com/bjoernf73/dry.module.ad/wiki).

## Features
dry.module.ad is a module for configuration of Active Directory objects, namely
- Creation of OU hierarchies
- Creation of AD groups of any type
- Group nesting (groups' group memberships)
- Rights on AD objects (acl's on any object in any AD naming context)
- GPO imports with migrations
  - native support for backup-GPO's
  - support for *automigrating json-GPOs* 
- GPO links (supports replacement of *lower-versioned-GPO's* with *higher-versioned-GPO's* of versioning formats `v1.2.3` and `v1r2`)
- WMI Filter creation 
- WMI Filter links on GPOs
- AD Schema extensions (from ldf-files) 
- Netlogon files (recursive copy of everything in your configuration's *netlogon* folder to your domain's NETLOGON) 
- Administrative Templates (copies everything in your configuration's *adm_templates* folder to *PolicyDefintions* on SYSVOL) 
- Creation of users
- Users' group memberships 

## Configuration files
`dry.module.ad` takes a folder with one or multiple json-files as input, converting the defined objects to configurations in Active Directory. Some configurations are file based (netlogon files, administrative templates, backup- and json-gpos import, and AD schema extensions). 

## Local-run vs Remote-run
You may run the `Import-DryADConfiguration` either 
- locally (local-run) with the privileges of the logged on identity, or 
- remotely (remote-run), meaning in a PSSession to a domain controller (or to any domain member, as long as you configure it to bypass the second-hop-authentication problem).

Remote-run requires you to establish a PSSession to the target, and passing the session to `Import-DryADConfiguration`:
```powershell
Import-Module dry.module.ad
# The ActiveDirectory module wmay warn about unable to connect the AD drive - don't mind that.

$cred = Get-Credential -UserName 'dom\admin' -Message 'enter dom\admin`s password'
$sess = New-PSSession -Credential $cred -ComputerName 10.0.5.6

Import-DryADConfiguration -PSSession $sess -ConfigurationPath ..\Some\Folder -VariablesPath ...
```

## Installation

```powershell
Install-Module -Name dry.module.ad
```

## Example
The module contains a couple of example configurations in the `example` folder. The README.md in that folder has instructions on how to run the example configs.  

<br>

# On DryDeploy
The dry.module.ad module is made for *DryDeploy*, more than it is made for standalone use. It is a submodule of a couple of standard action modules of DryDeploy, namely [dry.action.ad.import](https://github.com/bjoernf73/dry.action.ad.import) and [dry.action.ad.move](https://github.com/bjoernf73/dry.action.ad.move). 

*DryDeploy* aspires to do all aspects of automated deployment and configuration of Windows resources 
 - *using*, and not *competing with*, frameworks like Desired State Configuration, Terraform, Ansible, SaltStack, and so on. 

Check out the project [here](https://github.com/bjoernf73/DryDeploy), or clone recursively with 
```
git clone https://github.com/bjoernf73/DryDeploy.git --recurse
``` 