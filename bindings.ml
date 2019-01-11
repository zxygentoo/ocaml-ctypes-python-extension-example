open Ctypes
open PosixTypes
open Foreign


type pyobject
type pymethoddef
type pymoduledef_base
type pymoduledef


(* structs and function ctypes we need *)

let pyobject : pyobject structure typ = structure "PyObject"

let pycfunction = ptr pyobject @-> ptr pyobject @-> returning (ptr pyobject)
let inquiryfunc_t = ptr pyobject @-> returning int
let free_func_t = ptr void @-> returning (ptr void)
let visitproc_t = ptr pyobject @-> ptr void @-> returning int
let traverseproc_t =
  ptr pyobject @-> funptr visitproc_t @-> ptr void @-> returning int                     

let pyobject : pyobject structure typ = pyobject
let (-:) f ty = field pyobject f ty
let ob_refcnt = "ob_refcnt" -: ssize_t
(* Binding the actual PyTypeObject will bring a lot more stuffs to deal with,
   as the primary goal of this example is to show the basic steps to build 
   a python extension module using ocaml, not to build a comprehensive
   ocaml python ffi layer, and we won't be using type objects,
   so we just bind it to a null pointer here. *)
let ob_type = "ob_type" -: ptr void
let () = seal pyobject

let pymethoddef : pymethoddef structure typ = structure "PyMethodDef"
let (-:) f ty = field pymethoddef f ty 
let ml_name = "ml_name" -: string
(* see below for why `ml_meth` is a static_funptr instead of funptr *)
let ml_meth = "ml_meth" -: Ctypes_static.static_funptr pycfunction
let ml_flags = "ml_flags" -: int
let ml_doc = "ml_doc" -: string
let () = seal pymethoddef

let pymoduledef_base : 
  pymoduledef_base structure typ = structure "PyModuleDef_Base"
let (-:) f ty = field pymoduledef_base f ty
let ob_base = "ob_base" -: pyobject
let m_init = "m_init" -: funptr_opt (ptr pyobject @-> returning void)
let m_index = "m_index" -: ssize_t
let m_copy = "m_copy" -: ptr pyobject
let () = seal pymoduledef_base

let pymoduledef : pymoduledef structure typ = structure "PyModuleDef"
let (-:) f ty = field pymoduledef f ty
let m_base = "m_base" -: pymoduledef_base
let m_name = "m_name" -: string
let m_doc = "m_doc" -: string
let m_size = "m_size" -: ssize_t
let m_methods = "m_methods" -: ptr pymethoddef
let m_traverse = "m_traverse" -: funptr_opt traverseproc_t
let m_clear = "m_clear" -: funptr_opt inquiryfunc_t
let m_free = "m_free" -: funptr_opt free_func_t
let () = seal pymoduledef


(* some Python C-API bindings we need *)

let pylong_fromlong_t = int @-> returning (ptr pyobject)
let pylong_fromlong =
  foreign "PyLong_FromLong" ~check_errno:true pylong_fromlong_t

let pylong_aslong_t = ptr pyobject @-> returning int
let pylong_aslong = foreign "PyLong_AsLong" ~check_errno:true pylong_aslong_t

let pytuple_getitem_t = ptr pyobject @-> ssize_t @-> returning (ptr pyobject)
let pytuple_getitem =
  foreign "PyTuple_GetItem" ~check_errno:true pytuple_getitem_t

(* Python doc suggests using PyModule_Create for most cases, but it's a macro,
   here we use the function form PyModule_Create2 for simple sake. *)
let pymodule_create2_t = ptr pymoduledef @-> int @-> returning (ptr pyobject)
let pymodule_create2 =
  foreign "PyModule_Create2" ~check_errno:true pymodule_create2_t


(* helpers *)

let pyobject_head_init =
  let ob = make pyobject in
  setf ob ob_refcnt (Ssize.of_int 1);
  setf ob ob_type null;
  ob

let pymoduledef_head_init =
  let m = make pymoduledef_base in
  setf m ob_base pyobject_head_init;
  setf m m_init None;
  setf m m_index (Ssize.of_int 0);
  setf m m_copy (from_voidp pyobject null);
  m

let make_method name doc f =
  let ml = make pymethoddef in
  setf ml ml_name name;
  setf ml ml_meth f;
  setf ml ml_flags 1;
  setf ml ml_doc doc;
  ml

let make_module name doc methods =
  let m = make pymoduledef in
  setf m m_base pymoduledef_head_init;
  setf m m_name name;
  setf m m_doc doc;
  setf m m_size (Ssize.of_int (-1));
  setf m m_methods (CArray.start (CArray.of_list pymethoddef methods));
  setf m m_traverse None;
  setf m m_clear None;
  setf m m_free None;
  m

let python_api_version = 1013
let mod_init_t = (void @-> returning (ptr pyobject))

let make_module_init mod_ptr =
  fun _ ->
  if is_null mod_ptr then failwith "pymod initialize failed"
  else pymodule_create2 mod_ptr python_api_version

(* NOTE

   The current desgin of ocaml-ctypes works very well when binding and calling
   c code, but not as well the other way around.
   Specially for things like structs with string/function pointers, 
   as structs don't have clear deallocation equivalent like functions, 
   it's possible running into automatic memory management issues.

   The current recommendation from ctypes author is resolving to low-level api 
   like `Ctypes_static.static_funptr` and  `ptr char` 
   which doesn't do auto memory management. There are future plans to change 
   the design of ctypes to make these kind of things easier.

   That's why `ml_meth` is a static_funptr` instead of just a `funptr`, 
   you can play with it to see if it causing problems :P

   Here we add some helpers for those conversions.   
*)

let char_ptr_of_string s =
  CArray.start (CArray.of_string s)

let static_funptr_of_funptr ty fp =
  coerce
    (funptr ty)
    (Ctypes_static.static_funptr ty)
    fp

let static_funptr_of_funptr_pycfunction =
  static_funptr_of_funptr pycfunction


(* a test module `pymod` with two methods *)

let anser_meth _ _  = pylong_fromlong 42

let answer =
  make_method
    "answer"
    "answer to everything"
    (static_funptr_of_funptr_pycfunction anser_meth)

let double_int_meth _ args =
  pylong_fromlong (2 * (pylong_aslong (pytuple_getitem args (Ssize.of_int 0))))

let double_int =
  make_method
    "double_int"
    "accept an int and return the double of it"
    (static_funptr_of_funptr_pycfunction double_int_meth)

let pymod_ptr =
  allocate pymoduledef
    (make_module
       "pymod"
       "pymod doc"
       [
         answer;
         double_int
       ]
    )

module Stubs (I : Cstubs_inverted.INTERNAL) = struct
  let () = I.internal "pymod" mod_init_t (make_module_init pymod_ptr)
end
