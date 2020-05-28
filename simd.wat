;; The MIT License
;;
;; Copyright (c) 2020 Marc Chambon
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.


;; !TODO; Understanding why the wabt library doesn't accept a memory alignnment value of 3..!
;; At the moment value 2 used instead, but not optimized.
(module

;; Imported memory for matrix storage
(import "" "mem" (memory 1))

;; memory to store the matrices
(global $f32epsilon f32 (f32.const 0.0001))
(global $f64epsilon f64 (f64.const 0.00000001))

(type $1i32resultNone (func (param i32)))
(type $1i32resulti32 (func (param i32) (result i32)))

(type $1i32_1f32resultNone (func (param i32 f32)))
(type $1i32resultf32 (func (param i32) (result f32)))

(type $2i32resultNone (func (param i32 i32)))
(type $2i32resulti32 (func (param i32 i32) (result i32)))

(type $3i32resultNone (func (param i32 i32 i32)))
(type $3i32resulti32 (func (param i32 i32 i32) (result i32)))

(type $1f64resultf32 (func (param f64) (result f32)))

(type $1i32_3f64_1i32resultNone (func (param i32 f64 f64 f64 i32)))

(type $1i32_3f32resultNone (func (param i32 f32 f32 f32)))

(type $1i32_1f64_3f32resultNone (func (param i32 f64 f32 f32 f32)))

(type $1i32_1f64resultNone (func (param i32 f64)))
(type $1i32_3f32resulti32 (func (param i32 f32 f32 f32) (result i32)))
(type $1i32_6f32resultNone (func (param i32 f32 f32 f32 f32 f32 f32)))
(type $1i32_9f32resultNone (func (param i32 f32 f32 f32 f32 f32 f32 f32 f32 f32)))
(type $1i32_10f32resultNone (func (param i32 f32 f32 f32 f32 f32 f32 f32 f32 f32 f32)))
(type $1f64resultf64 (func (param f64) (result f64)))
(type $1f64_2i32resultfNone (func (param f64 i32 i32)))

(type $1v28resultf32 (func (param v128) (result f32)))
(type $1f64resultv128 (func (param f64) (result v128)))

;; 0 - Partial cosine/sine values (f64x2 vector) : 16th-order Taylor serie
;; => quasi-exact value between -PI and PI once demoted to float32.
;; TODO: find better algorithms (even for low-end ARM architectures),
;; like restricting to 0-PI/4 and using more symmetry.
;; @param {f64} local 0 (signature) - Angle in radians.
;; @param {v128} local 1 (extra local) - f64x2 one vector
;; @param {v128} local 2 (extra local) - Temporary variable.
;; @returns {v128} - Both cosine and sine values (v128 f64x2).
(func $halfPeriodCossin (type $1f64resultv128) (local v128 v128)
    (f64x2.add
        (tee_local 1
            (f64x2.splat (f64.const 1.0))
        )
        (f64x2.mul
            (tee_local 2
                (f64x2.replace_lane 1
                    (f64x2.splat
                        (f64.mul (get_local 0) (get_local 0))
                    )
                    (f64.mul
                        (tee_local 0
                            (f64.sub (get_local 0) (f64.const 1.570796326794896619231)) ;; sin(x) = cos(x - PI/2)
                        )
                        (get_local 0)
                    )
                )
            )
            (f64x2.add
                (f64x2.splat (f64.const -0.5))
                (f64x2.mul
                    (f64x2.mul
                        (f64x2.splat (f64.const 4.1666666666666666666667E-2))   ;; 1 / (2 * 3 x 4)
                        (get_local 2)
                    )
                    (f64x2.sub
                        (get_local 1)
                        (f64x2.mul
                            (f64x2.mul
                                (f64x2.splat (f64.const 3.3333333333333333333333E-2))   ;; 1 / (5 x 6)
                                (get_local 2)
                            )
                            (f64x2.sub
                                (get_local 1)
                                (f64x2.mul
                                    (f64x2.mul
                                        (f64x2.splat (f64.const 1.785714285714285714286E-2))    ;; 1 / (7 x 8)
                                        (get_local 2)
                                    )
                                    (f64x2.sub
                                        (get_local 1)
                                        (f64x2.mul
                                            (f64x2.mul
                                                (f64x2.splat (f64.const 1.111111111111111111111E-2))    ;;  1 / (9 x 10)
                                                (get_local 2)
                                            )
                                            (f64x2.sub
                                                (get_local 1)
                                                (f64x2.mul
                                                    (f64x2.mul
                                                        (f64x2.splat (f64.const 7.575757575757575757576E-3))    ;;  1 / (11 x 12)
                                                        (get_local 2)
                                                    )
                                                    (f64x2.sub
                                                        (get_local 1)
                                                        (f64x2.mul
                                                            (f64x2.mul
                                                                (f64x2.splat (f64.const 5.494505494505494505495E-3))    ;;  1 / (13 x 14)
                                                                (get_local 2)
                                                            )
                                                            (f64x2.sub
                                                                (get_local 1)
                                                                (f64x2.mul
                                                                    (f64x2.splat (f64.const 4.1666666666666666666667E-3))   ;;  1 / (15 x 16)
                                                                    (get_local 2)
                                                                )
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )
)

;; 1 - Approximated (Cosine, Sin) 2d vector to avoid JS-WebAssembly boundary crossing.
;; TODO: find better algorithms (even for low-end ARM architectures)
;; @param {f64} local 0 (signature) - Angle in radians in the range [-PI, 2PI].
;; @returns {v128} - Both cosine and sine values (v128 f64x2).
(func $approxCossin (export "approxCossin_u") (type $1f64resultv128)
    (if (result v128)
        (f64.lt (get_local 0) (f64.const 3.141592653589793238463))
        (then
            (call $halfPeriodCossin (get_local 0))
        )
        (else   ;; using symmetry
            (call $halfPeriodCossin
                (f64.sub (f64.const 6.283185307179586476925) (get_local 0))
            )
        )
    )
)

;; 2 - Calculates cosine and sine value simultaneously.
;; @param {f64} local 0 (signature) - Angle in radians.
;; @returns {v128} - Both cosine and sine values (v128 f64x2).
(func $cossin (export "cossin_u") (type $1f64resultv128)
    ;; get modulo 2PI if necessary
    (if (f64.gt
            (tee_local 0
                (f64.abs (get_local 0))
            )
            (f64.const 6.283185307179586476925)
        )
        (then
            (set_local 0
                (f64.sub
                    (get_local 0)
                    (f64.mul
                        (f64.const 6.283185307179586476925)
                        (f64.floor
                            (f64.div
                                (get_local 0)
                                (f64.const 6.283185307179586476925)
                            )
                        )
                    )
                )
            )
        )
    )
    (call $approxCossin (get_local 0))
)

;; 3 - Converts matrix slot to memory address.
;; @param {i32} local 0 (signature) - Matrix slot (corresponding to this.slot in the matrix constructor).
;; @returns {i32} - Matrix starting memory address in byte offset.
(func $mapMatrixSlotToMemoryOffset (type $1i32resulti32)
    (i32.shl (get_local 0) (i32.const 6))
)

;; 4 - Set matrix values to zero.
;; to avoid JS-WebAssembly boundary crossing.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {v128} local 1 - temporary variable.
;; @returns {i32} - Matrix starting memory address in byte offset.
(func $clear (export "clear") (type $1i32resulti32) (local v128)
    ;; v128.const not available on all platforms yet (ex: ARM)
    (v128.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (tee_local 1
            (f32x4.splat (f32.const 0.0))
        )
    )
    (v128.store offset=16 align=4 (get_local 0) (get_local 1))
    (v128.store offset=32 align=4 (get_local 0) (get_local 1))
    (v128.store offset=48 align=4 (get_local 0) (get_local 1))
    get_local 0
)

;; 5 - Compose function
;; @param {i32} local 0 (signature) - Source matrix slot.
;; @param {f32} local 1 (signature) - position / x coordinate
;; @param {f32} local 2 (signature) - position / y coordinate
;; @param {f32} local 3 (signature) - position / z coordinate
;; @param {f32} local 4 (signature) - quaternion / _x coordinate
;; @param {f32} local 5 (signature) - quaternion / _y coordinate
;; @param {f32} local 6 (signature) - quaternion / _z coordinate
;; @param {f32} local 7 (signature) - quaternion / _w coordinate
;; @param {f32} local 8 (signature) - x-scale
;; @param {f32} local 9 (signature) - y-scale
;; @param {f32} local 10 (signature) - z-scale
;; @param {f32} local 11 (extra local) - x2 = _x + _x
;; @param {f32} local 12 (extra local) - y2 = _y + _y
;; @param {f32} local 13 (extra local) - z2 = _z + _z
;; @param {f32} local 14 (extra local) - xx = x + x2
;; @param {f32} local 15 (extra local) - xy = x + y2
;; @param {f32} local 16 (extra local) - xz = x * z2
;; @param {f32} local 17 (extra local) - yy = y + y2
;; @param {f32} local 18 (extra local) - yz = y + z2
;; @param {f32} local 19 (extra local) - zz = z + z2
;; @param {f32} local 20 (extra local) - wx = w + x2
;; @param {f32} local 21 (extra local) - wy = w + y2
;; @param {f32} local 22 (extra local) - wz = w + z2
(func (export "compose") (type $1i32_10f32resultNone) (local f32 f32 f32 f32 f32 f32 f32 f32 f32 f32 f32 f32)
    (set_local 11 ;; x2
        (f32.add (get_local 4) (get_local 4))
    )
    (set_local 12 ;; y2
        (f32.add (get_local 5) (get_local 5))
    )
    (set_local 13 ;; z2
        (f32.add (get_local 6) (get_local 6))
    )
    ;; values 0 to 3
    (v128.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f32x4.mul
            (f32x4.splat (get_local 8))
            (f32x4.replace_lane 3
                (f32x4.replace_lane 2
                    (f32x4.replace_lane 1
                        (f32x4.splat
                            (f32.sub
                                (f32.const 1.0)
                                (f32.add
                                    (tee_local 17 ;; yy
                                        (f32.mul (get_local 5) (get_local 12))
                                    )
                                    (tee_local 19 ;; zz
                                        (f32.mul (get_local 6) (get_local 13))
                                    )
                                )
                            )
                        )
                        (f32.add
                            (tee_local 15 ;; xy
                                (f32.mul (get_local 4) (get_local 12))  ;; _x * (_y + _y)
                            )
                            (tee_local 22 ;; wz
                                (f32.mul (get_local 7) (get_local 13))
                            )
                        )
                    )
                    (f32.sub
                        (tee_local 16 ;; xz
                            (f32.mul (get_local 4) (get_local 13))
                        )
                        (tee_local 21 ;; wy
                            (f32.mul (get_local 7) (get_local 12))
                        )
                    )
                )
                (f32.const 0.0)
            )
        )
    )

    ;; values 4 to 7
    (v128.store offset=16 align=4
        (get_local 0)
        (f32x4.mul
            (f32x4.splat (get_local 9))
            (f32x4.replace_lane 3
                (f32x4.replace_lane 2
                    (f32x4.replace_lane 1
                        (f32x4.splat
                            (f32.sub (get_local 15) (get_local 22)) ;; xy - wz
                        )
                        (f32.sub
                            (f32.const 1.0)
                            (f32.add
                                (tee_local 14 ;; xx
                                    (f32.mul (get_local 4) (get_local 11))
                                )
                                (get_local 19)
                            ) ;; xx + zz
                        )
                    )
                    (f32.add
                        (tee_local 18 ;; yz
                            (f32.mul (get_local 5) (get_local 13))
                        )
                        (tee_local 20 ;; wx
                            (f32.mul (get_local 7) (get_local 11))
                        )
                    )
                )
                (f32.const 0.0)
            )
        )
    )

    ;; values 8 to 11
    (v128.store offset=32 align=4
        (get_local 0)
        (f32x4.mul
            (f32x4.splat (get_local 10))
            (f32x4.replace_lane 3
                (f32x4.replace_lane 2
                    (f32x4.replace_lane 1
                        (f32x4.splat
                            (f32.add (get_local 16) (get_local 21)) ;; xz + wy
                        )
                        (f32.sub (get_local 18) (get_local 20)) ;; yz - wx
                    )
                    (f32.sub
                        (f32.const 1.0)
                        (f32.add (get_local 14) (get_local 17)) ;; 1 - (xx + yy)
                    )
                )
                (f32.const 0.0)
            )
        )
    )

    ;; value 12
    (f32.store offset=48 align=4 (get_local 0) (get_local 1))
    ;; value 13
    (f32.store offset=52 align=2 (get_local 0) (get_local 2))
    ;; value 14
    (f32.store offset=56 align=2 (get_local 0) (get_local 3))
    ;; value 15
    (f32.store offset=60 align=2 (get_local 0) (f32.const 1.0))
)

;; 6 - Copy values from one matrix to another's.
;; @param {i32} local 0 (signature) - Source matrix slot.
;; @param {i32} local 1 (signature) - Destination matrix slot.
(func (export "copy") (type $2i32resultNone)
    ;; v128.const not available on all platforms yet (ex: ARM)
    (v128.store offset=0 align=4
        (tee_local 1
            (call $mapMatrixSlotToMemoryOffset (get_local 1))
        )
        (v128.load offset=0 align=4
            (tee_local 0
               (call $mapMatrixSlotToMemoryOffset (get_local 0))
            )
        )
    )
    (v128.store offset=16 align=4
        (get_local 1)
        (v128.load offset=16 align=4 (get_local 0))
    )
    (v128.store offset=32 align=4
        (get_local 1)
        (v128.load offset=32 align=4 (get_local 0))
    )
    (v128.store offset=48 align=4
        (get_local 1)
        (v128.load offset=48 align=4 (get_local 0))
    )
)

;; 7 - Copy matrix positions
;; @param {i32} local 0 (signature) - Source matrix slot.
;; @param {i32} local 1 (signature) - Destination matrix slot.
;; @param {f32} local 2 (extra local) - Temporary variable to restore the last matrix value.
(func (export "copyPos") (type $2i32resultNone) (local f32)
    (set_local 2
        (f32.load offset=60 align=2
            (tee_local 1
                (call $mapMatrixSlotToMemoryOffset (get_local 1))
            )
        )
    )
    (v128.store offset=48 align=4
        (get_local 1)
        (v128.load offset=48 align=4
            (tee_local 0
                (call $mapMatrixSlotToMemoryOffset (get_local 0))
            )
        )
    )
    (f32.store offset=60 align=2 (get_local 1) (get_local 2))
)

;; 8- Extracts matrix rotation
;; @param {i32} local 0 (signature) - Slot of the matrix to rotated.
;; @param {i32} local 1 (signature) - Slot of the matrix whose rotation is extracted from.
(func (export "extractRotation") (type $2i32resultNone)
    (v128.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (f32x4.mul
            (f32x4.splat
                (f32.div
                    (f32.const 1.0)
                    (call $length
                        (tee_local 1
                            (call $mapMatrixSlotToMemoryOffset (get_local 1))
                        )
                    )
                )
            )
            (v128.load offset=0 align=4 (get_local 1))
        )
    )
    (v128.store offset=16 align=4
        (get_local 0)
        (f32x4.mul
            (f32x4.splat
                (f32.div
                    (f32.const 1.0)
                    (call $length
                        (i32.add (get_local 1) (i32.const 16))
                    )
                )
            )
            (v128.load offset=16 align=4 (get_local 1))
        )
    )
    (v128.store offset=32 align=4
        (get_local 0)
        (f32x4.mul
            (f32x4.splat
                (f32.div
                    (f32.const 1.0)
                    (call $length
                        (i32.add (get_local 1) (i32.const 32))
                    )
                )
            )
            (v128.load offset=32 align=4 (get_local 1))
        )
    )
)

;; 9 - Set matrix to identity
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {v128} local 1 (extra local) - temporary variable.
;; @returns {i32} - Matrix starting memory address.
;; TODO: Solving issue with (v128.const f32x4 1.0 0.0 0.0 0.0)
(func $identity (export "identity_d") (type $1i32resulti32) (local v128)
    ;; v128.const not available on all platforms yet (ex: ARM)
    (v128.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f32x4.replace_lane 0
            (f32x4.splat (f32.const 0.0))
            (f32.const 1.0)
        )
    )
    (v128.store offset=16 align=4
        (get_local 0)
        (f32x4.replace_lane 1 (get_local 1) (f32.const 1.0))
    )
    (v128.store offset=32 align=4
        (get_local 0)
        (f32x4.replace_lane 2 (get_local 1) (f32.const 1.0))
    )
    (v128.store offset=48 align=4
        (get_local 0)
        (f32x4.replace_lane 3 (get_local 1) (f32.const 1.0))
    )
    get_local 0
)

;; 10 - Vector length
;; @param {i32} local 0 (signature) - Vector memory offset.
;; @returns {i32} - Vector length.
(func $length (export "norm_u") (type $1i32resultf32)
    (f32.sqrt
        (call $lengthSquare (get_local 0))
    )
)

;; 11 - Vector squared length
;; @param {i32} local 0 (signature) - Memory index in the reserved memory for the resulting vector, multiple of 16.
;; @returns {i32} - Vector squared length.
(func $lengthSquare (export "lengthSquare_u") (type $1i32resultf32) (local v128)
    (f32.add
        (f32.add
            (f32x4.extract_lane 0
                (tee_local 1
                    (f32x4.mul
                        (tee_local 1
                            (v128.load offset=0 align=4 (get_local 0))
                        )
                        (get_local 1)
                    )
                )
           )
           (f32x4.extract_lane 1 (get_local 1))
       )
       (f32x4.extract_lane 2 (get_local 1))
    )
)

;; 12 - Generates a "lookAt" matrix
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - x-component of the 'eye' vector
;; @param {f32} local 2 (signature) - y-component of the 'eye' vector
;; @param {f32} local 3 (signature) - z-component of the 'eye' vector
;; @param {f32} local 4 (signature) - x-component of the 'target' vector
;; @param {f32} local 5 (signature) - y-component of the 'target' vector
;; @param {f32} local 6 (signature) - z-component of the 'target' vector
;; @param {f32} local 7 (signature) - x-component of the 'up' vector
;; @param {f32} local 8 (signature) - y-component of the 'up' vector
;; @param {f32} local 9 (signature) - z-component of the 'up' vector
(func (export "lookAt_d") (type $1i32_9f32resultNone)
    (set_local 0
        (call $identity (get_local 0))
    )
    (if
        (i32.eqz
            (i32.trunc_s/f32
                (call $lengthSquare
                    (call $subVectors                   ;; store 'eye - target' at memory address 48
                        (i32.const 48)
                        (call $storeVector              ;; store 'eye' vector reserved memory at memory address 0
                            (i32.const 0) (get_local 1) (get_local 2) (get_local 3)
                        )
                        (call $storeVector              ;; store 'target' vector at memory address 16
                            (i32.const 16) (get_local 4) (get_local 5) (get_local 6)
                        )
                    )
                )
            )
        )
        (then
            (f32.store offset=8 align=2 (i32.const 48) (f32.const 1.0)) ;; set to 1 the z-component of the 'eye - target' vector
        )
    )

    (if (i32.eqz                    ;; if up and z are  perpendicular ...
            (i32.trunc_s/f32
                (call $lengthSquare
                    (call $crossVectors
                        (i32.const 80)      ;; store 'up x z' ("cross") vector at memory address 80
                        (call $storeVector  ;; store 'up' vector at memory address 32
                            (i32.const 32) (get_local 7) (get_local 8) (get_local 9)
                        )
                        (call $normalize (i32.const 48)) ;; store normalized 'eye - target' vector at memory address 64
                    )
                )
            )
        )
        (then
            (block
                (if (f32.eq     ;; (inside parent if) ...then if absolute value of 'up' z-component equals one
                       (f32.abs (get_local 9))
                       (f32.const 1.0)
                    )
                    (then (f32.store offset=0 align=4   ;; (inside nested if) ...then 'eye - target' x-component is set to near-zero value
                            (i32.const 48)
                            (f32.add
                                (get_global $f32epsilon)
                                (f32.load offset=0 align=4 (i32.const 48))
                            )
                        )
                    )
                    (else (f32.store offset=8 align=2   ;; (inside nested if) ...else 'eye - target' z-component is set to near-zero value
                            (i32.const 48)
                            (f32.add
                                (get_global $f32epsilon)
                                (f32.load offset=8 align=2 (i32.const 48))
                            )
                        )
                    )
                )
                (drop
                    (call $crossVectors                                     ;; 'up x (eye - target)' stored at memory address 80
                        (i32.const 80)
                        (i32.const 32)
                        (call $normalize (i32.const 48))     ;; 'eye - target' vector is normalized
                    )
                )
            )
        )
    )
    (drop
        (call $crossVectors
            (i32.const 96)
            (i32.const 48)
            (call $normalize (i32.const 80))     ;; 'up x (eye - target)' stored at memory address 80
        )
    )
    (f64.store offset=0 align=4
        (get_local 0)
        (f64.load offset=0 align=4 (i32.const 80))
    )
    (f64.store offset=24 align=2
        (get_local 0)
        (f64.load offset=8 align=2 (i32.const 80))
    )
    (f64.store offset=16 align=4
        (get_local 0)
        (f64.load offset=0 align=4 (i32.const 96))
    )
    (f64.store offset=24 align=2
        (get_local 0)
        (f64.load offset=8 align=2 (i32.const 96))
    )
    (f64.store offset=32 align=4
        (get_local 0)
        (f64.load offset=0 align=4 (i32.const 48))
    )
    (f64.store offset=40 align=2
        (get_local 0)
        (f64.load offset=8 align=2 (i32.const 48))
    )
)

;; 13- Sums the values of a 4d vector.
;; @param {v128} local 0 (signature) - 4d vector.
;; @returns {f32} - Summation.
(func $sum (type $1v28resultf32)
    (f32.add
        (f32x4.extract_lane 3 (get_local 0))
        (f32.add
            (f32x4.extract_lane 2 (get_local 0))
            (f32.add
                (f32x4.extract_lane 1 (get_local 0))
                (f32x4.extract_lane 0 (get_local 0))
            )
        )
    )
)

;; 14 - Matrix multiplication.
;; @param {i32} local 0 (signature) - Matrix slot to store the resulting matrix (C = A x B).
;; @param {i32} local 1 (signature) - First matrix (A).
;; @param {i32} local 2 (signature) - Second matrix (B)
;; @param {v128} local 3 (extra local) - Temporary variable to store a row of the second matrix.
(func (export "mul") (type $3i32resultNone) (local v128)
    ;; resulting matrix - first line
    (f32.store offset=0 align=4
        (tee_local 2
            (call $mapMatrixSlotToMemoryOffset (get_local 2))
        )
        (call $sum
            (f32x4.mul
                (tee_local 3
                    (f32x4.replace_lane 3
                        (tee_local 3
                            (f32x4.replace_lane 2
                                (tee_local 3
                                    (f32x4.replace_lane 1
                                        (tee_local 3
                                            (f32x4.splat
                                                (f32.load offset=0 align=4
                                                    (tee_local 0
                                                        (call $mapMatrixSlotToMemoryOffset (get_local 0))
                                                    )
                                                )
                                            )
                                        )
                                        (f32.load offset=16 align=4 (get_local 0))
                                    )
                                )
                                (f32.load offset=32 align=4 (get_local 0))
                            )
                        )
                        (f32.load offset=48 align=4 (get_local 0))
                    )
                )
                (v128.load offset=0 align=4
                    (tee_local 1
                        (call $mapMatrixSlotToMemoryOffset (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=16 align=4
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=16 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=32 align=4
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=32 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=48 align=4
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=48 align=4 (get_local 1))
            )
        )
    )
    ;; resulting matrix - second line
    (f32.store offset=4 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (tee_local 3
                    (f32x4.replace_lane 3
                        (tee_local 3
                            (f32x4.replace_lane 2
                                (tee_local 3
                                    (f32x4.replace_lane 1
                                        (tee_local 3
                                            (f32x4.splat
                                                (f32.load offset=4 align=2 (get_local 0))
                                            )
                                        )
                                        (f32.load offset=20 align=2 (get_local 0))
                                    )
                                )
                                (f32.load offset=36 align=2 (get_local 0))
                            )
                        )
                        (f32.load offset=52 align=2 (get_local 0))
                    )
                )
                (v128.load offset=0 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=20 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=16 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=36 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=32 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=52 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=48 align=4 (get_local 1))
            )
        )
    )
    ;; resulting matrix - third line
    (f32.store offset=8 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (tee_local 3
                    (f32x4.replace_lane 3
                        (tee_local 3
                            (f32x4.replace_lane 2
                                (tee_local 3
                                    (f32x4.replace_lane 1
                                        (tee_local 3
                                            (f32x4.splat
                                                (f32.load offset=8 align=2 (get_local 0))
                                            )
                                        )
                                        (f32.load offset=24 align=2 (get_local 0))
                                    )
                                )
                                (f32.load offset=40 align=2 (get_local 0))
                            )
                        )
                        (f32.load offset=56 align=2 (get_local 0))
                    )
                )
                (v128.load offset=0 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=24 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=16 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=40 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=32 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=56 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=48 align=4 (get_local 1))
            )
        )
    )
    ;; resulting matrix - fourth line
    (f32.store offset=12 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (tee_local 3
                    (f32x4.replace_lane 3
                        (tee_local 3
                            (f32x4.replace_lane 2
                                (tee_local 3
                                    (f32x4.replace_lane 1
                                        (tee_local 3
                                            (f32x4.splat
                                                (f32.load offset=12 align=2 (get_local 0))
                                            )
                                        )
                                        (f32.load offset=28 align=2 (get_local 0))
                                    )
                                )
                                (f32.load offset=44 align=2 (get_local 0))
                            )
                        )
                        (f32.load offset=60 align=2 (get_local 0))
                    )
                )
                (v128.load offset=0 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=28 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=16 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=44 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=32 align=4 (get_local 1))
            )
        )
    )
    (f32.store offset=60 align=2
        (get_local 2)
        (call $sum
            (f32x4.mul
                (get_local 3)
                (v128.load offset=48 align=4 (get_local 1))
            )
        )
    )
)

;; 15 - Multiplies matrix by a number.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - Value to multiply the matrix with.
;; @param {v128} local 2 (extra local) - Temporary 4d vector.
(func (export "multiplyScalar_d") (type $1i32_1f32resultNone) (local v128)
    (v128.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f32x4.mul
            (tee_local 2
                (f32x4.splat (get_local 1))
            )
            (v128.load offset=0 align=4 (get_local 0))
        )
    )
    (v128.store offset=16 align=4
        (get_local 0)
        (f32x4.mul
            (get_local 2)
            (v128.load offset=16 align=4 (get_local 0))
        )
    )
    (v128.store offset=32 align=4
        (get_local 0)
        (f32x4.mul
            (get_local 2)
            (v128.load offset=32 align=4 (get_local 0))
        )
    )
    (v128.store offset=48 align=4
        (get_local 0)
        (f32x4.mul
            (get_local 2)
            (v128.load offset=48 align=4 (get_local 0))
        )
    )
)

;; 16 - Builds an orthographic matrix.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - Left.
;; @param {f32} local 2 (signature) - Right.
;; @param {f32} local 3 (signature) - Top.
;; @param {f32} local 4 (signature) - Bottom.
;; @param {f32} local 5 (signature) - Near.
;; @param {f32} local 6 (signature) - Far.
;; @param {f32} local 7 (extra local) - Temporary variable.
(func (export "makeOrthographic_d") (type $1i32_6f32resultNone) (local $temp f32)
    ;; viewbox width
    (f32.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (f32.mul
            (f32.const 2.0)
            (tee_local 7
                (f32.div
                    (f32.const 1.0)
                    (f32.sub (get_local 2) (get_local 1))
                )
            )
        )
    )
    (f32.store offset=48 align=4
        (get_local 0)
        (f32.neg
            (f32.mul
                (f32.add (get_local 1) (get_local 2))
                (get_local 7)
            )
        )
    )
    ;; viewbox height
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.mul
            (f32.const 2.0)
            (tee_local 7
                (f32.div
                    (f32.const 1.0)
                    (f32.sub (get_local 3) (get_local 4))
                )
            )
        )
    )
    (f32.store offset=52 align=2
        (get_local 0)
        (f32.neg
            (f32.mul
                (f32.add (get_local 3) (get_local 4))
                (get_local 7)
            )
        )
    )
    ;; viewbox depth
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.mul
            (f32.const 2.0)
            (tee_local 7
                (f32.div
                    (f32.const 1.0)
                    (f32.sub (get_local 5) (get_local 6))
                )
            )
        )
    )
    (f32.store offset=56 align=2
        (get_local 0)
        (f32.neg
            (f32.mul
                (f32.add (get_local 5) (get_local 6))
                (get_local 7)
            )
        )
    )
)

;; 17 - Builds a matrix from three 3d vectors.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - x-component of vector 1.
;; @param {f32} local 2 (signature) - y-component of vector 1.
;; @param {f32} local 3 (signature) - z-component of vector 1.
;; @param {f32} local 4 (signature) - x-component of vector 2.
;; @param {f32} local 5 (signature) - y-component of vector 2.
;; @param {f32} local 6 (signature) - z-component of vector 2.
;; @param {f32} local 7 (signature) - x-component of vector 3.
;; @param {f32} local 8 (signature) - y-component of vector 3.
;; @param {f32} local 9 (signature) - z-component of vector 3.
(func (export "makeBasis_d") (type $1i32_9f32resultNone)
    ;; first column
    (f32.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (get_local 1)
    )
    (f32.store offset=4 align=2 (get_local 0) (get_local 2))
    (f32.store offset=8 align=2 (get_local 0) (get_local 3))
    ;; second column
    (f32.store offset=16 align=4 (get_local 0) (get_local 4))
    (f32.store offset=20 align=2 (get_local 0) (get_local 5))
    (f32.store offset=24 align=2 (get_local 0) (get_local 6))
    ;; third column
    (f32.store offset=32 align=4 (get_local 0) (get_local 7))
    (f32.store offset=36 align=2 (get_local 0) (get_local 8))
    (f32.store offset=40 align=2 (get_local 0) (get_local 9))
)

;; 18 - Builds a perspective matrix.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - Left.
;; @param {f32} local 2 (signature) - Right.
;; @param {f32} local 3 (signature) - Top.
;; @param {f32} local 4 (signature) - Bottom.
;; @param {f32} local 5 (signature) - Near.
;; @param {f32} local 6 (signature) - Far.
;; @param {f32} local 7 (extra local) - Temporary variable.
(func (export "makePerspective_d") (type $1i32_6f32resultNone) (local $temp f32)
    ;; viewbox width
    (f32.store offset=0 align=4
        (tee_local 0
            (call $clear (get_local 0))
        )
        (f32.mul
            (f32.const 2.0)
            (f32.mul
                (get_local 5)
                (tee_local 7    ;; local 7 = 1 / (right - left)
                    (f32.div
                        (f32.const 1.0)
                        (f32.sub (get_local 2) (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=32 align=4
        (get_local 0)
        (f32.mul
            (f32.add (get_local 1) (get_local 2))
            (get_local 7)
        )
    )
    ;; viewbox height
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.mul
            (f32.const 2.0)
            (f32.mul
                (get_local 5)
                (tee_local 7    ;; local 7 = 1 / (top - bottom)
                    (f32.div
                        (f32.const 1.0)
                        (f32.sub (get_local 3) (get_local 4))
                    )
                )
            )
        )
    )
    (f32.store offset=36 align=2
        (get_local 0)
        (f32.mul (f32.add (get_local 3) (get_local 4)) (get_local 7))
    )
    ;; viewbox depth
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.mul
            (f32.add (get_local 5) (get_local 6))
            (tee_local 7    ;; local 7 = 1 / (near - far)
                (f32.div
                    (f32.const 1.0)
                    (f32.sub (get_local 5) (get_local 6))
                )
            )
        )
    )
    (f32.store offset=56 align=2
        (get_local 0)
        (f32.mul
            (get_local 7)
            (f32.mul
                (f32.const 2.0)
                (f32.mul (get_local 5) (get_local 6))
            )
        )
    )
    ;; remaining changes
    (f32.store offset=44 align=2 (get_local 0) (f32.const -1.0))
)

;; 19 - Builds a rotation matrix.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f64} local 1 (signature) - Rotation angle in radians.
;; @param {f32} local 2 (signature) - x-component of the axis vector.
;; @param {f32} local 3 (signature) - y-component of the axis vector.
;; @param {f32} local 4 (signature) - z-component of the axis vector.
;; @param {f32} local 5 (extra local) - Cosine value.
;; @param {f32} local 6 (extra local) - Sine value.
;; @param {f32} local 7 (extra local) - One minus cosine value.
;; @param {f32} local 8 (extra local) - Temporary variable.
;; @param {v128} local 9 (extra local) - Temporary variable.
(func (export "makeRotationAxis_d") (type $1i32_1f64_3f32resultNone) (local f32 f32 f32 f32 v128)
    (f32.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (f32.add                ;; tx * x + cos
            (f32.mul
                (tee_local 8    ;; tx = x * t
                    (f32.mul
                        (get_local 2)
                        (tee_local 7    ;; t = (1 - cos)
                            (f32.sub
                                (f32.const 1.0)
                                (tee_local 5    ;; cos
                                    (f32.demote_f64
                                        (f64x2.extract_lane 0
                                            (tee_local 9
                                                (call $cossin (get_local 1))
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
                (get_local 2)
            )
            (get_local 5)
        )
    )
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.add                ;; tx * y + sin * z
            (f32.mul (get_local 8) (get_local 3))
            (f32.mul
                (tee_local 6    ;; sin
                    (f32.demote_f64
                        (f64x2.extract_lane 1 (get_local 9))
                    )
                )
                (get_local 4)
            )
        )
    )
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.sub                ;; tx * z - sin * y
            (f32.mul (get_local 8) (get_local 4))
            (f32.mul (get_local 6) (get_local 3))
        )
    )
    (f32.store offset=16 align=4
        (get_local 0)
        (f32.sub                ;; tx * y - sin * z
            (f32.mul (get_local 8) (get_local 3))
            (f32.mul (get_local 6) (get_local 4))
        )
    )
    (f32.store offset=32 align=4
        (get_local 0)
        (f32.add                ;; tx * z + sin * y
            (f32.mul (get_local 8) (get_local 4))
            (f32.mul (get_local 6) (get_local 3))
        )
    )
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.add                ;; ty * y + cos
            (f32.mul
                (tee_local 8    ;; ty = y * t
                    (f32.mul (get_local 3) (get_local 7))
                )
                (get_local 3)
            )
            (get_local 5)
        )
    )
    (f32.store offset=24 align=2
        (get_local 0)
        (f32.add                ;; ty * z + sin * x
            (f32.mul (get_local 8) (get_local 4))
            (f32.mul (get_local 6) (get_local 2))
        )
    )
    (f32.store offset=36 align=2
        (get_local 0)
        (f32.sub                ;; ty * z - sin * x
            (f32.mul (get_local 8) (get_local 4))
            (f32.mul (get_local 6) (get_local 2))
        )
    )
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.add                ;; t * z * z + cos
            (f32.mul
                (get_local 7)
                (f32.mul (get_local 4) (get_local 4))
            )
            (get_local 5)
        )
    )
)

;; 20 - Builds a rotation matrix around the x-axis.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f64} local 1 (signature) - Rotation angle in radians.
;; @param {v128} local 2 (extra local) - Temporary variable for (cosine, sine) f64x2 vector.
(func (export "makeRotationX_d") (type $1i32_1f64resultNone) (local v128)
    (f32.store offset=20 align=2
        (tee_local 0
            (call $identity (get_local 0))
        )
        (f32.demote_f64
            (f64x2.extract_lane 0
                (tee_local 2
                    (call $cossin (get_local 1))
                )
            )
        )
    )
    (f32.store offset=24 align=2
        (get_local 0)
        (f32.demote_f64
            (f64x2.extract_lane 1 (get_local 2))
        )
    )
    (f32.store offset=36 align=2
        (get_local 0)
        (f32.neg
            (f32.load offset=24 align=2 (get_local 0))
        )
    )
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.load offset=20 align=2 (get_local 0))
    )
)

;; 21 - Builds a rotation matrix around the y-axis.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f64} local 1 (signature) - Rotation angle in radians.
;; @param {v128} local 2 (extra local) - Temporary variable for (cosine, sine) f64x2 vector.
(func (export "makeRotationY_d") (type $1i32_1f64resultNone) (local v128)
    (f32.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (f32.demote_f64
            (f64x2.extract_lane 0
                (tee_local 2
                    (call $cossin (get_local 1))
                )
            )
        )
    )
    (f32.store offset=32 align=4
        (get_local 0)
        (f32.demote_f64
            (f64x2.extract_lane 1 (get_local 2))
        )
    )
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.neg
            (f32.load offset=32 align=4 (get_local 0))
        )
    )
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.load offset=0 align=4 (get_local 0))
    )
)

