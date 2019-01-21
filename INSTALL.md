# INSTALL
##/Users/Shared/GitHub/httpdicom
/Users/Shared/GitHub is the recommended directory where to clone GitHub's httpdicom. If you install it elsewhere, create a symlink in /Users/Shared/GitHub. For instance: 

```bash
mkdir /Users/Shared/GitHub
ln -s /Volumes/IN/GitHub/httpdicom  /Users/Shared/GitHub/httpdicom
```

## /Users/Shared/local/httpdicom
Copy local/httpdicom  into /Users/Shared. For instance:

```bash
cp /Volumes/IN/GitHub/httpdicom/local  /Users/Shared
```

The files within this new directory should be modified with local parameters and will not be affected by GitHub actualizations.
These are:

1. **com.opendicom.httpdicom.launchdeamon.plist** (the modified version needs to be copied into /Library/LaunchDeamons and activated with launchctl)
2. **com.opendicom.httpdicom.watchdog.sh** (which restarts the server in case it would block)
3. **httpdicom** (the binary compiled server. Each actualization GitHub comes with a new bin. The bin can also be compiled locally, opening httpdicom.xcodeproj from the latest version of XCode)

The watchdog looks for httpdicom next to it (in the same folder /Users/Shared/opendicom.). 

If you want the service to always restart with a local compilation of /Users/Shared/GitHub/httpdicom/httpdicom.xcodeproj, replace /Users/Shared/local/httpdicom/httpdicom by a symlink to /Users/Shared/GitHub/httpdicom/local/httpdicom/httpdicom.