# manymouse-love2d
(WIP) Love2D bindings for manymouse library (https://icculus.org/manymouse/)

A Love2D library enabling support for multiple mice.

## Requirements
Love2D or LuaJIT (The library uses LuaJIT FFI)
You need to compile the manymouse C library as a shared library yourself (https://icculus.org/manymouse/) and place it in the repo folder.
For example, in Linux:

```bash
git clone https://github.com/NoobsArePeople2/manymouse && cd manymouse
gcc -c -fpic *.c
gcc -shared -o libmanymouse.so *.o
```
although using a Makefile would be nicer when trying to support multiple platforms.

## Notes
Works on Linux(XInput2), both trackpad and mice.

## Usage
You can import the ManyMouse object, which is a thin wrapper around the original C functions. 
```lua
local ManyMouse = require("manymouse")
```

Also, there is a more convenient manager object called MouseManager.
```lua
local mouseMgr = ManyMouse.createMouseManager(love.graphics.getWidth(), love.graphics.getHeight())
```

Its usage is shown in the [example source code](main.lua).

## License
MIT License

## Libraries used:
- struct.lua (http://lua-users.org/wiki/StrictStructs)