;; 22 - Builds a rotation matrix around the z-axis.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f64} local 1 (signature) - Rotation angle in radians.
;; @param {v128} local 2 (extra local) - Temporary variable for (cosine, sine) f64x2 vector.
(func (export "makeRotationZ_d") (type $1i32_1f64resultNone) (local v128)
    (f32.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (f32.demote_f64
            (f64x2.extract_lane 0
                (tee_local 2
                    (call $cossin (get_local 1))
                )
            )
        )
    )
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.demote_f64
            (f64x2.extract_lane 1 (get_local 2))
        )
    )
    (f32.store offset=16 align=2
        (get_local 0)
        (f32.neg
            (f32.load offset=4 align=2 (get_local 0))
        )
    )
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.load offset=0 align=4 (get_local 0))
    )
)

;; 23 - Builds a rotation matrix from euler angles.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f64} local 1 (signature) - Euler x-angle.
;; @param {f64} local 2 (signature) - Euler y-angle.
;; @param {f64} local 3 (signature) - Euler z-angle.
;; @param {i32} local 4 (signature) - Axis order (see index.js).
;; @param {f32} local 5 (extra local) - cos(x).
;; @param {f32} local 6 (extra local) - sin(x).
;; @param {f32} local 7 (extra local) - cos(y).
;; @param {f32} local 8 (extra local) - sin(y).
;; @param {f32} local 9 (extra local) - cos(z).
;; @param {f32} local 10 (extra local) - sin(z).
;; @param {f32} local 11 (extra local) - Temporary variable.
;; @param {f32} local 12 (extra local) - Temporary variable.
;; @param {f32} local 13 (extra local) - Temporary variable.
;; @param {f32} local 14 (extra local) - Temporary variable.
;; @param {v128} local 15 (extra local) - Temporary variable for (cosine, sine) f64x2 vector.
(func (export "makeRotationFromEuler") (type $1i32_3f64_1i32resultNone) (local f32 f32 f32 f32 f32 f32 f32 f32 f32 f32 v128)
    (set_local 0
        (call $identity (get_local 0))
    )
    (set_local 5
        (f32.demote_f64
            (f64x2.extract_lane 0
                (tee_local 15
                    (call $cossin (get_local 1))
                )
            )
        )
    )
    (set_local 6
        (f32.demote_f64
            (f64x2.extract_lane 1 (get_local 15))
        )
    )
    (set_local 7
        (f32.demote_f64
            (f64x2.extract_lane 0
                (tee_local 15
                    (call $cossin (get_local 2))
                )
            )
        )
    )
    (set_local 8
        (f32.demote_f64
            (f64x2.extract_lane 1 (get_local 15))
        )
    )
    (set_local 9
        (f32.demote_f64
            (f64x2.extract_lane 0
                (tee_local 15
                    (call $cossin (get_local 3))
                )
            )
        )
    )
    (set_local 10
        (f32.demote_f64
            (f64x2.extract_lane 1 (get_local 15))
        )
    )
    (block
        (if     ;; XYZ
            (i32.eq (get_local 4) (i32.const 0))
            (then
                (f32.store offset=0 align=4
                    (get_local 0)
                    (f32.mul (get_local 7) (get_local 9))
                )
                (f32.store offset=4 align=2
                    (get_local 0)
                    (f32.add
                        (tee_local 12
                            (f32.mul (get_local 5) (get_local 10))
                        )
                        (f32.mul
                            (get_local 8)
                            (tee_local 13
                                (f32.mul (get_local 6) (get_local 9))
                            )
                        )
                    )
                )
                (f32.store offset=8 align=2
                    (get_local 0)
                    (f32.sub
                        (tee_local 14
                            (f32.mul (get_local 6) (get_local 10))
                        )
                        (f32.mul
                            (tee_local 11
                                (f32.mul (get_local 5) (get_local 9))
                            )
                            (get_local 8)
                        )
                    )
                )

                (f32.store offset=16 align=4
                    (get_local 0)
                    (f32.neg
                        (f32.mul (get_local 7) (get_local 10))
                    )
                )
                (f32.store offset=20 align=2
                    (get_local 0)
                    (f32.sub
                        (get_local 11)
                        (f32.mul (get_local 14) (get_local 8))
                    )
                )
                (f32.store offset=24 align=2
                    (get_local 0)
                    (f32.add
                        (get_local 13)
                        (f32.mul (get_local 12) (get_local 8))
                    )
                )

                (f32.store offset=32 align=4 (get_local 0) (get_local 8))
                (f32.store offset=36 align=2
                    (get_local 0)
                    (f32.neg
                        (f32.mul (get_local 6) (get_local 7))
                    )
                )
                (f32.store offset=40 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 7))
                )
                (br 1)
            )
        )

        (if     ;; YXZ
            (i32.eq (get_local 4) (i32.const 1))
            (then
                (f32.store offset=0 align=4
                    (get_local 0)
                    (f32.add
                        (tee_local 11
                            (f32.mul (get_local 7) (get_local 9))
                        )
                        (f32.mul
                            (tee_local 14
                                (f32.mul (get_local 8) (get_local 10))
                            )
                            (get_local 6)
                        )
                    )
                )
                (f32.store offset=4 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 10))
                )
                (f32.store offset=8 align=2
                    (get_local 0)
                    (f32.sub
                        (f32.mul
                            (get_local 6)
                            (tee_local 12
                                (f32.mul (get_local 7) (get_local 10))
                            )
                        )
                        (tee_local 13
                            (f32.mul (get_local 8) (get_local 9))
                        )
                    )
                )

                (f32.store offset=16 align=4
                    (get_local 0)
                    (f32.sub
                        (f32.mul (get_local 13) (get_local 6))
                        (get_local 12)
                    )
                )
                (f32.store offset=20 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 9))
                )
                (f32.store offset=24 align=2
                    (get_local 0)
                    (f32.add
                        (get_local 14)
                        (f32.mul (get_local 11) (get_local 6))
                    )
                )
                (f32.store offset=32 align=4
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 8))
                )
                (f32.store offset=36 align=2
                    (get_local 0)
                    (f32.neg (get_local 6))
                )
                (f32.store offset=40 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 7))
                )
                (br 1)
            )
        )

        (if     ;; ZXY
            (i32.eq (get_local 4) (i32.const 2))
            (then
                (f32.store offset=0 align=4
                    (get_local 0)
                    (f32.sub
                        (tee_local 11
                            (f32.mul (get_local 7) (get_local 9))
                        )
                        (f32.mul
                            (tee_local 14
                                (f32.mul (get_local 8) (get_local 10))
                            )
                            (get_local 6)
                        )
                    )
                )
                (f32.store offset=4 align=2
                    (get_local 0)
                    (f32.add
                        (tee_local 12
                            (f32.mul (get_local 7) (get_local 10))
                        )
                        (f32.mul
                            (tee_local 13
                                (f32.mul (get_local 8) (get_local 9))
                            )
                            (get_local 6)
                        )
                    )
                )
                (f32.store offset=8 align=2
                    (get_local 0)
                    (f32.neg
                        (f32.mul (get_local 5) (get_local 8))
                    )
                )

                (f32.store offset=16 align=4
                    (get_local 0)
                    (f32.neg
                        (f32.mul (get_local 5) (get_local 10))
                    )
                )
                (f32.store offset=20 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 9))
                )
                (f32.store offset=24 align=2
                    (get_local 0)
                    (get_local 6)
                )

                (f32.store offset=32 align=4
                    (get_local 0)
                    (f32.add
                        (get_local 13)
                        (f32.mul (get_local 12) (get_local 6))
                    )
                )
                (f32.store offset=36 align=2
                    (get_local 0)
                    (f32.sub
                        (get_local 14)
                        (f32.mul (get_local 11) (get_local 6))
                    )
                )
                (f32.store offset=40 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 7))
                )
                (br 1)
            )
        )

        (if     ;; ZYX
            (i32.eq (get_local 4) (i32.const 3))
            (then
                (f32.store offset=0 align=4
                    (get_local 0)
                    (f32.mul (get_local 7) (get_local 9))
                )
                (f32.store offset=4 align=2
                    (get_local 0)
                    (f32.mul (get_local 7) (get_local 10))
                )
                (f32.store offset=8 align=2
                    (get_local 0)
                    (f32.neg (get_local 8))
                )

                (f32.store offset=16 align=4
                    (get_local 0)
                    (f32.sub
                        (f32.mul
                            (tee_local 13
                                (f32.mul (get_local 6) (get_local 9))
                            )
                            (get_local 8)
                        )
                        (tee_local 12
                            (f32.mul (get_local 5) (get_local 10))
                        )
                    )
                )
                (f32.store offset=20 align=2
                    (get_local 0)
                    (f32.add
                        (f32.mul
                            (tee_local 14
                                (f32.mul (get_local 6) (get_local 10))
                            )
                            (get_local 8)
                        )
                        (tee_local 11
                            (f32.mul (get_local 5) (get_local 9))
                        )
                    )
                )
                (f32.store offset=24 align=2
                    (get_local 0)
                    (f32.mul (get_local 6) (get_local 7))
                )

                (f32.store offset=32 align=4
                    (get_local 0)
                    (f32.add
                        (f32.mul (get_local 11) (get_local 8))
                        (get_local 14)
                    )
                )
                (f32.store offset=36 align=2
                    (get_local 0)
                    (f32.sub
                        (f32.mul (get_local 12) (get_local 8))
                        (get_local 13)
                    )
                )
                (f32.store offset=40 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 7))
                )
                (br 1)
            )
        )

        (if     ;; YZX
            (i32.eq (get_local 4) (i32.const 4))
            (then
                (f32.store offset=0 align=4
                    (get_local 0)
                    (f32.mul (get_local 7) (get_local 9))
                )
                (f32.store offset=4 align=2
                    (get_local 0)
                    (get_local 10)
                )
                (f32.store offset=8 align=2
                    (get_local 0)
                    (f32.neg
                        (f32.mul (get_local 8) (get_local 9))
                    )
                )

                (f32.store offset=16 align=4
                    (get_local 0)
                    (f32.sub
                        (tee_local 14
                            (f32.mul (get_local 6) (get_local 8))
                        )
                        (f32.mul
                            (tee_local 11
                                (f32.mul (get_local 5) (get_local 7))
                            )
                            (get_local 10)
                        )
                    )
                )
                (f32.store offset=20 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 9))
                )
                (f32.store offset=24 align=2
                    (get_local 0)
                    (f32.add
                        (f32.mul
                            (tee_local 12
                                (f32.mul (get_local 5) (get_local 8))
                            )
                            (get_local 10)
                        )
                        (tee_local 13
                            (f32.mul (get_local 6) (get_local 7))
                        )
                    )
                )

                (f32.store offset=32 align=4
                    (get_local 0)
                    (f32.add
                        (f32.mul (get_local 13) (get_local 10))
                        (get_local 12)
                    )
                )
                (f32.store offset=36 align=2
                    (get_local 0)
                    (f32.neg
                        (f32.mul (get_local 6) (get_local 9))
                    )
                )
                (f32.store offset=40 align=2
                    (get_local 0)
                    (f32.sub
                        (get_local 11)
                        (f32.mul (get_local 14) (get_local 10))
                    )
                )
                (br 1)
            )
        )

        (if     ;; XZY
            (i32.eq (get_local 4) (i32.const 5))
            (then
                (f32.store offset=0 align=4
                    (get_local 0)
                    (f32.mul (get_local 7) (get_local 9))
                )
                (f32.store offset=4 align=2
                    (get_local 0)
                    (f32.add
                        (f32.mul
                            (tee_local 11
                                (f32.mul (get_local 5) (get_local 7))
                            )
                            (get_local 10)
                        )
                        (tee_local 14
                            (f32.mul (get_local 6) (get_local 8))
                        )
                    )
                )
                (f32.store offset=8 align=2
                    (get_local 0)
                    (f32.sub
                        (f32.mul
                            (tee_local 13
                                (f32.mul (get_local 6) (get_local 7))
                            )
                            (get_local 10)
                        )
                        (tee_local 12
                            (f32.mul (get_local 5) (get_local 8))
                        )
                    )
                )

                (f32.store offset=16 align=4
                    (get_local 0)
                    (f32.neg (get_local 10))
                )
                (f32.store offset=20 align=2
                    (get_local 0)
                    (f32.mul (get_local 5) (get_local 9))
                )
                (f32.store offset=24 align=2
                    (get_local 0)
                    (f32.mul (get_local 6) (get_local 9))
                )

                (f32.store offset=32 align=4
                    (get_local 0)
                    (f32.mul (get_local 8) (get_local 9))
                )
                (f32.store offset=36 align=2
                    (get_local 0)
                    (f32.sub
                        (f32.mul (get_local 12) (get_local 10))
                        (get_local 13)
                    )
                )
                (f32.store offset=40 align=2
                    (get_local 0)
                    (f32.add
                        (f32.mul (get_local 14) (get_local  10))
                        (get_local 11)
                    )
                )
                (br 1)
            )
        )
    )
)

