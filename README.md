Example showing how to write a Python extension module using [ocaml-ctypes](https://github.com/ocamllabs/ocaml-ctypes/tree/master/src/ctypes), based on [ocaml-ctypes-inverted-stubs-example](https://github.com/yallop/ocaml-ctypes-inverted-stubs-example).

### Install OCaml dependencies

```shell
opam install ctypes-foreign ctypes
```

and a working python3 installation, eg. on ubuntu, it will be something like:

```shell
apt-get install python-dev
```

### Build the example extension (pymod.so)

```shell
make
```

### Run Python tests on example extension

```shell
python3 tests.py
```

- tested on python-3.6.5 but should work on recent python3 releases.
