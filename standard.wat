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
;; At the moment value 2 used instead of 3, but not optimized.
(module

;; Imported memory for matrix storage
(import "" "mem" (memory 1))

;; memory to store the matrices
(global $f32epsilon f32 (f32.const 0.0001))
(global $f64epsilon f64 (f64.const 0.00000001))
(global $f64halfPi f64 (f64.const 1.570796326794896619231))

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


;; 0 - Partial cosine : 16th-order Taylor serie
;; => quasi-exact value between -PI and PI once demoted to float32.
;; TODO: find better algorithms (even for low-end ARM architectures),
;; like restricting to 0-PI/4 and using more symmetry.
;; @param {f64} local 0 (signature) - Angle in radians.
;; @param {f64} local 1 (extra local) - Temporary variable.
;; @returns {f64} - Cosine value.
(func $halfPeriodCos (type $1f64resultf64) (local f64)
    (f64.add
        (f64.const 1.0)
        (f64.mul
            (tee_local 1
                (f64.mul (get_local 0) (get_local 0))
            )
            (f64.add
                (f64.const -0.5)
                (f64.mul
                    (f64.mul (f64.const 4.1666666666666666666667E-2) (get_local 1))  ;; 1 / (2 * 3 x 4)
                    (f64.sub
                        (f64.const 1.0)
                        (f64.mul
                            (f64.mul (f64.const 3.3333333333333333333333E-2) (get_local 1)) ;; 1 / (5 x 6)
                            (f64.sub
                                (f64.const 1.0)
                                (f64.mul
                                    (f64.mul (f64.const 1.785714285714285714286E-2) (get_local 1))  ;; 1 / (7 x 8)
                                    (f64.sub
                                        (f64.const 1.0)
                                        (f64.mul
                                            (f64.mul (f64.const 1.111111111111111111111E-2) (get_local 1))  ;;  1 / (9 x 10)
                                            (f64.sub
                                                (f64.const 1.0)
                                                (f64.mul
                                                    (f64.mul (f64.const 7.575757575757575757576E-3) (get_local 1))  ;;  1 / (11 x 12)
                                                    (f64.sub
                                                        (f64.const 1.0)
                                                        (f64.mul
                                                            (f64.mul (f64.const 5.494505494505494505495E-3) (get_local 1))  ;;  1 / (13 x 14)
                                                            (f64.sub
                                                                (f64.const 1.0)
                                                                (f64.mul (f64.const 4.1666666666666666666667E-3) (get_local 1))  ;;  1 / (15 x 16)
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

;; 1 - Approximated Cosine to avoid JS-WebAssembly boundary crossing.
;; TODO: find better algorithms (even for low-end ARM architectures)
;; @param {f64} local 0 (signature) - Angle in radians in the range [-PI, 2PI].
;; @param {f64} local 1 (extra local) - Temporary variable.
;; @returns {f64} - Cosine value.
(func $approxCos (export "approxCos_u") (type $1f64resultf64)
    (if (result f64)
        (f64.lt (get_local 0) (f64.const 3.141592653589793238463))
        (then
            (call $halfPeriodCos (get_local 0))
        )
        (else   ;; using symmetry
            (call $halfPeriodCos
                (f64.sub (f64.const 6.283185307179586476925) (get_local 0))
            )
        )
    )
)

;; 2 - Sets cosine and sine at a specific memory address (cosine always before sine).
;; @param {f64} local 0 (signature) - Angle in radians.
;; @param {i32} local 1 (signature) - Memory address (in bytes) for storing the cosine value
;; @param {i32} local 2 (signature) - Memory address gap between the cosine value and the sine one (next one).
(func $sincos (export "sincos_u") (type $1f64_2i32resultfNone)
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
    (f32.store offset=0 align=2
        (get_local 1)
        (f32.demote_f64
            (call $approxCos (get_local 0))
        )
    )
    (f32.store offset=0 align=2
        (i32.add (get_local 1) (get_local 2))
        (f32.demote_f64
            (call $approxCos
                (f64.sub (get_local 0) (get_global $f64halfPi))
            )
        )
    )
)

;; 3 - Standard cosine approximation.
;; @param {f64} local 0 (signature) - Angle in radians.
;; @returns {f32} - Cosine value.
(func $cos (export "cos_u") (type $1f64resultf32)
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
    (f32.demote_f64
        (call $approxCos (get_local 0))
    )
)

;; 4 - Converts matrix slot to memory address.
;; @param {i32} local 0 (signature) - Matrix slot (corresponding to this.slot in the matrix constructor).
;; @returns {i32} - Matrix starting memory address in byte offset.
(func $mapMatrixSlotToMemoryOffset (type $1i32resulti32)
    (i32.shl (get_local 0) (i32.const 6))
)

;; 5 - Sets matrix values to zero.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @returns {i32} - Matrix starting memory address in byte offset.
(func $clear (export "clear") (type $1i32resulti32)
    (f64.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f64.const 0.0)
    )
    (f64.store offset=8 align=2 (get_local 0) (f64.const 0.0))
    (f64.store offset=16 align=4 (get_local 0) (f64.const 0.0))
    (f64.store offset=24 align=2 (get_local 0) (f64.const 0.0))
    (f64.store offset=32 align=4 (get_local 0) (f64.const 0.0))
    (f64.store offset=40 align=2 (get_local 0) (f64.const 0.0))
    (f64.store offset=48 align=4 (get_local 0) (f64.const 0.0))
    (f64.store offset=56 align=2 (get_local 0) (f64.const 0.0))
    get_local 0
)

;; 6 - Compose function
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
    ;; value 0
    (f32.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f32.mul
            (get_local 8)   ;; x-scale
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
    )
    ;; value 1
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.mul
            (get_local 8)   ;; x-scale
            (f32.add
                (tee_local 15 ;; xy
                    (f32.mul (get_local 4) (get_local 12))  ;; _x * (_y + _y)
                )
                (tee_local 22 ;; wz
                    (f32.mul (get_local 7) (get_local 13))
                )
            )
        )
    )
    ;; value 2
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.mul
            (get_local 8)   ;; x-scale
            (f32.sub
                (tee_local 16 ;; xz
                    (f32.mul (get_local 4) (get_local 13))
                )
                (tee_local 21 ;; wy
                    (f32.mul (get_local 7) (get_local 12))
                )
            )
        )
    )
    ;; value 3
    (f32.store offset=12 align=2 (get_local 0) (f32.const 0.0))

    ;; value 4
    (f32.store offset=16 align=4
        (get_local 0)
        (f32.mul
            (get_local 9)   ;; y-scale
            (f32.sub (get_local 15) (get_local 22)) ;; xy - wz
        )
    )
    ;; value 5
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.mul
            (get_local 9)   ;; y-scale
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
    )
    ;; value 6
    (f32.store offset=24 align=2
        (get_local 0)
        (f32.mul
            (get_local 9)   ;; y-scale
            (f32.add
                (tee_local 18 ;; yz
                    (f32.mul (get_local 5) (get_local 13))
                )
                (tee_local 20 ;; wx
                    (f32.mul (get_local 7) (get_local 11))
                )
            )
        )
    )
    ;; value 7
    (f32.store offset=28 align=2 (get_local 0) (f32.const 0.0))

    ;; value 8
    (f32.store offset=32 align=4
        (get_local 0)
        (f32.mul
            (get_local 10)  ;; z-scale
            (f32.add (get_local 16) (get_local 21)) ;; xz + wy
        )
    )
    ;; value 9
    (f32.store offset=36 align=2
        (get_local 0)
        (f32.mul
            (get_local 10)  ;; z-scale
            (f32.sub (get_local 18) (get_local 20)) ;; yz - wx
        )
    )
    ;; value 10
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.mul
            (get_local 10)  ;; z-scale
            (f32.sub
                (f32.const 1.0)
                (f32.add (get_local 14) (get_local 17)) ;; 1 - (xx + yy)
            )
        )
    )
    ;; value 11
    (f32.store offset=44 align=2 (get_local 0) (f32.const 0.0))

    ;; value 12
    (f32.store offset=48 align=4 (get_local 0) (get_local 1))
    ;; value 13
    (f32.store offset=52 align=2 (get_local 0) (get_local 2))
    ;; value 14
    (f32.store offset=56 align=2 (get_local 0) (get_local 3))
    ;; value 15
    (f32.store offset=60 align=2 (get_local 0) (f32.const 1.0))
)

;; 7 - Copy values from one matrix to another's.
;; @param {i32} local 0 (signature) - Source matrix slot.
;; @param {i32} local 1 (signature) - Destination matrix slot.
(func (export "copy") (type $2i32resultNone)
    (f64.store offset=0 align=4
        (tee_local 1
            (call $mapMatrixSlotToMemoryOffset (get_local 1))
        )
        (f64.load offset=0 align=4
            (tee_local 0
                (call $mapMatrixSlotToMemoryOffset (get_local 0))
            )
        )
    )
    (f64.store offset=8 align=2
        (get_local 1)
        (f64.load offset=8 (get_local 0))
    )
    (f64.store offset=16 align=4
        (get_local 1)
        (f64.load offset=16 (get_local 0))
    )
    (f64.store offset=24 align=2
        (get_local 1)
        (f64.load offset=24 (get_local 0))
    )
    (f64.store offset=32 align=4
        (get_local 1)
        (f64.load offset=32 (get_local 0))
    )
    (f64.store offset=40 align=2
        (get_local 1)
        (f64.load offset=40 (get_local 0))
    )
    (f64.store offset=48 align=4
        (get_local 1)
        (f64.load offset=48 (get_local 0))
    )
    (f64.store offset=56 align=2
        (get_local 1)
        (f64.load offset=56 (get_local 0))
    )
)

;; 8 - Copy matrix positions
;; @param {i32} local 0 (signature) - Source matrix slot.
;; @param {i32} local 1 (signature) - Destination matrix slot.
(func (export "copyPos") (type $2i32resultNone)
    (f64.store offset=48 align=4
        (tee_local 1
            (call $mapMatrixSlotToMemoryOffset (get_local 1))
        )
        (f64.load offset=48 align=4
            (tee_local 0
                (call $mapMatrixSlotToMemoryOffset (get_local 0))
            )
        )
    )
    (f32.store offset=56 align=2    ;; replace align=2 by align=3
        (get_local 1)
        (f32.load offset=56 align=2 (get_local 0))   ;; replace align=2 by align=3
    )
)

;; 9 - Extracts matrix rotation
;; @param {i32} local 0 (signature) - Slot of the matrix to rotated.
;; @param {i32} local 1 (signature) - Slot of the matrix whose rotation is extracted from.
(func (export "extractRotation") (type $2i32resultNone) (local f32)
    ;; TODO: deal with divide by zero
    (f32.store offset=0 align=4
        (tee_local 0
            (call $identity (get_local 0))
        )
        (f32.mul
            (tee_local 2
                (f32.div
                    (f32.const 1.0)
                    (call $length
                        (tee_local 1
                            (call $mapMatrixSlotToMemoryOffset (get_local 1))
                        )
                    )
                )
            )
            (f32.load offset=0 align=4 (get_local 1))
        )
    )
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.mul
            (get_local 2)
            (f32.load offset=4 align=2 (get_local 1))
        )
    )
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.mul
            (get_local 2)
            (f32.load offset=8 align=2 (get_local 1))
        )
    )

    (f32.store offset=16 align=4
        (get_local 0)
        (f32.mul
            (tee_local 2
                (f32.div
                    (f32.const 1.0)
                    (call $length
                        (i32.add (get_local 1) (i32.const 16))
                    )
                )
            )
            (f32.load offset=16 align=4 (get_local 1))
        )
    )
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.mul
            (get_local 2)
            (f32.load offset=20 align=2 (get_local 1))
        )
    )
    (f32.store offset=24 align=2
        (get_local 0)
        (f32.mul
            (get_local 2)
            (f32.load offset=24 align=2 (get_local 1))
        )
    )

    (f32.store offset=32 align=4
        (get_local 0)
        (f32.mul
            (tee_local 2
                (f32.div
                    (f32.const 1.0)
                    (call $length
                        (i32.add (get_local 1) (i32.const 32))
                    )
                )
            )
            (f32.load offset=32 align=4 (get_local 1))
        )
    )
    (f32.store offset=36 align=2
        (get_local 0)
        (f32.mul
            (get_local 2)
            (f32.load offset=36 align=2 (get_local 1))
        )
    )
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.mul
            (get_local 2)
            (f32.load offset=40 align=2 (get_local 1))
        )
    )
)

