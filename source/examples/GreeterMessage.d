

module example.GreeterMessage;

struct GreeterRequest {
    string msg;
}

struct GreeterResponse {
    string msg;
}

interface Greeter {
    GreeterResponse SayHello(GreeterRequest message);
}
