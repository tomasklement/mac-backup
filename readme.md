# Mac backup tool

Periodically synchronizes one or more directories with another ones. Easy to install and configure.

## Download
You need to have installed git. See [git installation guide](https://github.com/git-guides/install-git#install-git-on-mac).

Go to the installation directory where you store your executables, i.e.:
```bash
cd ~./local/bin
```
Run:
```bash
git clone https://github.com/tomasklement/mac-backup.git && git -C mac-backup submodule update --init --recursive
```
This will create directory "mac-backup" and clone the latest version with its submodules from github.

Check the content of newly created dir:
```bash
cd mac-backup
```

## Configuration
See file `backup_config/sample.conf`

```bash
# Name of backup used in notifications
NAME="My backup"
# Backup source directory. Keep slash at the end to copy directory content
SOURCE_DIR="/Users/john.doe/source/"
# Backup destionation directory
DESTINATION_DIR="/Users/john.doe/backup"
# Time period between the last and the next backup [seconds] (7 days)
INTERVAL=$((3600 * 24 * 7))
```
Copy configuration file for each of your backup dir and change the values. The name of the configuration file is up to you.
```bash
cd mac-backup/backups_config/
cp sample.conf my_backup_1.conf
cp sample.conf my_backup_2.conf
```
## Warning
Some folders like Documents, Downloads etc. are not accessible to backup script. If you want to run backup for any of these folders skip to section **Workaround for backups of restricted folders** and ignore the "Installation" and "Uninstallation" sections.

## Installation
```bash
./install
```
Creates daemon and starts it.

## Upgrade
```bash
./upgrade
```
This will pull the latest version with its submodules from github and restarts the daemon.

## Uninstallation
```bash
./uninstall
```
This will stop and remove daemon.

## Manual run
```bash
./backup myconfig.conf
```
Runs particular backup configured in given config file.
## Restart daemon
```bash
./restart
```
Unloads and loads daemon.

## Workaround for backups of restricted folders
Some folders like Documents, Downloads etc. are not accessible to backup script. To overcome this limitation follow these steps:
### Create automator app
* Run Automator app (installed by default on Mac)
* Create new file (File > New)
* Choose **Application**

![Choose Application](/img/automator_1.png)

* Find **Run Shell Script** and double-click it to create new action

![Find Run Shell Script](/img/automator_2.png)

* Select Shell: `/bin/bash`
* Fill the script content, replace `_path_to_mac_backup_installation_dir_` with absolute path where is your Mac backup downloaded:

```bash
_path_to_mac_backup_installation_dir_/mac-backup/process &>/dev/null &
```
* Save the app as `backup.app` to the `mac-backup` folder

### Add the automator app to login items
* Open **System settings**
* Search for "login items"

![Find Run Shell Script](/img/login_items_1.png)

* Click **+** to add new login item
* Locate your `backup.app` and click **Open**

### Troubleshooting ###
Change the `backup.app` script content by following one and replace `_path_to_mac_backup_installation_dir_` with absolute path where is your Mac backup downloaded):

```bash
_path_to_mac_backup_installation_dir_/mac-backup/process >> _path_to_mac_backup_installation_dir_/mac-backup/backup.log 2>&1
```

Observe `backup.log` in your `mac-backup` folder.