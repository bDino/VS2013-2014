-module(server).
-author("Milena Dreier, Dino Buskulic").
-export([start/0]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0]).

start() ->
%Speichern der Configparameter
    {ok, Configlist} = file:consult("server.cfg"),
    {ok, Servername} = get_config_value(servername,Configlist),
    %{ok, Lifetime} = get_config_value(lifetime,Configlist),
    {ok, DlqLimit} = get_config_value(dlqlimit,Configlist),
    {ok, Clientlifetime} = get_config_value(clientlifetime,Configlist),
%Configugration fertig

%Serverkomponenten initialisieren
    QueuemanagerPID = spawn(fun() -> queuemanager:start(DlqLimit) end),
    ClientmanagerPID = spawn(fun() -> clientmanager:start(Clientlifetime,QueuemanagerPID,self()) end),
    ServerPID = spawn(fun() -> loop(ClientmanagerPID,QueuemanagerPID,0) end),

    
    logging("server.log","...Queuemanager started..."),
    logging("server.log","...Clientmanager started..."),
    
    register(Servername,ServerPID),
    
    logging("server.log","...Server started and registered..."),
    
    ServerPID
.


loop(CManager,QManager,MessageNumber) ->
    receive
        {getmsgid, ClientPID} -> 
            logging("server.log",io:format("~p : Server: Received getmsgid: ~p ! ~p\n" ,[timeMilliSecond(),ClientPID,MessageNumber])),
            ClientPID ! {nnr,MessageNumber},
            loop(CManager,QManager,MessageNumber + 1);

        {getmessages,ClientPID} ->
            logging("server.log",io:format("~p : Server: Received getmessages:~p\n" ,[timeMilliSecond(),ClientPID])),
            CManager ! {getmessages, ClientPID},
            receive
                {Message,MsgId,Terminated} ->
                    ClientPID ! {reply,MsgId,Message,Terminated}
            end,
            
            loop(CManager,QManager,MessageNumber);
        
        {dropmessage, {Nachricht, Nr}} -> 
            logging("server.log",io:format("~p : Server: Received dropmessages:~p\n" ,[timeMilliSecond(),Nachricht])),
            QManager ! {dropmessage, {Nachricht, Nr}},
        
            loop(CManager,QManager,MessageNumber)
    end
.
    
%terminate(normal,state) -> ok.