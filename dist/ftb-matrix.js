function _loadWasmModule(A,g,I){var C=null;if("undefined"!=typeof process&&null!=process.versions&&null!=process.versions.node)C=Buffer.from(g,"base64");else{var B=globalThis.atob(g),E=B.length;C=new Uint8Array(new ArrayBuffer(E));for(var o=0;o<E;o++)C[o]=B.charCodeAt(o)}if(I&&!A)return WebAssembly.instantiate(C,I);if(I||A){var Q=new WebAssembly.Module(C);return I?new WebAssembly.Instance(Q,I):Q}return WebAssembly.compile(C)}!function(A,g){"object"==typeof exports&&"undefined"!=typeof module?module.exports=g():"function"==typeof define&&define.amd?define(g):(A=A||self).ftbMatrix=g()}(this,(function(){"use strict";function A(A){return _loadWasmModule(0,"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k5SSIAEqASwgASoBFCABKgEIlCABKgEEIAEqARiUk5SSlDgBDCAAIAIgASoBHCABKgIwIAEqASiUIAEqAiAgASoBOJSTlCABKgEsIAEqAhAgASoBOJQgASoCMCABKgEYlJOUkiABKgE8IAEqAiAgASoBGJQgASoCECABKgEolJOUkpQ4AhAgACACIAEqAQwgASoCICABKgE4lCABKgIwIAEqASiUk5QgASoBLCABKgIwIAEqAQiUIAEqAgAgASoBOJSTlJIgASoBPCABKgIAIAEqASiUIAEqAiAgASoBCJSTlJKUOAEUIAAgAiABKgEMIAEqAjAgASoBGJQgASoCECABKgE4lJOUIAEqARwgASoCACABKgE4lCABKgIwIAEqAQiUk5SSIAEqATwgASoCECABKgEIlCABKgIAIAEqARiUk5SSlDgBGCAAIAIgASoBDCABKgIQIAEqASiUIAEqAiAgASoBGJSTlCABKgEcIAEqAiAgASoBCJQgASoCACABKgEolJOUkiABKgEsIAEqAgAgASoBGJQgASoCECABKgEIlJOUkpQ4ARwgACACIAEqARwgASoCICABKgE0lCABKgIwIAEqASSUk5QgASoBLCABKgIwIAEqARSUIAEqAhAgASoBNJSTlJIgASoBPCABKgIQIAEqASSUIAEqAiAgASoBFJSTlJKUOAIgIAAgAiABKgEMIAEqAjAgASoBJJQgASoCICABKgE0lJOUIAEqASwgASoCACABKgE0lCABKgIwIAEqAQSUk5SSIAEqATwgASoCICABKgEElCABKgIAIAEqASSUk5SSlDgBJCAAIAIgASoBDCABKgIQIAEqATSUIAEqAjAgASoBFJSTlCABKgEcIAEqAjAgASoBBJQgASoCACABKgE0lJOUkiABKgE8IAEqAgAgASoBFJQgASoCECABKgEElJOUkpQ4ASggACACIAEqAQwgASoCICABKgEUlCABKgIQIAEqASSUk5QgASoBHCABKgIAIAEqASSUIAEqAiAgASoBBJSTlJIgASoBLCABKgIQIAEqAQSUIAEqAgAgASoBFJSTlJKUOAEsIAAgAiABKgEYIAEqAjAgASoBJJQgASoCICABKgE0lJOUIAEqASggASoCECABKgE0lCABKgIwIAEqARSUk5SSIAEqATggASoCICABKgEUlCABKgIQIAEqASSUk5SSlDgCMCAAIAIgASoBCCABKgIgIAEqATSUIAEqAjAgASoBJJSTlCABKgEoIAEqAjAgASoBBJQgASoCACABKgE0lJOUkiABKgE4IAEqAgAgASoBJJQgASoCICABKgEElJOUkpQ4ATQgACACIAEqAQggASoCMCABKgEUlCABKgIQIAEqATSUk5QgASoBGCABKgIAIAEqATSUIAEqAjAgASoBBJSTlJIgASoBOCABKgIQIAEqAQSUIAEqAgAgASoBFJSTlJKUOAE4IAAgAiABKgEIIAEqAhAgASoBJJQgASoCICABKgEUlJOUIAEqARggASoCICABKgEElCABKgIAIAEqASSUk5SSIAEqASggASoCACABKgEUlCABKgIQIAEqAQSUk5SSlDgBPAsFIAAQBRoLCx0BA30gABAEIgAQDEEQIABqEAyXQSAgAGoQDJeRCw==",A)}const g={autoFree:!1,simd:!1,autodetect:!1,maxMatrices:982,matrixStartingSlot:42};let I,C,B;const E=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],o={x:1,y:1,z:1},Q={_x:1,_y:1,_z:1,_w:1},S={x:1,y:1,z:1,isEuler:"XYZ"},i={XYZ:0,YXZ:1,ZXY:2,ZYX:3,YZX:4,XZY:5};function t(){return!0}function l(){return!1}return function(K=g){const U={...g,...K},{autoFree:q=!1,maxMatrices:s=982,matrixStartingSlot:e=42}=U,J=s+e,O=Math.ceil(64*(parseInt(s,10)+e)/65536),w=new WebAssembly.Memory({initial:O}),n=w.buffer;let D;const R={},f={};let r,k,h,y=e;async function M(){const g={"":{mem:w}};let K;if(U.autodetect||U.simd)try{({instance:{exports:K}}=await(O=g,_loadWasmModule(0,"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IAEqATiUk5SSIAEqATwgASoBBCABKgEYlCABKgEUIAEqAQiUk5SSlDgBCCAAIAIgASoBDCABKgEkIAEqARiUIAEqARQgASoBKJSTlCABKgEcIAEqAQQgASoBKJQgASoBJCABKgEIlJOUkiABKgEsIAEqARQgASoBCJQgASoBBCABKgEYlJOUkpQ4AQwgACACIAEqARwgASoCMCABKgEolCABKgIgIAEqATiUk5QgASoBLCABKgIQIAEqATiUIAEqAjAgASoBGJSTlJIgASoBPCABKgIgIAEqARiUIAEqAhAgASoBKJSTlJKUOAIQIAAgAiABKgEMIAEqAiAgASoBOJQgASoCMCABKgEolJOUIAEqASwgASoCMCABKgEIlCABKgIAIAEqATiUk5SSIAEqATwgASoCACABKgEolCABKgIgIAEqAQiUk5SSlDgBFCAAIAIgASoBDCABKgIwIAEqARiUIAEqAhAgASoBOJSTlCABKgEcIAEqAgAgASoBOJQgASoCMCABKgEIlJOUkiABKgE8IAEqAhAgASoBCJQgASoCACABKgEYlJOUkpQ4ARggACACIAEqAQwgASoCECABKgEolCABKgIgIAEqARiUk5QgASoBHCABKgIgIAEqAQiUIAEqAgAgASoBKJSTlJIgASoBLCABKgIAIAEqARiUIAEqAhAgASoBCJSTlJKUOAEcIAAgAiABKgEcIAEqAiAgASoBNJQgASoCMCABKgEklJOUIAEqASwgASoCMCABKgEUlCABKgIQIAEqATSUk5SSIAEqATwgASoCECABKgEklCABKgIgIAEqARSUk5SSlDgCICAAIAIgASoBDCABKgIwIAEqASSUIAEqAiAgASoBNJSTlCABKgEsIAEqAgAgASoBNJQgASoCMCABKgEElJOUkiABKgE8IAEqAiAgASoBBJQgASoCACABKgEklJOUkpQ4ASQgACACIAEqAQwgASoCECABKgE0lCABKgIwIAEqARSUk5QgASoBHCABKgIwIAEqAQSUIAEqAgAgASoBNJSTlJIgASoBPCABKgIAIAEqARSUIAEqAhAgASoBBJSTlJKUOAEoIAAgAiABKgEMIAEqAiAgASoBFJQgASoCECABKgEklJOUIAEqARwgASoCACABKgEklCABKgIgIAEqAQSUk5SSIAEqASwgASoCECABKgEElCABKgIAIAEqARSUk5SSlDgBLCAAIAIgASoBGCABKgIwIAEqASSUIAEqAiAgASoBNJSTlCABKgEoIAEqAhAgASoBNJQgASoCMCABKgEUlJOUkiABKgE4IAEqAiAgASoBFJQgASoCECABKgEklJOUkpQ4AjAgACACIAEqAQggASoCICABKgE0lCABKgIwIAEqASSUk5QgASoBKCABKgIwIAEqAQSUIAEqAgAgASoBNJSTlJIgASoBOCABKgIAIAEqASSUIAEqAiAgASoBBJSTlJKUOAE0IAAgAiABKgEIIAEqAjAgASoBFJQgASoCECABKgE0lJOUIAEqARggASoCACABKgE0lCABKgIwIAEqAQSUk5SSIAEqATggASoCECABKgEElCABKgIAIAEqARSUk5SSlDgBOCAAIAIgASoBCCABKgIQIAEqASSUIAEqAiAgASoBFJSTlCABKgEYIAEqAiAgASoBBJQgASoCACABKgEklJOUkiABKgEoIAEqAgAgASoBFJQgASoCECABKgEElJOUkpQ4ATwLBSAAEAQaCwsdAQN9IAAQAyIAEAtBECAAahALl0EgIABqEAuXkQs=",O))),console.info("ftb-matrix: successfully using SIMD for faster calculations.")}catch(I){U.autodetect?({instance:{exports:K}}=await A(g)):(console.error("ftb-matrix: does your platform really support SIMD ?"),console.error(I))}else({instance:{exports:K}}=await A(g));var O;const{identity_d:k,copy:h,copyPos:M,mul:c}=K,p=new Float32Array(n,0,16*e);for(let A=e;A<J;A++)f[A]=l,R[A]=new Float32Array(n,A<<6,16);function T(A,g,I,C,E,o,Q,S,i,l,K,U,O,w,n,h,M){D=q?e:y;for(let A=D;A<J;A++){if(!f[A]()){y=A;break}if(A===s)throw Error("ftb-matrix: Not enough allocated memory: please use the 'maxMatrices' option.")}q&&r.set(this,null),this.slot=y,this.dimension=4,f[y]=t,B=typeof A,"function"===B?A(y,g,I,C,E,o,Q,S,i,l,K,U,O,w,n,h,M):"object"===B&&"number"==typeof A.slot?this.copy(A,this):"number"===B?this.init(A,g,I,C,E,o,Q,S,i,l,K,U,O,w,n,h):k(y),this[Symbol.toPrimitive]=function(A){return"string"===A?R[this.slot].toString():"number"!==A?"Matrix slot number: "+this.slot:void this.determinant()}}T.prototype.free=function(){f[this.slot]=l,q||(y=this.slot)},T.prototype.multiply=function(A){return h(this.slot,0),c(0,A.slot,this.slot),this},T.prototype.premultiply=function(A){return h(this.slot,0),c(A.slot,0,this.slot),this},T.prototype.multiplyMatrices=function(A,g){return c(A.slot,g.slot,this.slot),this};for(let A of Object.keys(K)){const g=A.split("_"),I=g[0];if(g.length>1){const C=g[g.length-1];"d"===C?(T.prototype[I]=function(g,I,C,B,E,o,Q,S,i,t,l,U,q,s,e,J,O){const w=K[A].call(this,this.slot,g,I,C,B,E,o,Q,S,i,t,l,U,q,s,e,J,O);return void 0===w?this:w},T[I]=function(g,I,C,B,E,o,Q,S,i,t,l,U,q,s,e,J,O){return new T(K[A],g,I,C,B,E,o,Q,S,i,t,l,U,q,s,e,J,O)}):"u"===C&&(T.prototype[I]=K[A],T[I]=T.prototype[I])}}return T.prototype.copyPosition=function(A){return M(A.slot,this.slot),this},T.prototype.fromArray=function(A=E,g=0){for(let I=0;I<16;I++)R[this.slot]=A[I+g];return this},T.fromArray=function(A=E,g=0){I=new T;for(let C=0;C<16;C++)R[I.slot]=A[C+g];return I},T.prototype.set=function(A,g,I,C,B,E,o,Q,S,i,t,l,K,U,q,s){Object.assign(R[this.slot],[A,B,S,K,g,E,i,U,I,o,t,q,C,Q,l,s])},T.prototype.init=function(A,g,I,C,B,E,o,Q,S,i,t,l,K,U,q,s){return"number"==typeof s?Object.assign(R[this.slot],[A,g,I,C,B,E,o,Q,S,i,t,l,K,U,q,s]):"undefine"==typeof B?(this.dimension=2,Object.assign(R[this.slot],[A,g,0,0,I,C,0,0,0,0,0,0,0,0,0,0])):"undefine"==typeof i&&(this.dimension=3,Object.assign(R[this.slot],[A,g,I,0,C,B,E,0,o,Q,S,0,0,0,0,0])),this},T.prototype.clone=function(A){return h(A.slot,this.slot),this},T.prototype.compose=function(A=o,g=Q,I=o){return K.compose(this.slot,A.x,A.y,A.z,g._x,g._y,g._z,g._w,I.x,I.y,I.z),this},T.prototype.equals=function(A){return!!K.equals(this,A)},T.prototype.decompose=function(A=o,g=Q,C=o){I=this.slot<<6,C.x=K.norm_u(I),C.y=K.norm_u(I+16),C.z=K.norm_u(I+32),this.determinant()<0&&(C.x=-C.x),I=R[this.slot],A.x=I[12],A.y=I[13],A.z=I[14];const B=new T(this),E=1/C.x,S=1/C.y,i=1/C.z;if(I=R[B.slot],I[0]*=E,I[1]*=E,I[2]*=E,I[4]*=S,I[5]*=S,I[6]*=S,I[8]*=i,I[9]*=i,I[10]*=i,I[0]+I[5]+I[10]>0){const A=.5/Math.sqrt(1+I[0]+I[5]+I[10]);g._x=A*(I[6]-I[9]),g._y=A*(I[8]-I[2]),g._z=A*(I[1]-I[4]),g._w=.25/A}else if(I[0]>I[5]&&I[0]>I[10]){const A=.5/Math.sqrt(1+I[0]-I[5]-I[10]);g._x=.25/A,g._y=A*(I[4]+I[1]),g._z=A*(I[8]+I[2]),g._w=A*(I[6]-I[9])}else if(I[5]>I[10]){const A=.5/Math.sqrt(1+I[5]-I[0]-I[10]);g._x=A*(I[4]+I[1]),g._y=.25/A,g._z=A*(I[9]+I[6]),g._w=A*(I[8]-I[2])}else{const A=.5/Math.sqrt(1+I[10]-I[0]-I[5]);g._x=A*(I[1]-I[4]),g._y=A*(I[9]+I[6]),g._z=.25/A,g._w=A*(I[1]-I[4])}return B.free(),this},T.prototype.copy=function(A,g){return h(A.slot,g?g.slot:this.slot),this},T.prototype.extractBasis=function(A=o,g=o,C=o){return I=R[this.slot],A.x=I[0],A.y=I[1],A.z=I[2],g.x=I[4],g.y=I[5],g.z=I[6],C.x=I[8],C.y=I[9],C.z=I[10],this},T.prototype.extractRotation=function(A){return K.extractRotation(this.slot,A.slot),this},T.prototype.makeRotationFromQuaternion=function(A=Q){return K.compose(this.slot,0,0,0,A._x,A._y,A._z,A._w,1,1,1),this},T.prototype.makeRotationFromEuler=function(A=S){return I=i[A.isEuler||"XYZ"],K.makeRotationFromEuler(this.slot,A.x,A.y,A.z,I),this},T.prototype.getInverse=function(A){return K.getInverse(this.slot,A.slot),this},T.prototype.equals=function(A){return!!K.equals(this.slot,A.slot)},Object.defineProperty(T.prototype,"elements",{get(){return 4===this.dimension?R[this.slot]:3===this.dimension?(I=R[this.slot],[I[0],I[1],I[2],I[4],I[5],I[6],I[8],I[9],I[10]]):2===this.dimension?(I=R[this.slot],[I[0],I[1],I[4],I[5]]):void 0}}),T.prototype.fromArray=function(A=[],g=0){if(I=R[this.slot],4===this.dimension){C=16;for(let C=0;C<16;C++)I[C]=A[g+C]}return this},T.prototype.toArray=function(A=[],g=0){I=R[this.slot],C=4===this.dimension?16:3===this.dimension?9:4;for(let B=0;B<C;B++)A[g+B]=I[B];return A},T.reservedMemory=p,T}return q&&(r=new WeakMap,h=WeakMap.prototype.has.bind(r),k=function(A,g=t){r.set(A),f[A.slot]=g}),q?{matFactory:M,g:k,h:h}:{matFactory:M}}}));