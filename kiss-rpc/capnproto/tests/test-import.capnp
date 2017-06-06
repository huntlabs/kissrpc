@0xd693321951fee8f3;

using Dlang = import "/capnp/dlang.capnp";
$Dlang.module("capnproto.tests.testimport");

using import "test.capnp".TestAllTypes;

struct Foo {
	importedStruct @0 :TestAllTypes;
}