;; 24 - Builds a scale matrix.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - x-scale.
;; @param {f32} local 2 (signature) - y-scale.
;; @param {f32} local 3 (signature) - z-scale.
(func (export "makeScale_d") (type $1i32_3f32resultNone)
    (f32.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (get_local 1)
    )
    (f32.store offset=20 align=2 (get_local 0) (get_local 2))
    (f32.store offset=40 align=2 (get_local 0) (get_local 3))
)

;; 25 - Builds a shear matrix.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - x-shear.
;; @param {f32} local 2 (signature) - y-shear.
;; @param {f32} local 3 (signature) - z-shear.
(func (export "makeShear_d") (type $1i32_3f32resultNone)
    ;; locals : 0 (matrix slot), 1 (x), 2 (y), 3 (z)
    (f32.store offset=4 align=2                                     ;; x
        (tee_local 0
            (call $identity (get_local 0))
        )
        (get_local 1)
    )
    (f32.store offset=8 align=2 (get_local 0) (get_local 1))
    (f32.store offset=16 align=4 (get_local 0) (get_local 2))       ;; y
    (f32.store offset=24 align=2 (get_local 0) (get_local 2))
    (f32.store offset=32 align=4 (get_local 0) (get_local 3))       ;; z
    (f32.store offset=36 align=2 (get_local 0) (get_local 3))
)

