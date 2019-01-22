# INSTALL

##/Users/Shared/GitHub/httpdicom

/Users/Shared/GitHub is the recommended directory where to clone GitHub's httpdicom.

## /Users/Shared/local/httpdicom
Copy local/httpdicom  into /Users/Shared. For instance:

```bash
cp -R /Users/Shared/GitHub/httpdicom/deploy/local /Users/Shared
```

The files within this new directory should be modified with local parameters and will not be affected by GitHub actualizations.
These are:

1. **com.opendicom.httpdicom.launchdeamon.plist** (the modified version needs to be copied into /Library/LaunchDeamons and activated with launchctl)
2. **com.opendicom.httpdicom.watchdog.sh** (which restarts the server in case it would block)
3. **httpdicom** (the binary compiled server. Each actualization GitHub comes with a new bin. The bin can also be compiled locally, opening httpdicom.xcodeproj from the latest version of XCode)
4. **CocoaRestClient.bin.plist** (to be imported in CocoaRestClient.app para realizar pruebas de los servicios)

The watchdog looks for httpdicom next to it (in the same folder /Users/Shared/opendicom.). 

If you want the service to always restart with a local compilation of /Users/Shared/GitHub/httpdicom/httpdicom.xcodeproj, replace /Users/Shared/local/httpdicom/httpdicom by a symlink to /Users/Shared/GitHub/httpdicom/local/httpdicom/httpdicom.

```bash
rm -f /Users/Shared/local/httpdicom/httpdicom
ln -s /Users/Shared/GitHub/httpdicom/local/httpdicom/httpdicom  /Users/Shared/local/httpdicom
```

##Ways to startup

1. XCode, so that you can use debug tools. Adapt the args in the GUI.
2. comand line 

```bash
cd /Users/Shared/local/httpdicom
./httpdicom 1.3.6.1.4.1.23650.152.0.2.737765846967 11124 DEBUG +0300
```

3. Adapting and copying com.opendicom.httpdicom.launchdeamon.plist to /Library/launchdeamons and using launchctl
