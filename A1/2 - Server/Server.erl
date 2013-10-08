-module(server).
-author("Milena Dreier, Dino Buskulic").
-export([start/0]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0]).

%% -------------------------------------------
% Server
%% -------------------------------------------
%%
%% -------------------------------------------
%% startet den Server
%% liest die Config-Datei aus und startet die Prozesse Queuemanager und Clientmanager
%
start() ->
%Speichern der Configparameter
    {ok, Configlist} = file:consult("server.cfg"),
    {ok, Servername} = get_config_value(servername,Configlist),
    %{ok, Lifetime} = get_config_value(lifetime,Configlist),
    {ok, DlqLimit} = get_config_value(dlqlimit,Configlist),
    {ok, Clientlifetime} = get_config_value(clientlifetime,Configlist),
%Configuration fertig

%Serverkomponenten initialisieren
    QueuemanagerPID = spawn_link(fun() -> queuemanager:start(DlqLimit) end),
    ClientmanagerPID = spawn_link(fun() -> clientmanager:start(Clientlifetime,QueuemanagerPID,self()) end),
    %ServerPID = spawn(fun() -> loop(ClientmanagerPID,QueuemanagerPID,0) end),

    
    logging("server.log",io:format("...Queuemanager started with PID ~p...\n", [QueuemanagerPID])),
    logging("server.log",io:format("...Clientmanager started with PID ~p...\n", [ClientmanagerPID])),
    
    register(Servername,ServerPID),
    logging("server.log",io:format("...Server started and registered with Servername ~p and PID ~p...\n", [Servername, ServerPID])),
    
    loop(ClientmanagerPID,QueuemanagerPID,0, Lifetime),
    
    self()
.


%% -------------------------------------------
%% loop-Funktion behandelt eingehende Nachrichten und wird immer wieder aufgerufen
loop(CManager,QManager,MessageNumber, Lifetime) ->
    receive
        {getmsgid, ClientPID} -> 
            logging("server.log",io:format("~p : Server: Received getmsgid: ~p ! ~p\n" ,[timeMilliSecond(),ClientPID,MessageNumber])),
            ClientPID ! {nnr,MessageNumber},
            loop(CManager,QManager,MessageNumber + 1);

        {getmessages,ClientPID} ->
            logging("server.log",io:format("~p : Server: Received getmessages:~p\n" ,[timeMilliSecond(),ClientPID])),
            CManager ! {getmessages, ClientPID,self()},
            receive
                {Message,MsgId,Terminated} ->
                    io:fwrite("Server hat Message vom ClientManager bekommen: ~p\n",[MsgId]),
                    ClientPID ! {reply,MsgId,Message,Terminated}
            end,
            
            loop(CManager,QManager,MessageNumber);
        
        {dropmessage, {Nachricht, Nr}} -> 
            logging("server.log",io:format("~p : Server: Received dropmessages:~p\n" ,[timeMilliSecond(),Nachricht])),
            QManager ! {dropmessage, {Nachricht, Nr}},
        
            loop(CManager,QManager,MessageNumber);
    after 
    	Lifetime ->
    		logging("server.log",io:format("Lifetime ~p is over. Server ~p terminates" ,[Lifetime,self()]))
    		exit("Lifetime is over")
    end
.
    
%terminate(normal,state) -> ok.