;; 10 - Sets matrix to identity
;; @param {i32} local 0 (signature) - Matrix slot.
;; @returns {i32} - Matrix starting memory address.
(func $identity (export "identity_d") (type $1i32resulti32)
    (f64.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f64.const 5.263544247e-315)         ;; equivalent to 1 followed by (next contiguous value) 0
    )
    (f64.store offset=8 align=2 (get_local 0) (f64.const 0.0))
    (f64.store offset=16 align=4 (get_local 0) (f64.const 0.0078125))   ;; equivalent to 0 followed by (next gontiguous value) 1
    (f64.store offset=24 align=2 (get_local 0) (f64.const 0.0))
    (f64.store offset=32 align=4 (get_local 0) (f64.const 0.0))
    (f64.store offset=40 align=2 (get_local 0) (f64.const 5.263544247e-315))
    (f64.store offset=48 align=4 (get_local 0) (f64.const 0.0))
    (f64.store offset=56 align=2 (get_local 0) (f64.const 0.0078125))
    get_local 0
)

;; 11 - Vector length
;; @param {i32} local 0 (signature) - Vector memory offset.
;; @returns {i32} - Vector length.
(func $length (export "norm_u") (type $1i32resultf32)
    (f32.sqrt
        (call $lengthSquare (get_local 0))
    )
)

