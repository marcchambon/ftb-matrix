# ftb-matrix
* **fast** & **small** (WebAssembly) single-precision matrix4x4 library
* **ThreeJs**-like interface
* targets both **modern browsers** and **NodeJs** (UMD module)

## Installation
#### CDN
Insert the following script before the closing body tag of your index.html file and before the other scripts :
`<script src="https://cdn.jsdelivr.net/npm/ftb-matrix@0.0.5/dist/ftb-matrix.js"></script>`

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
    const { matFactory } = ftbMatrix();
    const Mat = await matFactory();
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

2. [More functions - see the ThreeJs documentation](https://threejs.org/docs/#api/en/math/Matrix4)