-module(clientmanagerN).
-author("Milena Dreier, Dino Buskulic").
-export([start/2]).
-import(werkzeug, [get_config_value/2, logging/2, logstop/0, timeMilliSecond/0]).

%%Syntax Eintrag ClientList: ClientId, {LastMsgId, Timestamp}

%%TODO: Client vergessen!

%% -------------------------------------------
% Clientmanager
%% -------------------------------------------
%%
%% -------------------------------------------
%% startet den Clientmanager
%% wird von server.erl aufgerufen
% Param: 	ClientLifetime -> wie lange soll der Client gemerkt werden
%			QueueManagerPID -> ID des Queuemanager Prozesses
%

	
%% -------------------------------------------	
%% getmessages ermittelt die Nummer der vom Client zuletzt erhaltenen Nachricht mithilfe der ClientListe
%% ist der Client nicht in der Liste ist seine letzte Nachrichtennummer 0 und er wird in die Liste aufgenommen
%% mithilfe der letzten Nachrichten Nummer und des Queuemanagers wird die Nachricht ermittelt
getmessages(ClientId, ClientList, ClientLifetime) ->
	io:fwrite("Clientmanager sucht letzte nachrichten nummer von Client ~p\n",[ClientId]),
        NewClientList = updateClientList(ClientList, ClientLifetime),
	case orddict:is_key(ClientId, ClientList) of
		true ->
			io:fwrite("Client ~p ist in Clientliste ~p vorhand\n",[ClientId, ClientList]),
			{LastMsgId, Timestamp} = orddict:fetch(ClientId, ClientList);
		false -> 
			LastMsgId = 0
		end,
	
	NewClientList = addClient(ClientId, LastMsgId, ClientList),
	{NewClientList, LastM.
	
	receive
		{Message, NewMsgId, Terminated} ->
		    {MsgId, NewTimestamp} = orddict:fetch(ClientId, NewClientList),
			ClientListWithNewMsgId = orddict:store(ClientId, {NewMsgId, NewTimestamp}, NewClientList),
            io:fwrite("CLientmanager hat Message vom QeueuManager bekommen und sendet an ServerPID: ~p\n",[ServerPID]),
			ServerPID ! {Message, NewMsgId, Terminated}
	end,
.
	
%% -------------------------------------------
%% prüft ob sich in der Clientliste Clients aufhalten die länger als Lifetime nichts gesendet haben
%% erstellt rekursiv eine Liste die nur die aktuellen Clients enthält und gibt diese zurück
updateClientList(ClientList, ClientLifetime) -> io:fwrite("CLIENTLIST orm update: ~p",[ClientList]), 
        updateClientList(ClientList, ClientLifetime, []).

% ------
updateClientList([],_,List) -> 
        io:write("CLIENTLIST ist leer und muss nicht geupdated werde"),
        List;

updateClientList([{CurrentClientId, Value}], ClientLifetime, List) ->
        io:fwrite("CLIENTLIST hat nur einen Eintrag: ~p, ~p",[CurrentClientId, Value]),
		{lastMsgId, Timestamp} = Value,
        Lifetime = currentTimeInSec()-Timestamp,
	case (Lifetime > ClientLifetime) of
		true -> NewList = List;
		false -> NewList = orddict:store(CurrentClientId, {lastMsgId, Timestamp}, List)
	end, 
	updateClientList([], ClientLifetime, NewList);
	    
updateClientList(ClientList, ClientLifetime, List) ->
        [{CurrentClientId, Value},_] = ClientList,
        {lastMsgId, Timestamp} = Value,
	Lifetime = currentTimeInSec()-Timestamp,
	case (Lifetime > ClientLifetime) of
		true -> NewList = List;
		false -> NewList = orddict:store(CurrentClientId, {lastMsgId, Timestamp}, List)
	end,
        Tail = orddict:erase(CurrentClientId,ClientList), 
	updateClientList(Tail, ClientLifetime, NewList)
.

%% -------------------------------------------
%% fügt einen Client mit einem aktuellen Zeitstempel in die Clientliste ein
addClient(ClientId, LastMsgId, ClientList) ->
	io:fwrite("Client mit ClientID ~p, LastMsgId ~p und Timestamp ~p soll zur Clientliste hinzugefügt werden\n", [ClientId, LastMsgId, timeMilliSecond()]),
	NewClients = orddict:store(ClientId, {LastMsgId, currentTimeInSec()}, ClientList),
        io:fwrite("Clientliste: ~p\n", [NewClients]),
	NewClients
.	

%% -------------------------------------------
%% gibt die aktuelle Zeit in Sekunden aus, um sie in der Clientliste zu speichern und mit der Variable Clientlifetime zu vergleichen
currentTimeInSec() ->
	{MegaSecs,Secs,MicroSecs} = now(),
	%((MegaSecs*1000000 + Secs)*1000000 + MicroSecs) / 1000000
        Secs
.
	
	
	
	