;; 12 - Vector squared length
;; @param {i32} local 0 (signature) - Memory index in the reserved memory for the resulting vector, multiple of 16.
;; @returns {i32} - Vector squared length.
(func $lengthSquare (export "lengthSquare_u") (type $1i32resultf32)
    (f32.add
        (f32.mul
            (f32.load offset=0 align=4 (get_local 0))
            (f32.load offset=0 align=4 (get_local 0))
        )
        (f32.add
            (f32.mul
                (f32.load offset=4 align=2 (get_local 0))
                (f32.load offset=4 align=2 (get_local 0))
            )
            (f32.mul
                (f32.load offset=8 align=2 (get_local 0))
                (f32.load offset=8 align=2 (get_local 0))
            )
        )
    )
)

;; 13 - Generates a "lookAt" matrix
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

;; 14 - Matrix multiplication.
;; @param {i32} local 0 (signature) - Matrix slot to store the resulting matrix (C = A x B).
;; @param {i32} local 1 (signature) - First matrix (A).
;; @param {i32} local 2 (signature) - Second matrix (B).
(func (export "mul") (type $3i32resultNone)
    ;; column 1
    (f32.store offset=0 align=4
        (tee_local 2 (call $mapMatrixSlotToMemoryOffset (get_local 2)))
        (f32.add
            (f32.mul
                (f32.load offset=0 align=4
                    (tee_local 0
                        (call $mapMatrixSlotToMemoryOffset (get_local 0))
                    )
                )
                (f32.load offset=0 align=4
                    (tee_local 1
                        (call $mapMatrixSlotToMemoryOffset (get_local 1))
                    )
                )
            )
            (f32.add
                (f32.mul
                    (f32.load offset=16 align=4 (get_local 0))
                    (f32.load offset=4 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=32 align=4 (get_local 0))
                        (f32.load offset=8 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=48 align=4 (get_local 0))
                        (f32.load offset=12 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=4 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=4 align=2 (get_local 0))
                (f32.load offset=0 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=20 align=2 (get_local 0))
                    (f32.load offset=4 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=36 align=2 (get_local 0))
                        (f32.load offset=8 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=52 align=2 (get_local 0))
                        (f32.load offset=12 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=8 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=8 align=2 (get_local 0))
                (f32.load offset=0 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=24 align=2 (get_local 0))
                    (f32.load offset=4 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=40 align=2 (get_local 0))
                        (f32.load offset=8 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=56 align=2 (get_local 0))
                        (f32.load offset=12 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=12 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=12 align=2 (get_local 0))
                (f32.load offset=0 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=28 align=2 (get_local 0))
                    (f32.load offset=4 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=44 align=2 (get_local 0))
                        (f32.load offset=8 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=60 align=2 (get_local 0))
                        (f32.load offset=12 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    ;; column 2
    (f32.store offset=16 align=4
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=0 align=4 (get_local 0))
                (f32.load offset=16 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=16 align=4 (get_local 0))
                    (f32.load offset=20 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=32 align=4 (get_local 0))
                        (f32.load offset=24 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=48 align=4 (get_local 0))
                        (f32.load offset=28 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=20 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=4 align=2 (get_local 0))
                (f32.load offset=16 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=20 align=2 (get_local 0))
                    (f32.load offset=20 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=36 align=2 (get_local 0))
                        (f32.load offset=24 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=52 align=2 (get_local 0))
                        (f32.load offset=28 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=24 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=8 align=2 (get_local 0))
                (f32.load offset=16 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=24 align=2 (get_local 0))
                    (f32.load offset=20 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=40 align=2 (get_local 0))
                        (f32.load offset=24 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=56 align=2 (get_local 0))
                        (f32.load offset=28 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=28 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=12 align=2 (get_local 0))
                (f32.load offset=16 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=28 align=2 (get_local 0))
                    (f32.load offset=20 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=44 align=2 (get_local 0))
                        (f32.load offset=24 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=60 align=2 (get_local 0))
                        (f32.load offset=28 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    ;; column 3
    (f32.store offset=32 align=4
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=0 align=4 (get_local 0))
                (f32.load offset=32 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=16 align=4 (get_local 0))
                    (f32.load offset=36 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=32 align=4 (get_local 0))
                        (f32.load offset=40 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=48 align=4 (get_local 0))
                        (f32.load offset=44 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=36 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=4 align=2 (get_local 0))
                (f32.load offset=32 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=20 align=2 (get_local 0))
                    (f32.load offset=36 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=36 align=2 (get_local 0))
                        (f32.load offset=40 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=52 align=2 (get_local 0))
                        (f32.load offset=44 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=40 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=8 align=2 (get_local 0))
                (f32.load offset=32 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=24 align=2 (get_local 0))
                    (f32.load offset=36 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=40 align=2 (get_local 0))
                        (f32.load offset=40 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=56 align=2 (get_local 0))
                        (f32.load offset=44 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=44 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=12 align=2 (get_local 0))
                (f32.load offset=32 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=28 align=2 (get_local 0))
                    (f32.load offset=36 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=44 align=2 (get_local 0))
                        (f32.load offset=40 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=60 align=2 (get_local 0))
                        (f32.load offset=44 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    ;; column 4
    (f32.store offset=48 align=4
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=0 align=4 (get_local 0))
                (f32.load offset=48 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=16 align=4 (get_local 0))
                    (f32.load offset=52 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=32 align=4 (get_local 0))
                        (f32.load offset=56 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=48 align=4 (get_local 0))
                        (f32.load offset=60 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=52 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=4 align=2 (get_local 0))
                (f32.load offset=48 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=20 align=2 (get_local 0))
                    (f32.load offset=52 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=36 align=2 (get_local 0))
                        (f32.load offset=56 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=52 align=2 (get_local 0))
                        (f32.load offset=60 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=56 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=8 align=2 (get_local 0))
                (f32.load offset=48 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=24 align=2 (get_local 0))
                    (f32.load offset=52 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=40 align=2 (get_local 0))
                        (f32.load offset=56 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=56 align=2 (get_local 0))
                        (f32.load offset=60 align=2 (get_local 1))
                    )
                )
            )
        )
    )
    (f32.store offset=60 align=2
        (get_local 2)
        (f32.add
            (f32.mul
                (f32.load offset=12 align=2 (get_local 0))
                (f32.load offset=48 align=4 (get_local 1))
            )
            (f32.add
                (f32.mul
                    (f32.load offset=28 align=2 (get_local 0))
                    (f32.load offset=52 align=2 (get_local 1))
                )
                (f32.add
                    (f32.mul
                        (f32.load offset=44 align=2 (get_local 0))
                        (f32.load offset=56 align=2 (get_local 1))
                    )
                    (f32.mul
                        (f32.load offset=60 align=2 (get_local 0))
                        (f32.load offset=60 align=2 (get_local 1))
                    )
                )
            )
        )
    )
)

;; 15 - Multiplies matrix by a number.
;; @param {i32} local 0 (signature) - Matrix slot.
;; @param {f32} local 1 (signature) - Value to multiply the matrix with.
(func (export "multiplyScalar_d") (type $1i32_1f32resultNone)
    (f32.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f32.mul
            (get_local 1)
            (f32.load offset=0 align=4 (get_local 0))
        )
    )
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=4 align=2 (get_local 0))
        )
    )
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=8 align=2 (get_local 0))
        )
    )
    (f32.store offset=12 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=12 align=2 (get_local 0))
        )
    )
    (f32.store offset=16 align=4
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=16 align=4 (get_local 0))
        )
    )
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=20 align=2 (get_local 0))
        )
    )
    (f32.store offset=24 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=24 align=2 (get_local 0))
        )
    )
    (f32.store offset=28 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=28 align=2 (get_local 0))
        )
    )
    (f32.store offset=32 align=4
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=32 align=4 (get_local 0))
        )
    )
    (f32.store offset=36
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=36 (get_local 0))
        )
    )
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=40 align=2 (get_local 0))
        )
    )
    (f32.store offset=44 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=44 align=2 (get_local 0))
        )
    )
    (f32.store offset=48 align=4
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=48 align=4 (get_local 0))
        )
    )
    (f32.store offset=52 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=52 align=2(get_local 0))
        )
    )
    (f32.store offset=56 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=56 align=2 (get_local 0))
        )
    )
    (f32.store offset=60 align=2
        (get_local 0)
        (f32.mul
            (get_local 1)
            (f32.load offset=60 align=2 (get_local 0))
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
(func (export "makeRotationAxis_d") (type $1i32_1f64_3f32resultNone) (local f32 f32 f32 f32)
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
                                (tee_local 5
                                    (call $cos (get_local 1))
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
                (tee_local 6
                    (call $cos
                        (f64.sub (get_local 1) (get_global $f64halfPi))
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
(func (export "makeRotationX_d") (type $1i32_1f64resultNone)
    (call $sincos
        (get_local 1)                   ;; angle
        (i32.add                        ;; memory offset for cosine
            (tee_local 0
                (call $identity (get_local 0))
            )
            (i32.const 20)
        )
        (i32.const 4)                   ;; memory gap between cosine and sine
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
(func (export "makeRotationY_d") (type $1i32_1f64resultNone)
    (call $sincos
        (get_local 1)                   ;; angle
        (tee_local 0                    ;; memory offset for cosine
            (call $identity (get_local 0))
        )
        (i32.const 32)                   ;; memory gap between cosine and sine
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
(func (export "makeRotationZ_d") (type $1i32_1f64resultNone)
    (call $sincos
        (get_local 1)                   ;; angle
        (tee_local 0                    ;; memory offset for cosine
            (call $identity (get_local 0))
        )
        (i32.const 4)                   ;; memory gap between cosine and sine
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
(func (export "makeRotationFromEuler") (type $1i32_3f64_1i32resultNone) (local f32 f32 f32 f32 f32 f32 f32 f32 f32 f32)
    (set_local 0
        (call $identity (get_local 0))
    )
    (set_local 5
        (call $cos (get_local 1))
    )
    (set_local 6
        (call $cos
            (f64.sub (get_local 1) (get_global $f64halfPi))
        )
    )
    (set_local 7
        (call $cos (get_local 2))
    )
    (set_local 8
        (call $cos
            (f64.sub (get_local 2) (get_global $f64halfPi))
        )
    )
    (set_local 9
        (call $cos (get_local 3))
    )
    (set_local 10
        (call $cos
            (f64.sub (get_local 3) (get_global $f64halfPi))
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
    (f32.store offset=0 align=4
        (tee_local 0
            (call $mapMatrixSlotToMemoryOffset (get_local 0))
        )
        (f32.mul
            (f32.load offset=0 align=4 (get_local 0))
            (get_local 1)
        )
    )
    (f32.store offset=4 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=4 align=2 (get_local 0))
            (get_local 1)
        )
    )
    (f32.store offset=8 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=8 align=2 (get_local 0))
            (get_local 1)
        )
    )
    (f32.store offset=12 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=12 align=2 (get_local 0))
            (get_local 1)
        )
    )

    (f32.store offset=16 align=4
        (get_local 0)
        (f32.mul
            (f32.load offset=16 align=4 (get_local 0))
            (get_local 2)
        )
    )
    (f32.store offset=20 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=20 align=2 (get_local 0))
            (get_local 2)
        )
    )
    (f32.store offset=24 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=24 align=2 (get_local 0))
            (get_local 2)
        )
    )
    (f32.store offset=28 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=28 align=2 (get_local 0))
            (get_local 2)
        )
    )

    (f32.store offset=32 align=4
        (get_local 0)
        (f32.mul
            (f32.load offset=32 align=4 (get_local 0))
            (get_local 3)
        )
    )
    (f32.store offset=36 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=36 align=2 (get_local 0))
            (get_local 3)
        )
    )
    (f32.store offset=40 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=40 align=2 (get_local 0))
            (get_local 3)
        )
    )
    (f32.store offset=44 align=2
        (get_local 0)
        (f32.mul
            (f32.load offset=44 align=2 (get_local 0))
            (get_local 3)
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

;; 31 - Stores a  3d vector inside reserved memory.
;; @param {i32} local 0 (signature) - Memory offset for resulting vector, multiple of 16.
;; @param {f32} local 1 (signature) - x coordinate.
;; @param {f32} local 2 (signature) - y coordinate.
;; @param {f32} local 3 (signature) - z coordinate.
;; @returns {i32} - Memory offset.
(func $storeVector (export "storeVector_u") (type $1i32_3f32resulti32)
    (f32.store offset=0 align=4 (get_local 0) (get_local 1))
    (f32.store offset=4 align=2 (get_local 0) (get_local 2))
    (f32.store offset=8 align=2 (get_local 0) (get_local 3))
    (f32.store offset=12 align=2 (get_local 0) (f32.const 0))
    get_local 0
)

;; 32 - Substracts 3d vectors from reserved memory.
;; @param {i32} local 0 (signature) - Memory offset for resulting vector, multiple of 16.
;; @param {i32} local 1 (signature) - Memory offset for first vector, multiple of 16.
;; @param {i32} local 2 (signature) - Memory offset for subtracted vector, multiple of 16.
;; @returns {i32} - Memory offset.
(func $subVectors (export "subVectors_u") (type $3i32resulti32)
        (f32.store offset=0 align=4
            (get_local 0)
            (f32.sub
                (f32.load offset=0 align=4 (get_local 1))
                (f32.load offset=0 align=4 (get_local 2))
            )
        )
        (f32.store offset=4 align=2
            (get_local 0)
            (f32.sub
                (f32.load offset=4 align=2 (get_local 1))
                (f32.load offset=4 align=2 (get_local 2))
            )
        )
        (f32.store offset=8 align=2
            (get_local 0)
            (f32.sub
                (f32.load offset=8 align=2 (get_local 1))
                (f32.load offset=8 align=2 (get_local 2))
            )
        )
        get_local 0
)

;; 33 - Computes cross products of 3d vectors from reserved memory.
;; @param {i32} local 0 (signature) - Memory offset for the resulting vector, multiple of 16.
;; @param {i32} local 1 (signature) - Memory offset for first vector, multiple of 16.
;; @param {i32} local 2 (signature) - Memory offset for subtracted vector, multiple of 16.
;; @returns {i32} - Memory offset for the resulting vector.
(func $crossVectors (export "crossVectors_u") (type $3i32resulti32)
        (f32.store offset=0 align=4     ;; x-component
            (get_local 0)
            (f32.sub
                (f32.mul
                    (f32.load offset=4 align=2 (get_local 1))
                    (f32.load offset=8 align=2 (get_local 2))
                )
                (f32.mul
                    (f32.load offset=8 align=2 (get_local 1))
                    (f32.load offset=4 align=2 (get_local 2))
                )
            )
        )
        (f32.store offset=4 align=2     ;; y-component
            (get_local 0)
            (f32.sub
                (f32.mul
                    (f32.load offset=8 align=2 (get_local 1))
                    (f32.load offset=0 align=4 (get_local 2))
                )
                (f32.mul
                    (f32.load offset=0 align=4 (get_local 1))
                    (f32.load offset=8 align=2 (get_local 2))
                )
            )
        )
        (f32.store offset=8 align=2     ;; z-component
            (get_local 0)
            (f32.sub
                (f32.mul
                    (f32.load offset=0 align=4 (get_local 1))
                    (f32.load offset=4 align=2 (get_local 2))
                )
                (f32.mul
                    (f32.load offset=4 align=2 (get_local 1))
                    (f32.load offset=0 align=4 (get_local 2))
                )
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
