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
    {ok, Lifetime} = get_config_value(lifetime,Configlist),
    {ok, DlqLimit} = get_config_value(dlqlimit,Configlist),
    {ok, Clientlifetime} = get_config_value(clientlifetime,Configlist),
%Configuration fertig

%Serverkomponenten initialisieren
    QueuemanagerPID = spawn_link(fun() -> queuemanager:start(DlqLimit) end),
    ClientmanagerPID = spawn_link(fun() -> clientmanager:start(Clientlifetime,QueuemanagerPID) end),
    ServerPID = spawn(fun() -> loop(ClientmanagerPID,QueuemanagerPID,0) end),
	%ServerPID = self(),
    
    logging("server.log","...Queuemanager started ... \n"),
    logging('server.log',"...Clientmanager started ...\n"),
    
    register(Servername,ServerPID),
    logging("server.log","...Server started and registered with Servername ...\n"),
    
    %loop(ClientmanagerPID,QueuemanagerPID,0)
    ServerPID
.


%% -------------------------------------------
%% loop-Funktion behandelt eingehende Nachrichten und wird immer wieder aufgerufen
loop(CManager,QManager,MessageNumber) ->
    receive
        {getmsgid, ClientPID} -> 
            logging("server.log","Server: Received getmsgid\n"),
            ClientPID ! {nnr,MessageNumber},
            NewMsgNr = MessageNumber+1,
            loop(CManager, QManager, NewMsgNr);

        {getmessages,ClientPID} ->
        	logging("server.log","Server: Received getmessages\n"),
            logging("server.log",io:format("~p : Server: Received getmessages:~p\n" ,[timeMilliSecond(),ClientPID])),
            CManager ! {getmessages, ClientPID, self()},
            receive
                {Message,MsgId,Terminated} ->
                    io:fwrite("Server hat Message vom ClientManager bekommen: ~p\n",[MsgId]),
                    ClientPID ! {reply,MsgId,Message,Terminated}
            end,
            
            loop(CManager, QManager, MessageNumber);
        
        {dropmessage, {Nachricht, Nr}} -> 
            logging("server.log",io:format("~p : Server: Received dropmessages:~p\n" ,[timeMilliSecond(),Nachricht])),
            QManager ! {dropmessage, {Nachricht, Nr}},
        
            loop(CManager, QManager, MessageNumber)
%%    after 
%%    	1000*100000000 ->
%%    		logging("server.log",io:format("Lifetime is over. Server ~p terminates" ,[self()])),
%%    		exit("Lifetime is over")
    end
.
    
%terminate(normal,state) -> ok.