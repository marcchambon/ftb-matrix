const test = require('tape');
const ftbMatrix = require('../dist/ftb-matrix');

const tolerance = 0.000001;
function areMatricesEqual(mat1, mat2) {
	arr1 = mat1.elements ? mat1.elements : mat1;
	arr2 = mat2.elements ? mat2.elements : mat2;
	if (typeof arr1 === 'undefined' || typeof arr2 === 'undefined') {
		return false;
	}
	for (let i = 0; i < 16; i++) {
		if (Math.abs(arr2[i] - arr1[i]) > tolerance) return false;
	}
	return true;
}

function areValuesEqual(val1, val2) {
	if (Math.abs(val1 - val2) > tolerance) return false;
	return true;
}

function areVectorsEqual(vec1, vec2) {
	if (
		Math.abs(vec1.x - vec2.x) <= tolerance &&
		Math.abs(vec1.y - vec2.y) <= tolerance &&
		Math.abs(vec1.z - vec2.z) <= tolerance
	)
		return true;
	return false;
}

function areQuaternionEqual(vec1, vec2) {
	if (
		Math.abs(vec1._x - vec2._x) <= tolerance &&
		Math.abs(vec1._y - vec2._y) <= tolerance &&
		Math.abs(vec1._z - vec2._z) <= tolerance &&
		Math.abs(vec1._w - vec2._w) <= tolerance
	)
		return true;
	return false;
}

const axisRotMat = [
	0.90987903,
	0.39223227,
	0.1351815,
	0,
	-0.39223227,
	0.70710677,
	0.58834839,
	0,
	0.1351815,
	-0.58834839,
	0.79722774,
	0,
	0,
	0,
	0,
	1,
];

const multiplyMat = [265, 294, 323, 352, 244, 276, 308, 340, 281, 322, 363, 404, 177, 202, 227, 252];
const extractRotationMat = [
	0.26726123,
	0.53452247,
	0.80178368,
	0,
	0.26726123,
	0.53452247,
	0.80178368,
	0,
	0.26726126,
	0.53452253,
	0.80178374,
	0,
	0,
	0,
	0,
	1,
];
const inverseMat = [
	0.00846835,
	0.02962875,
	-0.03229101,
	-0.00627746,
	-0.0130516,
	-0.00061103,
	-0.00529255,
	0.0152574,
	-0.00463914,
	-0.0125714,
	0.02658457,
	0.00106465,
	0.01950305,
	-0.00000372,
	0.00028874,
	-0.0018331,
];

