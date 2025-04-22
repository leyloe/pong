## Build
```
zig build -Doptimize=ReleaseFast
```
## Help
```
<executable> --help
```
## Singleplayer
```
<executable>
```
## Multiplayer
### Do the following steps in order
#### First, you run
```
<executable> --serve <port>
```
#### Your opponent then runs
```
<executable> --connect <address:port>
```