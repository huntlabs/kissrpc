module rpcgenerate.Greeter.WeaponFb;
// automatically generated by the FlatBuffers compiler, do not modifymodule rpcgenerate.Greeter.WeaponFb;

import std.typecons;
import flatbuffers;

struct WeaponFb {
	mixin Table!WeaponFb;

  static WeaponFb getRootAsWeaponFb(ByteBuffer _bb) {  return WeaponFb.init_(_bb.get!int(_bb.position()) + _bb.position(), _bb); }
	@property Nullable!string name() { uint o = __offset(4); return o != 0 ? Nullable!string(__string(o + _pos)) : Nullable!string.init; }
	auto damage() { return Iterator!(WeaponFb, short, "damage")(this); }
	short damage(uint j) { uint o = __offset(6); return o != 0 ? _buffer.get!short(__dvector(o) + j * 2)  : 0; }
	@property uint damageLength() { uint o = __offset(6); return o != 0 ? __vector_len(o) : 0; }

	static uint createWeaponFb(FlatBufferBuilder builder,uint name,uint damage) {
		builder.startObject(2);
		WeaponFb.addDamage(builder, damage);
		WeaponFb.addName(builder, name);
		return WeaponFb.endWeaponFb(builder);
	}

	static void startWeaponFb(FlatBufferBuilder builder) { builder.startObject(2); }
	static void addName(FlatBufferBuilder builder, uint nameOffset) { builder.addOffset(0, nameOffset, 0); }
	static void addDamage(FlatBufferBuilder builder, uint damageOffset) { builder.addOffset(1, damageOffset, 0); }
	static uint createDamageVector(FlatBufferBuilder builder, short[] data) { builder.startVector(2, cast(uint)data.length, 2); for (size_t i = data.length; i > 0; i--) builder.add!short(data[i - 1]); return builder.endVector(); }
	static void startDamageVector(FlatBufferBuilder builder, uint numElems) { builder.startVector(2, numElems, 2); }
	static uint endWeaponFb(FlatBufferBuilder builder) {
		uint o = builder.endObject();
		return o;
	}
}