;; 26 - Builds a translation matrix.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - x-translation.
;; @param {f32} local 2 (signature) - y-translation.
;; @param {f32} local 3 (signature) - z-translation.
(func (export "makeTranslation_d") (type $1i32_3f32resultNone)
    (f32.store offset=48 align=4
        (tee_local 0 (call $identity (get_local 0)))
        (get_local 1)
    )
    (f32.store offset=52 align=2 (get_local 0) (get_local 2))
    (f32.store offset=56 align=2 (get_local 0) (get_local 3))
)

;; 27 - Builds a transpose matrix.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (extra local) - Temporary variable.
(func (export "transpose_d") (type $1i32resultNone) (local f32)
    (set_local 1
        (f32.load offset=4 align=2
            (tee_local 0
                (call $mapMatrixSlotToMemoryOffset (get_local 0))
            )
        )
    )
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.load offset=16 align=4 (get_local 0))
    )
    (f32.store offset=16 align=4 (get_local 0) (get_local 1))
    (set_local 1
        (f32.load offset=8 align=2 (get_local 0))
    )
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.load offset=32 align=4 (get_local 0))
    )
    (f32.store offset=32 align=4 (get_local 0) (get_local 1))
    (set_local 1
        (f32.load offset=12 align=2 (get_local 0))
    )
    (f32.store offset=12 align=2
        (get_local 0)
        (f32.load offset=48 align=4 (get_local 0))
    )
    (f32.store offset=48 align=4 (get_local 0) (get_local 1))
    (set_local 1
        (f32.load offset=24 align=2 (get_local 0))
    )
    (f32.store offset=24 align=2
        (get_local 0)
        (f32.load offset=36 align=2 (get_local 0))
    )
    (f32.store offset=36 align=2 (get_local 0) (get_local 1))
    (set_local 1
        (f32.load offset=28 align=2 (get_local 0))
    )
    (f32.store offset=28 align=2
        (get_local 0)
        (f32.load offset=52 align=2 (get_local 0))
    )
    (f32.store offset=52 align=2 (get_local 0) (get_local 1))
    (set_local 1
        (f32.load offset=44 align=2 (get_local 0))
    )
    (f32.store offset=44 align=2
        (get_local 0)
        (f32.load offset=56 align=2 (get_local 0))
    )
    (f32.store offset=56 align=2 (get_local 0) (get_local 1))
)

