const { readFileSync, writeFileSync } = require('fs');

require('wabt')().then(wabt => {
    let wasmModule = wabt.parseWat('standard.wat', readFileSync('standard.wat', 'utf8'), { simd: true });
    let { buffer } = wasmModule.toBinary({});
    writeFileSync('standard.wasm', Buffer.from(buffer));

    wasmModule = wabt.parseWat('simd.wat', readFileSync('simd.wat', 'utf8'), { simd: true });
    ({ buffer } = wasmModule.toBinary({}));
    writeFileSync('simd.wasm', Buffer.from(buffer));
});

