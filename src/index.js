'use strict';
/*
The MIT License

Copyright (c) 2020 Marc Chambon. WestLangley and mrdoob for the 'decompose' function
Inspired from the ThreeJs Matrix4 library : https://github.com/mrdoob/three.js/blob/dev/src/math/Matrix4.js

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

WARNING: matrices in this libray follow the COLUMN-MAJOR convention: values are given by columns instead of rows.
For instances: if you set your matrice with this array : [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
* row-major convention (the one taught at school):

    0   1   2   3
    4   5   6   7
    8   9   10  11
    12  13  14  15

* column-major convention (the OpenGL convention and the one of this library):

    0   4   8   12
    1   5   9   13
    2   6   10  14
    3   7   11  15

Matrices in this library are using 4-bytes values (f32).
A matrix is defined by a "slot", a integer which represents where its values are stored
in the WebAssembly Memory buffer "buffer" (16 * 4 bytes = 64 bytes)
matrixArray = Float32Array(buffer, slot * 64, 16)
*/

import standardModule from '../standard.wasm';
import simdModule from '../simd.wasm';

const defaultOptions = {
	// experimental feature : garbage collection awareness (no need to call matrix.free(), but a specific call is required when creating a new matrix
	// like this : let mat = new Mat();g(mat, _ => h(mat));
	autoFree: false,
	simd: false,
	autodetect: false,
	maxMatrices: 982,
	/* one slot = 16 times 4-byte = 64 bytes of memory. Memory before the one used by matrices is called reserved memory
	(here 42 * 64 bytes = 2688 bytes available for processing vectors inside for specific operations.
	Warning: nothing automatically prevents the utility functions to manipulate memory above and corrupt matrices! */
	matrixStartingSlot: 42,
};

let temp;
let maxIndex;

let firstArgType;

const defaultArray = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
const defaultVector = { x: 1, y: 1, z: 1 };

const defaultQuaternion = { _x: 1, _y: 1, _z: 1, _w: 1 };

const defaultEuler = { x: 1, y: 1, z: 1, isEuler: 'XYZ' };
const eulerMap = {
	XYZ: 0,
	YXZ: 1,
	ZXY: 2,
	ZYX: 3,
	YZX: 4,
	XZY: 5,
};

// helper functions for memory management
function trueFunc() {
	return true;
}
function falseFunc() {
	return false;
}

