-module(queuemanager).
-author("Milena Dreier, Dino Buskulic").
-export([start/0]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0]).

start() ->
    HoldBackQueu = orddict:new(),
    DeliveryQueue = orddict:new(),
    
    loop()
.

    
    
    