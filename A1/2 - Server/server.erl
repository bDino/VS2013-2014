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
    
    ServerPID = spawn(fun() -> loop(self(),Lifetime,ClientmanagerPID,QueuemanagerPID,0) end),
    
    global:register_name(Servername,ServerPID),
    logging("server.log","...Server started and registered with Servername ...\n"),
    
    ServerPID
.


%% -------------------------------------------
%% loop-Funktion behandelt eingehende Nachrichten und wird immer wieder aufgerufen
loop(ServerPID,Lifetime,CManager,QManager,MessageNumber) ->

TRef = timer:send_after(Lifetime * 1000,ServerPID,{exit}),
    
    receive
        {getmsgid, ClientPID} ->
            timer:cancel(TRef), 
            logging("server.log",lists:concat(["Server: Received getmsgid von Client: ",pid_to_list(ClientPID)," ! ",MessageNumber,"\n"])),
            ClientPID ! {nnr,MessageNumber},
            NewMsgNr = MessageNumber+1,
            loop(ServerPID,Lifetime,CManager, QManager, NewMsgNr);

        {getmessages,ClientPID} ->
            timer:cancel(TRef),
            logging("server.log",lists:concat(["Server: Received getmessages von Client: ",pid_to_list(ClientPID),"\n"])),
            CManager ! {getmessages, ClientPID, self()},
            receive
                {Message,MsgId,Terminated} ->
                    ClientPID ! {reply,MsgId,Message,Terminated}
            end,
            
            loop(ServerPID,Lifetime,CManager, QManager, MessageNumber);
        
        {dropmessage, {Nachricht, Nr}} -> 
            timer:cancel(TRef),
            logging("server.log",lists:concat(["Server: Received dropmessage: ",Nachricht,"\n"])),
            QManager ! {dropmessage, {Nachricht, Nr}},
        
            loop(ServerPID,Lifetime,CManager, QManager, MessageNumber);
        
        {exit} -> 
            logging("server.log","Server Received Exit Signal and is Shuting down\n"),
            exit("Serverlifetime is over")
    end
.


