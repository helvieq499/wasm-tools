# wasm-tools
Tools I have written in/for WebAssembly

1. [wasm-attach](#wasm-attach)

## wasm-attach
Attaches a file to a `wasm` module in a custom section, with the section name the same as the file name
```sh
wasmer run ./wasm-attach.wat --dir . -- destination.wasm attachment.txt
```