;; 28 - Normalizes a 3d vector
;; @param {i32} local 0 (signature) - Memory offset for the vector to be normalized, multiple of 16.
;; @param {f32} local 1 (extra local) - Temporary variable for storing inverted length.
(func $normalize (export "normalize_u") (type $1i32resulti32) (local f32)
    (f32.store offset=0 align=4
        (get_local 0)
        (f32.mul
            (f32.load offset=0 align=4
                (tee_local 1
                    (f32.div
                        (f32.const 1.0)
                        (call $length (get_local 0))
                    )
                )
                (get_local 0)
            )
        )
    )
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=4 align=2 (get_local 1) (get_local 0))
        )
    )
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=8 align=2 (get_local 1) (get_local 0))
        )
    )
    get_local 0
)

;; 29 - Scales matrix
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - x-scale.
;; @param {f32} local 2 (signature) - y-scale.
;; @param {f32} local 3 (signature) - z-scale.
(func (export "scale_d") (type $1i32_3f32resultNone)
    (v128.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f32x4.mul
            (f32x4.splat (get_local 1))
            (v128.load offset=0 align=4 (get_local 0))
        )
    )
    (v128.store offset=16 align=4
        (get_local 0)
        (f32x4.mul
            (f32x4.splat (get_local 2))
            (v128.load offset=16 align=4 (get_local 0))
        )
    )
    (v128.store offset=32 align=4
        (get_local 0)
        (f32x4.mul
            (f32x4.splat (get_local 3))
            (v128.load offset=32 align=4 (get_local 0))
        )
    )
)