export default function ftbMatrix(opt = defaultOptions) {
	const options = { ...defaultOptions, ...opt };
	const { autoFree = false, maxMatrices = 982, matrixStartingSlot = 42 } = options;
	const max = maxMatrices + matrixStartingSlot;
	// pages: WebAssembly pages allocated for matrix storage.
	const pages = Math.ceil(((parseInt(maxMatrices, 10) + matrixStartingSlot) * 64) / 65536);
	const mem = new WebAssembly.Memory({ initial: pages });
	const buffer = mem.buffer;

	let start;
	const slotToTypedArrayMap = {};
	const isAllocated = {};
	let currentMemorySlot = matrixStartingSlot;
	let garbageCollectionChecker;
	let g;
	let h;
	if (autoFree) {
		garbageCollectionChecker = new WeakMap();
		h = WeakMap.prototype.has.bind(garbageCollectionChecker);
		g = function g(matrix, isGarbageCollected = trueFunc) {
			garbageCollectionChecker.set(matrix);
			isAllocated[matrix.slot] = isGarbageCollected;
		};
	}

	async function matFactory() {
		const WasmImportObject = { '': { mem } };
		let exports;
		if (options.autodetect || options.simd) {
			try {
				({
					instance: { exports },
				} = await simdModule(WasmImportObject));
				console.info('ftb-matrix: successfully using SIMD for faster calculations.');
			} catch (error) {
				if (!options.autodetect) {
					console.error('ftb-matrix: does your platform really support SIMD ?');
					console.error(error);
				} else {
					({
						instance: { exports },
					} = await standardModule(WasmImportObject));
				}
			}
		} else {
			({
				instance: { exports },
			} = await standardModule(WasmImportObject));
		}
		const { identity_d, copy, copyPos, mul } = exports;
		const reservedMemory = new Float32Array(buffer, 0, matrixStartingSlot * 16);
		for (let i = matrixStartingSlot; i < max; i++) {
			// matrix indices 0 to 42 reserved as an internal temporary storage for various structures..
			isAllocated[i] = falseFunc;
			slotToTypedArrayMap[i] = new Float32Array(buffer, i << 6, 16);
		}

		function Mat(numberOrObjOrFunc, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $opt) {
			/* If one uses the experimental garbage collection awareness feature (GCA), all the slots must be checked from
			the start to find a free one */
			start = autoFree ? matrixStartingSlot : currentMemorySlot;

			for (let i = start; i < max; i++) {
				if (!isAllocated[i]()) {
					currentMemorySlot = i;
					break;
				} else if (i === maxMatrices) {
					throw Error(`ftb-matrix: Not enough allocated memory: please use the 'maxMatrices' option.`);
				}
			}
			// if GCA, set a key in the garbageCollectionChecker WeakMap with the current matrix
			autoFree && garbageCollectionChecker.set(this, null);
			this.slot = currentMemorySlot;
			this.dimension = 4;
			isAllocated[currentMemorySlot] = trueFunc;
			firstArgType = typeof numberOrObjOrFunc;
			if (firstArgType === 'function') {
				// create new matrix from a function
				numberOrObjOrFunc(currentMemorySlot, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $opt);
			} else if (firstArgType === 'object' && typeof numberOrObjOrFunc.slot === 'number') {
				// create new matrix from existing one
				this.copy(numberOrObjOrFunc, this);
			} else if (firstArgType === 'number') {
				// create new matrix from separated values
				this.init(numberOrObjOrFunc, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15);
			} else {
				identity_d(currentMemorySlot);
			}

			this[Symbol.toPrimitive] = function(hint) {
				if (hint === 'string') {
					return slotToTypedArrayMap[this.slot].toString();
				} else if (hint === 'number') {
					this.determinant();
				} else {
					return `Matrix slot number: ${this.slot}`;
				}
			};
		}

		Mat.prototype.free = function() {
			isAllocated[this.slot] = falseFunc;
			if (!autoFree) currentMemorySlot = this.slot;
		};

		Mat.prototype.multiply = function(mat) {
			copy(this.slot, 0);
			mul(0, mat.slot, this.slot);
			return this;
		};

		Mat.prototype.premultiply = function(mat) {
			copy(this.slot, 0);
			mul(mat.slot, 0, this.slot);
			return this;
		};

		Mat.prototype.multiplyMatrices = function(mat1, mat2) {
			mul(mat1.slot, mat2.slot, this.slot);
			return this;
		};

		// Map WebAssembly functions to API
		for (let rawFuncName of Object.keys(exports)) {
			const arr = rawFuncName.split('_');
			const funcName = arr[0];
			if (arr.length > 1) {
				const type = arr[arr.length - 1];
				if (type === 'd') {
					// case of functions operating on a single memory slot
					Mat.prototype[funcName] = function(
						$0,
						$1,
						$2,
						$3,
						$4,
						$5,
						$6,
						$7,
						$8,
						$9,
						$10,
						$11,
						$12,
						$13,
						$14,
						$15,
						$opt
					) {
						const result = exports[rawFuncName].call(
							this,
							this.slot,
							$0,
							$1,
							$2,
							$3,
							$4,
							$5,
							$6,
							$7,
							$8,
							$9,
							$10,
							$11,
							$12,
							$13,
							$14,
							$15,
							$opt
						);
						return typeof result === 'undefined' ? this : result;
					};
					Mat[funcName] = function($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $opt) {
						return new Mat(
							exports[rawFuncName],
							$0,
							$1,
							$2,
							$3,
							$4,
							$5,
							$6,
							$7,
							$8,
							$9,
							$10,
							$11,
							$12,
							$13,
							$14,
							$15,
							$opt
						);
					};
				} else if (type === 'u') {
					// case of utility functions, not specific to matrices
					Mat.prototype[funcName] = exports[rawFuncName];
					Mat[funcName] = Mat.prototype[funcName];
				}
			}
		}

		Mat.prototype.copyPosition = function(srcMat) {
			copyPos(srcMat.slot, this.slot);
			return this;
		};

		Mat.prototype.fromArray = function(array = defaultArray, offset = 0) {
			for (let i = 0; i < 16; i++) slotToTypedArrayMap[this.slot] = array[i + offset];
			return this;
		};
		Mat.fromArray = function(array = defaultArray, offset = 0) {
			temp = new Mat();
			for (let i = 0; i < 16; i++) slotToTypedArrayMap[temp.slot] = array[i + offset];
			return temp;
		};

		// Warning: set method arguments are a row-major exception!
		Mat.prototype.set = function set($0, $4, $8, $12, $1, $5, $9, $13, $2, $6, $10, $14, $3, $7, $11, $15) {
			Object.assign(slotToTypedArrayMap[this.slot], [
				$0,
				$1,
				$2,
				$3,
				$4,
				$5,
				$6,
				$7,
				$8,
				$9,
				$10,
				$11,
				$12,
				$13,
				$14,
				$15,
			]);
		};

		Mat.prototype.init = function init($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15) {
			if (typeof $15 === 'number') {
				Object.assign(slotToTypedArrayMap[this.slot], [
					$0,
					$1,
					$2,
					$3,
					$4,
					$5,
					$6,
					$7,
					$8,
					$9,
					$10,
					$11,
					$12,
					$13,
					$14,
					$15,
				]);
			} else if (typeof $4 === 'undefine') {
				// case of dimension 2 matrix, only 4 values
				this.dimension = 2;
				Object.assign(slotToTypedArrayMap[this.slot], [$0, $1, 0, 0, $2, $3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
			} else if (typeof $9 === 'undefine') {
				// case of dimension 3 matrix, only 9 values
				this.dimension = 3;
				Object.assign(slotToTypedArrayMap[this.slot], [$0, $1, $2, 0, $3, $4, $5, 0, $6, $7, $8, 0, 0, 0, 0, 0]);
			}
			return this;
		};
		Mat.prototype.clone = function(srcMat) {
			copy(srcMat.slot, this.slot);
			return this;
		};

		Mat.prototype.compose = function(position = defaultVector, quaternion = defaultQuaternion, scale = defaultVector) {
			exports.compose(
				this.slot,
				position.x,
				position.y,
				position.z,
				quaternion._x,
				quaternion._y,
				quaternion._z,
				quaternion._w,
				scale.x,
				scale.y,
				scale.z
			);
			return this;
		};

		Mat.prototype.equals = function(mat) {
			if (exports.equals(this, mat)) return true;
			return false;
		};

		Mat.prototype.decompose = function(
			position = defaultVector,
			quaternion = defaultQuaternion,
			scale = defaultVector
		) {
			// TODO : move code to WebAssembly
			temp = this.slot << 6; // matrix memory offset
			scale.x = exports.norm_u(temp);
			scale.y = exports.norm_u(temp + 16);
			scale.z = exports.norm_u(temp + 32);
			if (this.determinant() < 0) scale.x = -scale.x;

			temp = slotToTypedArrayMap[this.slot];
			position.x = temp[12];
			position.y = temp[13];
			position.z = temp[14];

			const mat = new Mat(this); // copy matrix
			const invScaleX = 1 / scale.x;
			const invScaleY = 1 / scale.y;
			const invScaleZ = 1 / scale.z;
			temp = slotToTypedArrayMap[mat.slot];
			temp[0] *= invScaleX;
			temp[1] *= invScaleX;
			temp[2] *= invScaleX;
			temp[4] *= invScaleY;
			temp[5] *= invScaleY;
			temp[6] *= invScaleY;
			temp[8] *= invScaleZ;
			temp[9] *= invScaleZ;
			temp[10] *= invScaleZ;
			// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
			// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
			if (temp[0] + temp[5] + temp[10] > 0) {
				const s = 0.5 / Math.sqrt(1 + temp[0] + temp[5] + temp[10]);
				quaternion._x = s * (temp[6] - temp[9]);
				quaternion._y = s * (temp[8] - temp[2]);
				quaternion._z = s * (temp[1] - temp[4]);
				quaternion._w = 0.25 / s;
			} else if (temp[0] > temp[5] && temp[0] > temp[10]) {
				const invS = 0.5 / Math.sqrt(1 + temp[0] - temp[5] - temp[10]);
				quaternion._x = 0.25 / invS;
				quaternion._y = invS * (temp[4] + temp[1]);
				quaternion._z = invS * (temp[8] + temp[2]);
				quaternion._w = invS * (temp[6] - temp[9]);
			} else if (temp[5] > temp[10]) {
				const invS = 0.5 / Math.sqrt(1 + temp[5] - temp[0] - temp[10]);
				quaternion._x = invS * (temp[4] + temp[1]);
				quaternion._y = 0.25 / invS;
				quaternion._z = invS * (temp[9] + temp[6]);
				quaternion._w = invS * (temp[8] - temp[2]);
			} else {
				const invS = 0.5 / Math.sqrt(1 + temp[10] - temp[0] - temp[5]);
				quaternion._x = invS * (temp[1] - temp[4]);
				quaternion._y = invS * (temp[9] + temp[6]);
				quaternion._z = 0.25 / invS;
				quaternion._w = invS * (temp[1] - temp[4]);
			}
			mat.free();
			return this;
		};

		Mat.prototype.copy = function(srcMat, dstMat) {
			if (dstMat) {
				copy(srcMat.slot, dstMat.slot);
			} else {
				copy(srcMat.slot, this.slot);
			}
			return this;
		};

		Mat.prototype.extractBasis = function(vector1 = defaultVector, vector2 = defaultVector, vector3 = defaultVector) {
			// 3d vectors with x, y, z number attributes.
			temp = slotToTypedArrayMap[this.slot];
			vector1.x = temp[0];
			vector1.y = temp[1];
			vector1.z = temp[2];
			vector2.x = temp[4];
			vector2.y = temp[5];
			vector2.z = temp[6];
			vector3.x = temp[8];
			vector3.y = temp[9];
			vector3.z = temp[10];
			return this;
		};

		Mat.prototype.extractRotation = function(mat) {
			exports.extractRotation(this.slot, mat.slot);
			return this;
		};

		Mat.prototype.makeRotationFromQuaternion = function(quaternion = defaultQuaternion) {
			exports.compose(this.slot, 0, 0, 0, quaternion._x, quaternion._y, quaternion._z, quaternion._w, 1, 1, 1);
			return this;
		};

		Mat.prototype.makeRotationFromEuler = function(euler = defaultEuler) {
			temp = eulerMap[euler.isEuler || 'XYZ'];
			exports.makeRotationFromEuler(this.slot, euler.x, euler.y, euler.z, temp);
			return this;
		};

		Mat.prototype.getInverse = function(mat) {
			exports.getInverse(this.slot, mat.slot);
			return this;
		};

		Mat.prototype.equals = function(mat) {
			return exports.equals(this.slot, mat.slot) ? true : false;
		};

		Object.defineProperty(Mat.prototype, 'elements', {
			get() {
				if (this.dimension === 4) {
					return slotToTypedArrayMap[this.slot];
				} else if (this.dimension === 3) {
					temp = slotToTypedArrayMap[this.slot];
					return [temp[0], temp[1], temp[2], temp[4], temp[5], temp[6], temp[8], temp[9], temp[10]];
				} else if (this.dimension === 2) {
					temp = slotToTypedArrayMap[this.slot];
					return [temp[0], temp[1], temp[4], temp[5]];
				}
			},
		});

		Mat.prototype.fromArray = function fromArray(array = [], offset = 0) {
			temp = slotToTypedArrayMap[this.slot];
			if (this.dimension === 4) {
				maxIndex = 16;
				for (let i = 0; i < 16; i++) {
					temp[i] = array[offset + i];
				}
			}
			return this;
		};

		Mat.prototype.toArray = function toArray(array = [], offset = 0) {
			temp = slotToTypedArrayMap[this.slot];
			if (this.dimension === 4) {
				maxIndex = 16;
			} else if (this.dimension === 3) {
				maxIndex = 9;
			} else {
				maxIndex = 4;
			}
			for (let i = 0; i < maxIndex; i++) {
				array[offset + i] = temp[i];
			}
			return array;
		};

		Mat.reservedMemory = reservedMemory;

		return Mat;
	}
	if (autoFree) {
		return {
			matFactory,
			g,
			h,
		};
	}
	return { matFactory };
}
