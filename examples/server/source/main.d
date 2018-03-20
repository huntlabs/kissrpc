


import kissrpc;

import rpcgenerate.Greeter;


import std.string;


final class GreeterService : Greeter {
    mixin MakeRpc;
public:
    this() {
        
        Weapon wp1;
        wp1.name = "sword";
        wp1.damage = [100, 150, 200];

        Weapon wp2;
        wp2.name = "knife";
        wp1.damage = [100, 200];

        Monster monster1;
        monster1.id = 1;
        monster1.pos.x = 100;
        monster1.pos.y = 100;
        monster1.pos.z = 100;
        monster1.weapons = [wp1];
        
        Monster monster2;
        monster2.id = 1;
        monster2.pos.x = 200;
        monster2.pos.y = 200;
        monster2.pos.z = 200;
        monster1.weapons = [wp1,wp2];

        _monsters = [monster1, monster2];
    }
    override Monster updateAndGetMonster(Monster monster) {
        foreach(ref value; _monsters) {
            if (value.id == monster.id) {
                log("updateAndGetMonster old monster ", value);
                value.pos = monster.pos;
                value.weapons = monster.weapons[0..$];
                log("updateAndGetMonster new monster ", value);
                break;
            }
        }
        return monster;
    }
	override Monster getFirstMonster() {
        log("getFirstMonster ", _monsters[0]);
        log("getRpcExData = ", getRpcExData());
        return _monsters[0];
    }
	override void updateMonster(Monster monster) {
        foreach(ref value; _monsters) {
            if (value.id == monster.id) {
                log("updateMonster old monster ", value);
                value.pos = monster.pos;
                value.weapons = monster.weapons[0..$];
                log("updateMonster new monster ", value);
                break;
            }
        }
    }
	override void removeAllMonster() {
        _monsters = _monsters.init;
        log("removeAllMonster ", _monsters);
    }
private:
    Monster[] _monsters;
}

void main() {
    RpcServer server = RpcManager.getInstance().createRpcServer("0.0.0.0", 9009, (RpcStream stream, RpcEvent code, string msg){
        log("~~~~~~~~~server event code = %s, msg = %s".format(code,msg));
    });
}