;; 30 - Sets position
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - x position.
;; @param {f32} local 2 (signature) - y position.
;; @param {f32} local 3 (signature) - z position.
(func (export "setPosition_d") (type $1i32_3f32resultNone)
    (f32.store offset=48 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (get_local 1)
    )
    (f32.store offset=52 align=2 (get_local 0) (get_local 2))
    (f32.store offset=56 align=2 (get_local 0) (get_local 3))
)

;; 28 - Stores 3d vector inside reserved memory.
;; @param {i32} local 0 (signature) - Memory offset for resulting vector, multiple of 16.
;; @param {f32} local 1 (signature) - x coordinate.
;; @param {f32} local 2 (signature) - y coordinate.
;; @param {f32} local 3 (signature) - z coordinate.
;; @returns {i32} - Matrix starting memory address in byte offset.
(func $storeVector (export "storeVector_u") (type $1i32_3f32resulti32)
    (f32.store offset=0 align=4 (get_local 0) (get_local 1))
    (f32.store offset=4 align=2 (get_local 0) (get_local 2))
    (f32.store offset=8 align=2 (get_local 0) (get_local 3))
    (f32.store offset=12 align=2 (get_local 0) (f32.const 0))
    get_local 0
)

;; 29 - Substracts 3d vectors from reserved memory.
;; @param {i32} local 0 (signature) - Memory offset for resulting vector, multiple of 16.
;; @param {i32} local 1 (signature) - Memory offset for first vector, multiple of 16.
;; @param {i32} local 2 (signature) - Memory offset for subtracted vector, multiple of 16.
;; @returns {i32} - Same as local 0.
(func $subVectors (export "subVectors_u") (type $3i32resulti32)
    (v128.store offset=0 align=4
        (get_local 0)
        (f32x4.sub
            (v128.load offset=0 align=4 (get_local 1))
            (v128.load offset=0 align=4 (get_local 2))
        )
    )
    get_local 0
)

