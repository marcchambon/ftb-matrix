# ftb-matrix
* **fast** & **small** (WebAssembly) single-precision matrix4x4 library
* **ThreeJs**-like interface
* targets both **modern browsers** and **NodeJs** (UMD module)

## Installation
#### CDN
Insert the following script before the closing body tag of your index.html file and before the other scripts :
`<script src="https://cdn.jsdelivr.net/npm/ftb-matrix@0.0.8/dist/ftb-matrix.js"></script>`

#### Via package managers
1. With `npm` :

    ```sh
    $ npm install --save ftb-matrix
    ```

2. With `yarn` :

    ```sh
    $ yarn add ftb-matrix
    ```
## Use
0. Without CDN only :

    ```js
    import ftbMatrix from 'ftb-matrix';
    ```

1. Getting the matrix constructor :

    ```js
    const { Mat } = await ftbMatrix();
    ```

## Examples
__IMPORTANT__: these matrices use the column-major convention.
1. 101 : Getting an identity matrix
```js
const mat = new Mat();
// getting the elements as a Float32Array
const arr = mat.elements;
// freeing the memory allocated in the WebAssembly memory object.
mat.free();
```
2. Enabling garbage collection awareness
```js
const { Mat, g } = await ftbMatrix({ autoFree });
const mat = new Mat();g(_=>mat);
// no need to do: mat.free();
```
Note: tedious but could be automated with framework like Svelte
(inserting g(_=>varialbe) at compile time?).

3. [Enabling vector processing (SIMD) for even more speed (Chrome/Chromium only)](https://v8.dev/features/simd#enabling-experimental-simd-support-in-chrome)

```js
const { Mat } = await ftbMatrix({ simd: true });
```
Note: you can use { autodetect: true } instead of { simd: true },
for automatic fallback to standard code. 

4. [More functions - see the ThreeJs documentation](https://threejs.org/docs/#api/en/math/Matrix4)

## Contributing
Feedbacks are welcome (email or PM, see my Twitter account):
* Improving garbage collection awareness
(is it possible to do it automatically? not sure because of closures...), by using WeakRef
instead of WeakMap?
