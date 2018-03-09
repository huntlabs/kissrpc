

module rpcgenerate.greeter.Greeter;

class Greeter {
    abstract GreeterResponse SayHello(GreeterRequest message);
    abstract GreeterResponse getSayHello();
}


struct GreeterRequest {
    string msg;
}


struct GreeterResponse {
    string msg;
}