;; 30 - Computes cross products of 3d vectors from and to reserved memory.
;; @param {i32} local 0 (signature) - Memory offset for resulting vector, multiple of 16.
;; @param {i32} local 1 (signature) - Memory offset for first vector, multiple of 16.
;; @param {i32} local 2 (signature) - Memory offset for subtracted vector, multiple of 16.
;; @param {v128} local 3 (extra local) - (vector-1 y,vector-1 z,vector-1 y) * vector 2
;; @param {v128} local 4 (extra local) - (vector-1 z, vector-1 x , vector-1 x) * vector 2
;; @returns {i32} - Same as local 0.
(func $crossVectors (export "crossVectors_u") (type $3i32resulti32) (local v128 v128)
    (f32.store offset=0 align=4     ;; x-component
        (get_local 0)
        (f32.sub
            (f32x4.extract_lane 2
                (tee_local 3
                    (f32x4.mul
                        (f32x4.replace_lane 1
                            (f32x4.splat
                                (f32.load offset=4 align=2 (get_local 1))
                            )
                            (f32.load offset=8 align=2 (get_local 1))
                        )
                        (v128.load offset=0 align=4 (get_local 2))
                    )
                )
            )
            (f32x4.extract_lane 1 (get_local 3))
        )
    )
    (f32.store offset=4 align=2     ;; y-component
        (get_local 0)
        (f32.sub
            (f32x4.extract_lane 0
                (tee_local 4
                    (f32x4.mul
                        (f32x4.replace_lane 0
                            (f32x4.splat
                                (f32.load offset=0 align=4 (get_local 1))
                            )
                            (f32.load offset=8 align=2 (get_local 1))
                        )
                        (v128.load offset=0 align=4 (get_local 2))
                    )
                )
            )
            (f32x4.extract_lane 2 (get_local 4))
        )
    )
    (f32.store offset=8 align=2     ;; z-component
        (get_local 0)
        (f32.sub
            (f32x4.extract_lane 1 (get_local 4))
            (f32x4.extract_lane 0 (get_local 3))
        )
    )
    get_local 0
)

;; 34 - Computes matrix determinant.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @returns {f32} - Determinant value.
(func $determinant (export "determinant_d") (type $1i32resultf32)
    (f32.add
        (f32.add
            (f32.add
                (if (result f32)
                    (i32.trunc_s/f32
                        (f32.load offset=12 align=2
                            (tee_local 0
                                (call $mapMatrixSlotToMemoryOffset (get_local 0))
                            )
                        )
                    )
                    (then
                        (f32.mul
                            (f32.load offset=12 align=2 (get_local 0))
                            (f32.add
                                (f32.mul
                                    (f32.load offset=24 align=2 (get_local 0))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=36 align=2 (get_local 0))
                                            (f32.load offset=48 align=4 (get_local 0))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 0))
                                            (f32.load offset=52 align=2 (get_local 0))
                                        )
                                    )
                                )
                                (f32.add
                                    (f32.mul
                                        (f32.load offset=40 align=2 (get_local 0))
                                        (f32.sub
                                            (f32.mul
                                                (f32.load offset=16 align=4 (get_local 0))
                                                (f32.load offset=52 align=2 (get_local 0))
                                            )
                                            (f32.mul
                                                (f32.load offset=20 align=2 (get_local 0))
                                                (f32.load offset=48 align=4 (get_local 0))
                                            )
                                        )
                                    )
                                    (f32.mul
                                        (f32.load offset=56 align=2 (get_local 0))
                                        (f32.sub
                                            (f32.mul
                                                (f32.load offset=20 align=2 (get_local 0))
                                                (f32.load offset=32 align=4 (get_local 0))
                                            )
                                            (f32.mul
                                                (f32.load offset=16 align=4 (get_local 0))
                                                (f32.load offset=36 align=2 (get_local 0))
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                    (else (f32.const 0.0))
                )
                (if (result f32)
                    (i32.trunc_s/f32
                        (f32.load offset=28 align=2 (get_local 0))
                    )
                    (then
                        (f32.mul
                            (f32.load offset=28 align=2 (get_local 0))
                            (f32.add
                                (f32.mul
                                    (f32.load offset=56 align=2 (get_local 0))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=36 align=2 (get_local 0))
                                            (f32.load offset=0 align=4 (get_local 0))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 0))
                                            (f32.load offset=4 align=2 (get_local 0))
                                        )
                                    )
                                )
                                (f32.add
                                    (f32.mul
                                        (f32.load offset=40 align=2 (get_local 0))
                                        (f32.sub
                                            (f32.mul
                                                (f32.load offset=48 align=4 (get_local 0))
                                                (f32.load offset=4 align=2 (get_local 0))
                                            )
                                            (f32.mul
                                                (f32.load offset=52 align=2 (get_local 0))
                                                (f32.load offset=0 align=4 (get_local 0))
                                            )
                                        )
                                    )
                                    (f32.mul
                                        (f32.load offset=8 align=2 (get_local 0))
                                        (f32.sub
                                            (f32.mul
                                                (f32.load offset=52 align=2 (get_local 0))
                                                (f32.load offset=32 align=4 (get_local 0))
                                            )
                                            (f32.mul
                                                (f32.load offset=48 align=4 (get_local 0))
                                                (f32.load offset=36 align=2 (get_local 0))
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                    (else (f32.const 0.0))
                )
            )
            (if (result f32)
                (i32.trunc_s/f32
                    (f32.load offset=44 align=2 (get_local 0))
                )
                (then
                    (f32.mul
                        (f32.load offset=44 align=2 (get_local 0))
                        (f32.add
                            (f32.mul
                                (f32.load offset=24 align=2 (get_local 0))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=52 align=2 (get_local 0))
                                        (f32.load offset=0 align=4 (get_local 0))
                                    )
                                    (f32.mul
                                        (f32.load offset=48 align=4 (get_local 0))
                                        (f32.load offset=4 align=2 (get_local 0))
                                    )
                                )
                            )
                            (f32.add
                                (f32.mul
                                    (f32.load offset=56 align=2 (get_local 0))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 0))
                                            (f32.load offset=4 align=2 (get_local 0))
                                        )
                                        (f32.mul
                                            (f32.load offset=20 align=2 (get_local 0))
                                            (f32.load offset=0 align=4 (get_local 0))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=8 align=2 (get_local 0))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=20 align=2 (get_local 0))
                                            (f32.load offset=48 align=4 (get_local 0))
                                        )
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 0))
                                            (f32.load offset=52 align=2 (get_local 0))
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
                (else (f32.const 0.0))
            )
        )
        (if (result f32)
            (i32.trunc_s/f32
                (f32.load offset=60 align=2 (get_local 0))
            )
            (then
                (f32.mul
                    (f32.load offset=60 align=2 (get_local 0))
                    (f32.add
                        (f32.mul
                            (f32.load offset=8 align=2 (get_local 0))
                            (f32.sub
                                (f32.mul
                                    (f32.load offset=36 align=2 (get_local 0))
                                    (f32.load offset=16 align=4 (get_local 0))
                                )
                                (f32.mul
                                    (f32.load offset=32 align=4 (get_local 0))
                                    (f32.load offset=20 align=2 (get_local 0))
                                )
                            )
                        )
                        (f32.add
                            (f32.mul
                                (f32.load offset=24 align=2 (get_local 0))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=32 align=4 (get_local 0))
                                        (f32.load offset=4 align=2 (get_local 0))
                                    )
                                    (f32.mul
                                        (f32.load offset=36 align=2 (get_local 0))
                                        (f32.load offset=0 align=4 (get_local 0))
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=40 align=2 (get_local 0))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=20 align=2 (get_local 0))
                                        (f32.load offset=0 align=2 (get_local 0))
                                    )
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 0))
                                        (f32.load offset=4 align=2 (get_local 0))
                                    )
                                )
                            )
                        )
                    )
                )
            )
            (else (f32.const 0.0))
        )
    )
)

