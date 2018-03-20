// automatically generated, do not modify
module rpcgenerate.Greeter.GreeterBase;

class Greeter {
	abstract Monster updateAndGetMonster(Monster monster);
	abstract Monster getFirstMonster();
	abstract void updateMonster(Monster monster);
	abstract void removeAllMonster();
}

struct Pos {
	float x;
	float y;
	float z;
}

struct Weapon {
	string name;
	short[] damage;
}

struct Monster {
	ulong id = 1;
	Pos pos;
	Weapon[] weapons;
}

