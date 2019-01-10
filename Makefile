GENDIR = _build
OCAMLDIR=$(shell ocamlfind opt -where)
PYINCLUDES=$(shell python3-config --includes)
PYLIB=$(shell python3-config --libs | cut -d ' ' -f 1)
PACKAGES=ctypes,ctypes.foreign,ctypes.stubs

all :
	mkdir -p $(GENDIR)
	make pymod.so

pymod.so : bindings.cmx bindings_gen.cmx bindings_gen_c.o apply_bindings.cmx
	ocamlfind opt -o $@ -linkpkg -output-obj -runtime-variant _pic -package $(PACKAGES) $^

bindings_gen.cmx : generated
	ocamlfind opt -c -o $@ -package $(PACKAGES) $(GENDIR)/bindings_gen.ml

bindings_gen_c.o : generated
	$(CC) -c -o $@ -Wall -fPIC -I$(PYINCLUDES) -I$(OCAMLDIR) -I$(OCAMLDIR)/../ctypes $(GENDIR)/bindings_gen_c.c

generated : $(GENDIR)/generator
	./$(GENDIR)/generator $(GENDIR)

$(GENDIR)/generator : bindings.cmx stub_generator.cmx
	ocamlfind opt -o $@ -linkpkg -package $(PACKAGES) -cclib $(PYLIB) $^

%.cmx: %.ml
	ocamlfind opt -c -o $@ -package $(PACKAGES) $<

clean :
	rm -rf *.so $(GENDIR) *.a *.o *.cmi *cmx *.pyc __pycache__