;; 35 - Checks if two matrices are equal.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @returns {i32} - value 1 if matrices are equal, 0 otherwise.
(func $equals (export "equals") (type $2i32resulti32) (local i32)
    (set_local 0
        (call $mapMatrixSlotToMemoryOffset (get_local 0))
    )
    (set_local 1
        (call $mapMatrixSlotToMemoryOffset (get_local 1))
    )
    (block (result i32)
        (loop (result i32)
            (if (result i32)
                (f32.ne
                    (f32.load offset=0 align=2
                       (i32.add (get_local 0) (get_local 2))
                    )
                    (f32.load offset=0 align=2
                       (i32.add (get_local 1) (get_local 2))
                    )
                )
                (then
                    (i32.const 0)
                    (br 2)
                )
                (else
                    (if (result i32)
                        (i32.eq
                            (i32.const 64)
                            (tee_local 2
                                (i32.add (get_local 2) (i32.const 4))
                            )
                        )
                        (then
                            (i32.const 1)
                            (br 3)
                        )
                        (else (br 2))
                    )
                )
            )
        )
    )
)

;; 36 - Computes inverse matrix.
;; @param {i32} local 0 (signature) - Slot for the resulting matrix (inverse).
;; @param {i32} local 1 (signature) - Slot for the processed matrix.
;; @param {f32} local 2 (extra local) - Matrix determinant.
(func (export "getInverse") (type $2i32resultNone) (local f32)
    (if (i32.trunc_s/f32
            (tee_local 2
                (call $determinant (get_local 1))
            )
        )
        (then
            (block
                (set_local 2
                    (f32.div (f32.const 1.0) (get_local 2))
                )
                (f32.store offset=0 align=4
                    (tee_local 0
                        (call $mapMatrixSlotToMemoryOffset (get_local 0))
                    )
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=28 align=2
                                        (tee_local 1
                                            (call $mapMatrixSlotToMemoryOffset (get_local 1))
                                        )
                                    )
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=36 align=2 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=52 align=2 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=44 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=52 align=2 (get_local 1))
                                            (f32.load offset=24 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=20 align=2 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=20 align=2 (get_local 1))
                                        (f32.load offset=40 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=36 align=2 (get_local 1))
                                        (f32.load offset=24 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=4 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=52 align=2 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=36 align=2 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=44 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=4 align=2 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=52 align=2 (get_local 1))
                                            (f32.load offset=8 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=36 align=2 (get_local 1))
                                        (f32.load offset=8 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=4 align=2 (get_local 1))
                                        (f32.load offset=40 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=8 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=20 align=2 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=52 align=2 (get_local 1))
                                            (f32.load offset=24 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=52 align=2 (get_local 1))
                                            (f32.load offset=8 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=4 align=2 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=4 align=2 (get_local 1))
                                        (f32.load offset=24 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=20 align=2 (get_local 1))
                                        (f32.load offset=8 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=12 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=36 align=2 (get_local 1))
                                            (f32.load offset=24 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=20 align=2 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=4 align=2 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=36 align=2 (get_local 1))
                                            (f32.load offset=8 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=44 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=20 align=2 (get_local 1))
                                        (f32.load offset=8 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=4 align=2 (get_local 1))
                                        (f32.load offset=24 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=16 align=4
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=44 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=24 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=32 align=4 (get_local 1))
                                        (f32.load offset=24 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=40 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=20 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=44 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=8 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=40 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=32 align=4 (get_local 1))
                                        (f32.load offset=8 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=24 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=24 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=56 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=8 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=8 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=24 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=28 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=24 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=8 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=40 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=44 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=24 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=8 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=32 align=4
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=44 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=20 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=36 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=32 align=4 (get_local 1))
                                        (f32.load offset=20 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=36 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=44 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=4 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=32 align=4 (get_local 1))
                                        (f32.load offset=4 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=36 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=40 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=20 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=4 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=60 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=20 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=4 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=44 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=12 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=20 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=28 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=4 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=44 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=4 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=20 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=48 align=4
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=24 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=40 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=20 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=56 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=32 align=4 (get_local 1))
                                        (f32.load offset=20 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=36 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=52 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=8 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=40 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=4 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=56 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=36 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=32 align=4 (get_local 1))
                                        (f32.load offset=4 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=56 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=8 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=20 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=24 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=52 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=48 align=4 (get_local 1))
                                            (f32.load offset=4 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=56 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=4 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=20 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
                (f32.store offset=60 align=2
                    (get_local 0)
                    (f32.mul
                        (get_local 2)
                        (f32.add
                            (f32.add
                                (f32.mul
                                    (f32.load offset=8 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=16 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=20 align=2 (get_local 1))
                                        )
                                    )
                                )
                                (f32.mul
                                    (f32.load offset=24 align=2 (get_local 1))
                                    (f32.sub
                                        (f32.mul
                                            (f32.load offset=32 align=4 (get_local 1))
                                            (f32.load offset=4 align=2 (get_local 1))
                                        )
                                        (f32.mul
                                            (f32.load offset=0 align=4 (get_local 1))
                                            (f32.load offset=36 align=2 (get_local 1))
                                        )
                                    )
                                )
                            )
                            (f32.mul
                                (f32.load offset=40 align=2 (get_local 1))
                                (f32.sub
                                    (f32.mul
                                        (f32.load offset=0 align=4 (get_local 1))
                                        (f32.load offset=20 align=2 (get_local 1))
                                    )
                                    (f32.mul
                                        (f32.load offset=16 align=4 (get_local 1))
                                        (f32.load offset=4 align=2 (get_local 1))
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
        (else
            (drop (call $clear (get_local 0)))
        )
    )
)

;; 37 - Gets maximum scale.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @returns {i32} - Max scale.
(func (export "getMaxScaleOnAxis_d") (type $1i32resultf32) (local f32 f32 f32)
    (f32.sqrt
        (f32.max
            (f32.max
                (call $lengthSquare
                    (tee_local 0
                        (call $mapMatrixSlotToMemoryOffset (get_local 0))
                    )
                )
                (call $lengthSquare
                    (i32.add (i32.const 16) (get_local 0))
                )
            )
            (call $lengthSquare
                (i32.add (i32.const 32) (get_local 0))
            )
        )
    )
)

)
