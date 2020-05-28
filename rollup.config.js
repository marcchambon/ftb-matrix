import { terser } from 'rollup-plugin-terser';
import wasm from '@rollup/plugin-wasm';

export default {
	input: 'src/index.js',
	plugins: [wasm(), terser()],
	output: {
		file: './dist/ftb-matrix.js',
		format: 'umd',
		name: 'ftbMatrix',
	},
};
