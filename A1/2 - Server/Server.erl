-module(server).
-author("Milena Dreier, Dino Buskulic").
-export([start/0]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0]).

start() ->
%Speichern der Configparameter
    {ok, Configlist} = file:consult("server.cfg"),
    {ok, Servername} = get_config_value(servername,Configlist),
    {ok, Lifetime} = get_config_value(lifetime,Configlist),
    {ok, DlqLimit} = get_config_value(dlqlimit,Configlist),
    {ok, Clientlifetime} = get_config_value(clientlifetime,Configlist),
%Configugration fertig

%Serverkomponenten initialisieren
    %QeuemanagerPID = spawn(fun() -> queuemanager:start() end).
    ClientmanagerPID = spawn(clientmanager:start(Clientlifetime,self(),self())),
    ServerPID = spawn(fun() -> loop(ClientmanagerPID,0) end),
    
    register(Servername,self()),
    ServerPID
.


loop(CManager,MessageNumber) ->
    receive
        {getmsgid, ClientPID} -> 
            logging("server.log",io:format("~p : Server: Received getmsgid:~p ! ~p\n" ,[now(),ClientPID])),
            ClientPID ! {nnr,MessageNumber},
            loop(CManager,MessageNumber + 1);

        {getmessages,ClientPID} ->
            logging("server.log",io:format("~p : Server: Received getmessages:~p ! ~p\n" ,[now(),ClientPID])),
            CManager ! {getmessages, ClientPID},
            receive
                {Message,MsgId,Terminated} ->
                    ClientPID ! {reply,MsgId,Message,Terminated}
            end,
            
            loop(CManager,MessageNumber); %Wieder in den Loop springen
        
        {dropmessage, {Nachricht, Nr}} -> 
            logging("server.log",io:format("~p : Server: Received dropmessages:~p ! ~p\n" ,[now(),Nachricht]))
            
    end
.
    
currentTimeInSec() ->
    {MegaSecs,Secs,MicroSecs} = now(),
    ((MegaSecs*1000000 + Secs)*1000000 + MicroSecs) / 1000000
.
    