(async () => {
	const simd = false;
	const { g, h, matFactory } = ftbMatrix({ autoFree: true, simd });
	const Mat = await matFactory();

	if (!simd) {
		test('Utility - cosine', async function(t) {
			t.plan(16);
			const { PI } = Math;
			t.equal(areValuesEqual(Mat.cos(-2 * PI), Math.cos(-2 * PI)), true);
			t.equal(areValuesEqual(Mat.cos(-PI), Math.cos(-PI)), true);
			t.equal(areValuesEqual(Mat.cos(-PI / 2), Math.cos(-PI / 2)), true);
			t.equal(areValuesEqual(Mat.cos(0), Math.cos(0)), true);
			t.equal(areValuesEqual(Mat.cos(PI / 6), Math.cos(PI / 6)), true);
			t.equal(areValuesEqual(Mat.cos(PI / 4), Math.cos(PI / 4)), true);
			t.equal(areValuesEqual(Mat.cos(PI / 3), Math.cos(PI / 3)), true);
			t.equal(areValuesEqual(Mat.cos(PI / 2), Math.cos(PI / 2)), true);
			t.equal(areValuesEqual(Mat.cos(PI / 2 + PI / 4), Math.cos(PI / 2 + PI / 4)), true);
			t.equal(areValuesEqual(Mat.cos(PI), Math.cos(PI)), true);
			t.equal(areValuesEqual(Mat.cos(PI + PI / 4), Math.cos(PI + PI / 4)), true);
			t.equal(areValuesEqual(Mat.cos(PI + PI / 2), Math.cos(PI + PI / 2)), true);
			t.equal(areValuesEqual(Mat.cos(PI + PI / 2 + PI / 4), Math.cos(PI + PI / 2 + PI / 4)), true);
			t.equal(areValuesEqual(Mat.cos(2 * PI), Math.cos(2 * PI)), true);
			t.equal(areValuesEqual(Mat.cos(2 * PI + PI / 6), Math.cos(2 * PI + PI / 6)), true);
			t.equal(areValuesEqual(Mat.cos(213 * PI + PI / 6), Math.cos(213 * PI + PI / 6)), true);
		});
	}

	test('Utility - storeVector', async function(t) {
		t.plan(3);
		Mat.storeVector(0, 2, 4, 8);
		t.equal(areValuesEqual(Mat.reservedMemory[0], 2), true);
		t.equal(areValuesEqual(Mat.reservedMemory[1], 4), true);
		t.equal(areValuesEqual(Mat.reservedMemory[2], 8), true);
	});

	test('Utility- squared length', async function(t) {
		t.plan(1);
		Mat.storeVector(0, 1, 2, 3);
		const value = Mat.lengthSquare(0);
		t.equal(value, 14);
	});

	test('Utility - length', async function(t) {
		t.plan(1);
		Mat.storeVector(0, 1, 2, 3);
		t.equal(areValuesEqual(Mat.norm(0), 3.7416574), true);
	});

	test('Utility - normalize', async function(t) {
		t.plan(3);
		Mat.storeVector(0, 1, 3, 5);
		Mat.normalize(0);
		t.equal(areValuesEqual(Mat.reservedMemory[0], 0.1690308), true);
		t.equal(areValuesEqual(Mat.reservedMemory[1], 0.5070925), true);
		t.equal(areValuesEqual(Mat.reservedMemory[2], 0.8451542), true);
	});

	test('Utility - subVectors', async function(t) {
		t.plan(3);
		Mat.storeVector(16, 10, 20, 30);
		Mat.storeVector(32, 1, 2, 3);
		Mat.subVectors(0, 16, 32);
		t.equal(areValuesEqual(Mat.reservedMemory[0], 9), true);
		t.equal(areValuesEqual(Mat.reservedMemory[1], 18), true);
		t.equal(areValuesEqual(Mat.reservedMemory[2], 27), true);
	});

	test('Utility - crossVectors', async function(t) {
		t.plan(3);
		Mat.storeVector(16, 2, 4, 8);
		Mat.storeVector(32, 3, 6, 9);
		Mat.crossVectors(48, 16, 32);
		t.equal(areValuesEqual(Mat.reservedMemory[48 / 4], -12), true);
		t.equal(areValuesEqual(Mat.reservedMemory[48 / 4 + 1], 6), true);
		t.equal(areValuesEqual(Mat.reservedMemory[48 / 4 + 2], 0), true);
	});

	test('Initialization', async function(t) {
		t.plan(4);
		const mat = new Mat();
		t.equal(
			areMatricesEqual(mat, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
			true,
			'Default matrix is the identity one.'
		);
		t.equal(mat.slot, 42, 'Internals : memory index is 42 for the first matrix.');
		const mat2 = new Mat();
		t.equal(mat2.slot, 43, 'Internals : memory index is 43 for the second matrix.');
		mat2.free();
		mat.free();
		const mat3 = new Mat();
		t.equal(mat3.slot, 42, 'Manual memory freeing.');
		// IMPORTANT: Memory cleanup
		mat3.free();
	});

	test('Matrices are aware of the garbage collection', async function(t) {
		t.plan(3);
		let mat = new Mat();
		g(mat, _ => h(mat));
		t.equal(mat.slot, 42, 'first matrix uses slot 42.');
		let mat2 = new Mat();
		g(mat2, _ => h(mat2));
		t.equal(mat2.slot, 43, 'Second matrix uses slot 43.');
		mat = null;
		let mat3 = new Mat();
		t.equal(mat3.slot, 42, 'Third matrix re-uses slot 42.');
		// cleanup
		mat3.free();
	});

	test('extractBasis', async function(t) {
		t.plan(4);
		const mat = Mat.makeBasis(2, 3, 4, 5, 6, 7, 8, 9, 10);
		t.equal(areMatricesEqual(mat, [2, 3, 4, 0, 5, 6, 7, 0, 8, 9, 10, 0, 0, 0, 0, 1]), true);
		const vector1 = {};
		const vector2 = {};
		const vector3 = {};
		mat.extractBasis(vector1, vector2, vector3);
		t.equal(areVectorsEqual(vector1, { x: 2, y: 3, z: 4 }), true);
		t.equal(areVectorsEqual(vector2, { x: 5, y: 6, z: 7 }), true);
		t.equal(areVectorsEqual(vector3, { x: 8, y: 9, z: 10 }), true);
		mat.free();
	});

	test('extractRotation', async function(t) {
		t.plan(1);
		const mat1 = new Mat(1, 2, 3, 0, 2, 4, 6, 0, 3, 6, 9, 0, 0, 0, 0, 0);
		const mat2 = new Mat();
		mat2.extractRotation(mat1);
		t.equal(areMatricesEqual(mat2, extractRotationMat), true);
		mat1.free();
		mat2.free();
	});

	test('clone', async function(t) {
		t.plan(1);
		const mat1 = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		const mat2 = new Mat();
		mat2.clone(mat1);
		t.equal(areMatricesEqual(mat1, mat2), true);
		mat1.free();
		mat2.free();
	});

	test('compose', async function(t) {
		t.plan(1);
		const mat = new Mat();
		const position = { x: 10, y: 11, z: 12 };
		const quaternion = {
			_x: 0.18257418583505536,
			_y: 0.3651483716701107,
			_z: 0.5477225575051661,
			_w: 0.7302967433402214,
		};
		const scale = { x: 1, y: 2, z: 3 };
		mat.compose(position, quaternion, scale);
		t.equal(
			areMatricesEqual(mat, [
				0.13333332538604736,
				0.9333333373069763,
				-0.3333333134651184,
				0,
				-1.3333333730697632,
				0.6666666269302368,
				1.3333332538604736,
				0,
				2.1999998092651367,
				0.40000006556510925,
				2,
				0,
				10,
				11,
				12,
				1,
			]),
			true
		);
		mat.free();
	});

	test('decompose', async function(t) {
		// TODO: check quaternion values
		t.plan(3);
		const mat = new Mat(1, 2, 3, 0, 2, 3, 4, 0, 3, 4, 5, 0, 4, 5, 6, 0);
		const position = {};
		const quaternion = {};
		const scale = {};
		mat.decompose(position, quaternion, scale);
		t.equal(areVectorsEqual(position, { x: 4, y: 5, z: 6 }), true);
		t.equal(areVectorsEqual(scale, { x: 3.74165749, y: 5.38516473, z: 7.07106781 }), true);
		t.equal(
			areQuaternionEqual(quaternion, {
				_x: 0.05565362557628658,
				_y: -0.11863818454848937,
				_z: 0.0512653133660459,
				_w: 0.7955271925744255,
			}),
			true
		);
		mat.free();
	});

	test('copyPosition', async function(t) {
		t.plan(1);
		const mat1 = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		const mat2 = new Mat();
		mat2.copyPosition(mat1);
		t.equal(areMatricesEqual(mat2, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 13, 14, 15, 1]), true);
		mat1.free();
		mat2.free();
	});

	test('determinant', async function(t) {
		t.plan(1);
		const mat = new Mat(1, 7, 2, 56, 75, 25, 96, 7, 35, 10, 82, 11, 16, 76, 34, 52);
		t.equal(mat.determinant(), 10195838);
		mat.free();
	});

	test('equals', async function(t) {
		t.plan(4);
		const mat1 = new Mat(1, 7, 2, 56, 75, 25, 96, 7, 35, 10, 82, 11, 16, 76, 34, 52);
		const mat2 = new Mat(1, 7, 2, 56, 75, 25, 96, 7, 35, 10, 82, 11, 16, 76, 34, 52);
		const mat3 = new Mat(1, 7, 2, 56, 75, 25, 96, 7, 35, 10, 82, 11, 16, 76, 34, 53);
		const mat4 = new Mat(0, 7, 2, 56, 75, 25, 96, 7, 35, 10, 82, 11, 16, 76, 34, 52);
		t.equal(mat1.equals(mat1), true);
		t.equal(mat1.equals(mat2), true);
		t.equal(mat1.equals(mat3), false);
		t.equal(mat1.equals(mat4), false);
		mat1.free();
		mat2.free();
		mat3.free();
		mat4.free();
	});

	test('fromArray', async function(t) {
		t.plan(1);
		const mat = new Mat();
		const arr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
		mat.fromArray(arr, 1);
		t.equal(areMatricesEqual(mat, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]), true);
		mat.free();
	});

	test('getInverse', async function(t) {
		t.plan(1);
		const mat1 = new Mat(1, 7, 2, 56, 75, 25, 96, 7, 35, 10, 82, 11, 16, 76, 34, 52);
		const mat2 = new Mat().getInverse(mat1);
		t.equal(areMatricesEqual(mat2, inverseMat), true);
		mat1.free();
		mat2.free();
	});

	test('getMaxScaleOnAxis', async function(t) {
		t.plan(1);
		const mat = new Mat(1, 2, 3, 0, 5, 6, 7, 0, 1, 1, 1, 0, 0, 0, 0, 0);
		t.equal(areValuesEqual(mat.getMaxScaleOnAxis(), 10.48808848), true);
		mat.free();
	});

	test('lookAt', async function(t) {
		t.plan(1);
		const mat = new Mat();
		mat.lookAt(0.5, 1, 2, -1, 10, 3, 5, 1, 0);
		t.equal(
			areMatricesEqual(mat, [
				-0.02137723499819775,
				0.10688617499098875,
				0,
				0,
				0.9863248868247347,
				0.1647756452015348,
				-0.00349347657671098,
				0,
				0.163420413210853,
				-0.9805224792651179,
				-0.10894694214056866,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		mat.free();
	});

	test('makeRotationFromQuaternion', async function(t) {
		t.plan(1);
		const mat = new Mat();
		const quaternion = {
			_x: 0.18257418583505536,
			_y: 0.3651483716701107,
			_z: 0.5477225575051661,
			_w: 0.7302967433402214,
		};
		mat.makeRotationFromQuaternion(quaternion);
		t.equal(
			areMatricesEqual(mat, [
				0.13333332538604736,
				0.9333333373069763,
				-0.3333333134651184,
				0,
				-0.6666666865348816,
				0.3333333134651184,
				0.6666666269302368,
				0,
				0.7333332896232605,
				0.13333335518836975,
				0.6666666865348816,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		mat.free();
	});

	test('multiply', async function(t) {
		t.plan(1);
		const mat1 = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		const mat2 = new Mat(0, 11, 6, 12, 4, 8, 15, 5, 16, 3, 9, 13, 3, 7, 14, 1);
		mat1.multiply(mat2);
		t.equal(areMatricesEqual(mat1, multiplyMat), true);
		mat1.free();
		mat2.free();
	});

	test('multiplyMatrices', async function(t) {
		t.plan(1);
		const mat1 = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		const mat2 = new Mat(0, 11, 6, 12, 4, 8, 15, 5, 16, 3, 9, 13, 3, 7, 14, 1);
		const resultMat = new Mat();
		resultMat.multiplyMatrices(mat1, mat2);
		t.equal(areMatricesEqual(resultMat, multiplyMat), true);
		mat1.free();
		mat2.free();
		resultMat.free();
	});

	test('multiplyScalar', async function(t) {
		t.plan(1);
		const mat = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		mat.multiplyScalar(0.5);
		t.equal(areMatricesEqual(mat, [0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8]), true);
		mat.free();
	});

	test('orthographic matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeOrthographic(-1, 3, 5, -3, 6, 10);
		t.equal(areMatricesEqual(mat, [0.5, 0, 0, 0, 0, 0.25, 0, 0, 0, 0, -0.5, 0, -0.5, -0.25, 4, 1]), true);
		mat.free();
	});

	test('perspective matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makePerspective(-1, 3, 5, -3, 5, 15);
		t.equal(areMatricesEqual(mat, [2.5, 0, 0, 0, 0, 1.25, 0, 0, 0.5, 0.25, -2, -1, 0, 0, -15, 0]), true);
		mat.free();
	});

	test('premultiply', async function(t) {
		t.plan(1);
		const mat1 = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		const mat2 = new Mat(0, 11, 6, 12, 4, 8, 15, 5, 16, 3, 9, 13, 3, 7, 14, 1);
		mat2.premultiply(mat1);
		t.equal(areMatricesEqual(mat2, multiplyMat), true);
		mat1.free();
		mat2.free();
	});

	test('axis rotation matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeRotationAxis(Math.PI / 4, 0.83205029433, 0, 0.55470019622);
		t.equal(areMatricesEqual(mat, axisRotMat), true);
		mat.free();
	});

	test('X-rotation matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeRotationX(Math.PI / 3);
		t.equal(areMatricesEqual(mat, [1, 0, 0, 0, 0, 0.5, 0.86602545, 0, 0, -0.86602545, 0.5, 0, 0, 0, 0, 1]), true);
		mat.free();
	});

	test('Y-rotation matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeRotationY(Math.PI / 3);
		t.equal(areMatricesEqual(mat, [0.5, 0, -0.86602545, 0, 0, 1, 0, 0, 0.86602545, 0, 0.5, 0, 0, 0, 0, 1]), true);
		mat.free();
	});

	test('Z-rotation matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeRotationZ(Math.PI / 3);
		t.equal(areMatricesEqual(mat, [0.5, 0.86602545, 0, 0, -0.86602545, 0.5, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]), true);
		mat.free();
	});

	test('scale', async function(t) {
		t.plan(1);
		const mat = new Mat(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1);
		mat.scale(2, 3, 4);
		t.equal(areMatricesEqual(mat, [2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 1, 1, 1, 1]), true);
		mat.free();
	});

	test('scale matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeScale(2, 3, 4);
		t.equal(areMatricesEqual(mat, [2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4, 0, 0, 0, 0, 1]), true);
		mat.free();
	});

	test('translation matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeTranslation(2, 3, 4);
		t.equal(areMatricesEqual(mat, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 3, 4, 1]), true);
		mat.free();
	});

	test('shear matrix', async function(t) {
		t.plan(1);
		const mat = Mat.makeShear(2, 3, 4);
		t.equal(areMatricesEqual(mat, [1, 2, 2, 0, 3, 1, 3, 0, 4, 4, 1, 0, 0, 0, 0, 1]), true);
		mat.free();
	});

	test('setPosition', async function(t) {
		t.plan(1);
		const mat = new Mat();
		mat.setPosition(2, 3, 4);
		t.equal(areMatricesEqual(mat, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2, 3, 4, 1]), true);
		mat.free();
	});

	test('toArray', async function(t) {
		t.plan(1);
		const mat = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		const arr = [0];
		const resultArr = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
		t.equal(JSON.stringify(mat.toArray(arr, 1)) == JSON.stringify(resultArr), true);
		mat.free();
	});

	test('transpose', async function(t) {
		t.plan(1);
		const mat = new Mat(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
		mat.transpose();
		t.equal(areMatricesEqual(mat, [1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16]), true);
		mat.free();
	});

	test('makeRotationFromEuler', async function(t) {
		t.plan(6);
		const mat = new Mat();
		const euler = {
			x: Math.PI / 6,
			y: Math.PI / 4,
			z: Math.PI / 3,
			isEuler: 'XYZ',
		};
		mat.makeRotationFromEuler(euler);
		t.equal(
			areMatricesEqual(mat, [
				0.3535533547401428,
				0.926776647567749,
				0.12682649493217468,
				0,
				-0.6123723983764648,
				0.1268264651298523,
				0.7803300619125366,
				0,
				0.7071067690849304,
				-0.3535533845424652,
				0.6123723983764648,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		euler.isEuler = 'YXZ';
		mat.makeRotationFromEuler(euler);
		t.equal(
			areMatricesEqual(mat, [
				0.6597395539283752,
				0.75,
				-0.0473671555519104,
				0,
				-0.43559572100639343,
				0.4330126643180847,
				0.7891490459442139,
				0,
				0.6123723983764648,
				-0.5,
				0.6123723983764648,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		euler.isEuler = 'ZXY';
		mat.makeRotationFromEuler(euler);
		t.equal(
			areMatricesEqual(mat, [
				0.0473671555519104,
				0.7891490459442139,
				-0.6123723983764648,
				0,
				-0.75,
				0.4330126643180847,
				0.5,
				0,
				0.6597395539283752,
				0.43559572100639343,
				0.6123723983764648,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		euler.isEuler = 'ZYX';
		mat.makeRotationFromEuler(euler);
		t.equal(
			areMatricesEqual(mat, [
				0.3535533547401428,
				0.6123723983764648,
				-0.7071067690849304,
				0,
				-0.573223352432251,
				0.7391988635063171,
				0.3535533845424652,
				0,
				0.7391989231109619,
				0.2803300619125366,
				0.6123723983764648,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		euler.isEuler = 'YZX';
		mat.makeRotationFromEuler(euler);
		t.equal(
			areMatricesEqual(mat, [
				0.3535533547401428,
				0.8660253882408142,
				-0.3535533547401428,
				0,
				-0.1767766773700714,
				0.4330126643180847,
				0.8838834762573242,
				0,
				0.9185585975646973,
				-0.2499999850988388,
				0.3061861991882324,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		euler.isEuler = 'XZY';
		mat.makeRotationFromEuler(euler);
		t.equal(
			areMatricesEqual(mat, [
				0.3535533547401428,
				0.8838834762573242,
				-0.3061861991882324,
				0,
				-0.8660253882408142,
				0.4330126643180847,
				0.2499999850988388,
				0,
				0.3535533547401428,
				0.1767766773700714,
				0.9185585975646973,
				0,
				0,
				0,
				0,
				1,
			]),
			true
		);
		mat.free();
	});
})();
