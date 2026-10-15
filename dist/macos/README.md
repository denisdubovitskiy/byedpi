# Installing on macOS

## Building

Xcode Command Line Tools are required (`xcode-select --install`).

```sh
cd byedpi/
make
```

## LaunchAgent (optional)

You can run ciadpi as a user LaunchAgent, no root required.

Either set it up manually: edit `byedpi.plist` — set the full path to the
`ciadpi` binary and add your options as `<string>` arguments — then:

```sh
cp byedpi.plist ~/Library/LaunchAgents/com.user.ciadpi.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.user.ciadpi.plist
```

Or use the helper scripts, which do the same (render the plist from the
template, install the binary to `~/.local/bin`, reload the agent):

```sh
./install.sh                                        # default preset: --disorder 1 --auto=torst --tlsrec 1+s
./install.sh --split 2 --auto=torst --disorder 1    # custom options
./socks.sh on|off|status                            # system SOCKS proxy via networksetup
./uninstall.sh [--purge]                            # unload the agent (--purge also removes the binary)
```

Logs are written to `~/Library/Logs/ciadpi.log`.

Note: `--fake` and related options are not supported on macOS
(see the main README).
