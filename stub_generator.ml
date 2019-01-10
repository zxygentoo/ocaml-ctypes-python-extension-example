let generate dirname =
  let prefix = "pymod" in
  let path basename = Filename.concat dirname basename in
  let ml_fd = open_out (path "bindings_gen.ml") in
  let c_fd = open_out (path "bindings_gen_c.c") in
  let h_fd = open_out (path "bindings_gen_c.h") in
  let stubs = (module Bindings.Stubs : Cstubs_inverted.BINDINGS) in
  begin
    (* Generate the ML module that links in the generated C. *)
    Format.fprintf (Format.formatter_of_out_channel ml_fd)
      "%a"
      (Cstubs_inverted.write_ml ~prefix) stubs;

    (* Generate the C source file that exports OCaml functions. *)
    Format.fprintf (Format.formatter_of_out_channel c_fd)
      "#include <Python.h>\n#include \"bindings_gen_c.h\"\n%a
/* symbol for Python to use */
PyMODINIT_FUNC PyInit_pymod(void) {
  /* initialise OCaml runtime if necesarry */
  static int inited = 0;
  char *caml_argv[1] = { NULL };
  if (inited == 0) {
    caml_startup(caml_argv);
  }
  /* Python module init function */
  return (PyMODINIT_FUNC) pymod();
}
"
      (Cstubs_inverted.write_c ~prefix) stubs;

    (* Generate the C header file that exports OCaml functions. *)
    Format.fprintf (Format.formatter_of_out_channel h_fd)
      "%a"
      (Cstubs_inverted.write_c_header ~prefix) stubs;
  end;
  close_out h_fd;
  close_out c_fd;
  close_out ml_fd

let () = generate (Sys.argv.(1))
