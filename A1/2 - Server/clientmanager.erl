-module(clientmanager).
-author("Milena Dreier, Dino Buskulic").
-export([start/2]).
-import(werkzeug, [get_config_value/2, logging/2, logstop/0, timeMilliSecond/0]).

%%Syntax Eintrag ClientList: ClientId, {LastMsgId, Timestamp}

%%TODO: Client vergessen!

%% -------------------------------------------
%  Clientmanager
%% -------------------------------------------
%%
%% -------------------------------------------
%% startet den Clientmanager
%% wird von server.erl aufgerufen
% Param: 	ClientLifetime -> wie lange soll der Client gemerkt werden
%			QueueManagerPID -> ID des Queuemanager Prozesses
%

start(ClientLifetime, QueueManagerPID) ->
        logging("server.log","...Clientmanager started ... \n"),
	ClientList = orddict:new(),
	loop(ClientList, ClientLifetime, QueueManagerPID)
.


%% -------------------------------------------
%% loop-Funktion wird immer wieder aufgerufen und reagiert auf eingehende Nachrichten
loop(ClientList, ClientLifetime, QueueManagerPID) ->
	receive
            {getmessages, ClientId, ServerPID} ->
                    %NewClientList = updateClientList(ClientList, ClientLifetime),
                    getmessages(ClientId, ClientList, ClientLifetime, QueueManagerPID, ServerPID);
            
            {timer_timeout,ClientId} ->
                    
                            
	end  
.
	
%% -------------------------------------------	
%% getmessages ermittelt die Nummer der vom Client zuletzt erhaltenen Nachricht mithilfe der ClientListe
%% ist der Client nicht in der Liste ist seine letzte Nachrichtennummer 0 und er wird in die Liste aufgenommen
%% mithilfe der letzten Nachrichten Nummer und des Queuemanagers wird die Nachricht ermittelt
getmessages(ClientId, ClientList, ClientLifetime, QueueManagerPID, ServerPID) ->
	case orddict:is_key(ClientId, ClientList) of
		true ->
                        io:fwrite("Client ~p ist in Clientliste\n", [ClientId]),
			{LastMsgId, Timestamp} = orddict:fetch(ClientId, ClientList);
		false -> 
                        io:fwrite("Client ~p ist nicht in Clientliste\n", [ClientId]),
			LastMsgId = -1
		end,
	
	NewClientList = addClient(ClientId, LastMsgId, ClientList),
        %io:fwrite("QUEUEMANAGER wird aufgefordert die Message zur letzten Nummer: ~p auszugeben \n", [LastMsgId]),
	QueueManagerPID ! {getmessagesbynumber, LastMsgId, self()},
	
	receive
		{Message, NewMsgId, Terminated} ->
                %io:format("CMANAGER RECEIVED MSG ~p: ~p\n und TERMINATED IS ~p\n",[NewMsgId, Message, Terminated]),
                {MsgId, NewTimestamp} = orddict:fetch(ClientId, NewClientList),
                ClientListWithNewMsgId = orddict:store(ClientId, {NewMsgId, NewTimestamp}, NewClientList),
                %io:fwrite("Clientliste mit aktualisiertem Client ~p: ~p\n", [ClientId, NewClientList]),
                ServerPID ! {Message, NewMsgId, Terminated}
	end,
			 
	loop(ClientListWithNewMsgId, ClientLifetime, QueueManagerPID)
.
	

%% -------------------------------------------
%% fügt einen Client mit einem aktuellen Zeitstempel in die Clientliste ein
addClient(ClientId, LastMsgId, ClientList) ->
	%logging("server.log",lists:concat(["Neuer Client in Client Liste: ", pid_to_list(ClientId),"\n"])), 
	NewClients = orddict:store(ClientId, {LastMsgId, currentTimeInSec()}, ClientList),
	NewClients
.	

%% -------------------------------------------
%% gibt die aktuelle Zeit in Sekunden aus, um sie in der Clientliste zu speichern und mit der Variable Clientlifetime zu vergleichen
currentTimeInSec() ->
	{MegaSecs,Secs,MicroSecs} = now(),
	%((MegaSecs*1000000 + Secs)*1000000 + MicroSecs) / 1000000
        Secs
.
	
	
%deleteClientFromList([]) -> [].	
	

%%%% -------------------------------------------
%%%% prüft ob sich in der Clientliste Clients aufhalten die länger als Lifetime nichts gesendet haben
%%%% erstellt rekursiv eine Liste die nur die aktuellen Clients enthält und gibt diese zurück
%%updateClientList(ClientList, ClientLifetime) -> 
%%        %io:fwrite("CLIENTLIST vorm update: ~p",[ClientList]), 
%%        updateClientList(ClientList, ClientLifetime, orddict:new()).

%%% ------
%%updateClientList([],_,List) -> 
%%        %io:fwrite("Clientliste ist leer"),
%%        %io:fwrite("CLIENTLIST ist leer, neue LISTE: ~p\n", [List]),
%%        orddict:new();

%%updateClientList([{CurrentClientId, Value}], ClientLifetime, List) ->
%%        %io:fwrite("Ein Eintrag in Clientliste"),
%%        %io:fwrite("CLIENTLIST hat nur einen Eintrag: ~p, ~p",[CurrentClientId, Value]),
%%		{LastMsgId, Timestamp} = Value,
%%        Lifetime = currentTimeInSec()-Timestamp,
%%	case (Lifetime > ClientLifetime) of
%%		true -> NewList = List;
%%		false -> NewList = orddict:store(CurrentClientId, {LastMsgId, Timestamp}, List)
%%	end, 
%%	updateClientList(orddict:new(), ClientLifetime, NewList);
	    
%%updateClientList(ClientList, ClientLifetime, List) ->
%%        %io:fwrite("Mehrere Einträge in Clientliste"),
%%        [{CurrentClientId, {LastMsgId,TimeStamp}},_] = ClientList,
%%	Lifetime = currentTimeInSec()-TimeStamp,
%%	case (Lifetime > ClientLifetime) of
%%		true -> io:fwrite("Clientlifetime ~p ist abgelaufen", [CurrentClientId]),
%%                        NewList = List;
%%		false ->    io:fwrite("Clientlifetime ~p ist noch nicht abgelaufen", [CurrentClientId]),
%%                            NewList = orddict:store(CurrentClientId, {LastMsgId, TimeStamp}, List)
%%	end,
%%        Tail = orddict:erase(CurrentClientId,ClientList), 
%%	updateClientList(Tail, ClientLifetime, NewList)
%%.

	
	
	
