

module rpcgenerate.GreeterInterface;

import rpcgenerate.GreeterRequest;
import rpcgenerate.GreeterResponse;

interface Greeter {
    GreeterResponse SayHello(GreeterRequest message);
    GreeterResponse getSayHello();
}
