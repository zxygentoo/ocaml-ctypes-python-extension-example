Example showing how to write a Python extension module using [ocaml-ctypes](https://github.com/ocamllabs/ocaml-ctypes/tree/master/src/ctypes) based on [ocaml-ctypes-inverted-stubs-example](https://github.com/yallop/ocaml-ctypes-inverted-stubs-example)

### Install dependencies

```shell
opam install ctypes-foreign ctypes
```

### Build the example

```shell
make
```

### Running Python tests on the example extension

```shell
python3 tests.py
```

- tested on python-3.6.5 but should work on recent python3 releases.
