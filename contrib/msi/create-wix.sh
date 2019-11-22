#!/bin/sh

# Get arch from command line if given
PKGARCH=$1

# Check the prerequisite files are in place
test -f yggdrasil.exe || (echo "yggdrasil binary not found"; exit 1)
test -f yggdrasilctl.exe || (echo "yggdrasilctl binary not found"; exit 1)

# Create the postinstall script
cat > config.bat << EOF
if exist yggdrasil.conf (
  move yggdrasil.conf yggdrasil.conf.backup
  yggdrasil.exe -useconffile yggdrasil.conf.backup -normaliseconf > yggdrasil.conf
) else (
  yggdrasil.exe -genconf > yggdrasil.conf
)
EOF

# Work out metadata for the package info
PKGNAME=$(sh contrib/semver/name.sh)
PKGVERSION=$(sh contrib/semver/version.sh --bare)
PKGARCH=${PKGARCH-x64}

# Generate the wix.xml file
cat > wix.xml << EOF
<?xml version="1.0" encoding="windows-1252"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product
    Name="Yggdrasil (${PKGNAME} branch)"
    Id="f1ac3e74-e500-41a5-b35c-fc90a2d95445"
    UpgradeCode="f1ac3e74-e500-41a5-b35c-fc90a2d95445"
    Language="1033"
    Codepage="1252"
    Version="${PKGVERSION}"
    Manufacturer="github.com/yggdrasil-network">

    <Package
      Id="*"
      Keywords="Installer"
      Description="Yggdrasil Network Installer"
      Comments="This is the Yggdrasil Network binary."
      Manufacturer="github.com/yggdrasil-network"
      InstallerVersion="100"
      Languages="1033"
      Compressed="yes"
      SummaryCodepage="1252" />

    <Media
      Id="1"
      Cabinet="Media.cab"
      EmbedCab="yes"
      DiskPrompt="CD-ROM #1" />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder" Name="PFiles">
        <Directory Id="YggdrasilInstallFolder" Name="Yggdrasil">

          <Component Id="MainExecutable" Guid="f1ac3e74-e500-41a5-b35c-fc90a2d95445">
            <File
              Id="Yggdrasil"
              Name="yggdrasil.exe"
              DiskId="1"
              Source="yggdrasil.exe"
              KeyPath="yes" />

            <ServiceInstall
              Id="ServiceInstaller"
              Account="LocalSystem"
              Description="Yggdrasil Network router process"
              DisplayName="Yggdrasil Service"
              ErrorControl="normal"
              LoadOrderGroup="NetworkProvider"
              Name="yggdrasil"
              Start="auto"
              Type="ownProcess"
              Arguments="-autoconf"
              Vital="yes" />

            <ServiceControl
              Id="ServiceControl"
              Name="yggdrasil"
              Start="install"
              Stop="both"
              Remove="uninstall" />
          </Component>

          <Component Id="CtrlExecutable" Guid="f1ac3e74-e500-41a5-b35c-fc90a2d95445">
            <File
              Id="Yggdrasilctl"
              Name="yggdrasilctl.exe"
              DiskId="1"
              Source="yggdrasilctl.exe"
              KeyPath="yes"/>
          </Component>

          <Component Id="ConfigScript" Guid="f1ac3e74-e500-41a5-b35c-fc90a2d95445">
            <File
              Id="Configbat"
              Name="config.bat"
              DiskId="1"
              Source="config.bat"
              KeyPath="yes"/>
          </Component>

        <!--  <Merge Id="Wintun" Language="1033" SourceFile="wintun.msm" DiskId="1" /> -->

        </Directory>
      </Directory>
    </Directory>

    <Feature Id="Complete" Level="1">
      <ComponentRef Id="MainExecutable" />
      <ComponentRef Id="CtrlExecutable" />
      <ComponentRef Id="ConfigScript" />
    </Feature>

    <CustomAction
      Id="UpdateGenerateConfig"
      ExeCommand="config.bat"
      Execute="deferred"
      Return="asyncWait"/>

    <InstallExecuteSequence>
      <Custom
        Action="UpdateGenerateConfig"
        Before="StartServices" />
    </InstallExecuteSequence>

  </Product>
</Wix>
EOF

# Generate the MSI
wixl wix.xml -o yggdrasil.msi
