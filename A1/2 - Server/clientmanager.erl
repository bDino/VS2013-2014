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
                    NewClientList = updateClientList(ClientList, ClientLifetime),
                    getmessages(ClientId, NewClientList, ClientLifetime, QueueManagerPID, ServerPID)		
	end  
.
	
%% -------------------------------------------	
%% getmessages ermittelt die Nummer der vom Client zuletzt erhaltenen Nachricht mithilfe der ClientListe
%% ist der Client nicht in der Liste ist seine letzte Nachrichtennummer 0 und er wird in die Liste aufgenommen
%% mithilfe der letzten Nachrichten Nummer und des Queuemanagers wird die Nachricht ermittelt
getmessages(ClientId, ClientList, ClientLifetime, QueueManagerPID, ServerPID) ->
	case orddict:is_key(ClientId, ClientList) of
		true ->
			{LastMsgId, Timestamp} = orddict:fetch(ClientId, ClientList);
		false -> 
			LastMsgId = -1
		end,
	
	NewClientList = addClient(ClientId, LastMsgId, ClientList),
	QueueManagerPID ! {getmessagesbynumber, LastMsgId, self()},
	
	receive
		{Message, NewMsgId, Terminated} ->
                io:format("CMANAGER RECEIVED MSG ~p: ~p\n und TERMINATED IS ~p\n",[NewMsgId, Message, Terminated]),
		    {MsgId, NewTimestamp} = orddict:fetch(ClientId, NewClientList),
			ClientListWithNewMsgId = orddict:store(ClientId, {NewMsgId, NewTimestamp}, NewClientList),
                       ServerPID ! {Message, NewMsgId, Terminated}
	end,
			 
	loop(ClientListWithNewMsgId, ClientLifetime, QueueManagerPID)
.
	
%% -------------------------------------------
%% pr�ft ob sich in der Clientliste Clients aufhalten die l�nger als Lifetime nichts gesendet haben
%% erstellt rekursiv eine Liste die nur die aktuellen Clients enth�lt und gibt diese zur�ck
updateClientList(ClientList, ClientLifetime) -> io:fwrite("CLIENTLIST vorm update: ~p",[ClientList]), 
        updateClientList(ClientList, ClientLifetime, []).

% ------
updateClientList([],_,List) -> 
        io:fwrite("CLIENTLIST ist leer und muss nicht geupdated werde\n"),
        List;

updateClientList([{CurrentClientId, Value}], ClientLifetime, List) ->
        io:fwrite("CLIENTLIST hat nur einen Eintrag: ~p, ~p",[CurrentClientId, Value]),
		{LastMsgId, Timestamp} = Value,
        Lifetime = currentTimeInSec()-Timestamp,
	case (Lifetime > ClientLifetime) of
		true -> NewList = List;
		false -> NewList = orddict:store(CurrentClientId, {LastMsgId, Timestamp}, List)
	end, 
	updateClientList([], ClientLifetime, NewList);
	    
updateClientList(ClientList, ClientLifetime, List) ->
        [{CurrentClientId, Value},_] = ClientList,
        {LastMsgId, Timestamp} = Value,
	Lifetime = currentTimeInSec()-Timestamp,
	case (Lifetime > ClientLifetime) of
		true -> NewList = List;
		false -> NewList = orddict:store(CurrentClientId, {LastMsgId, Timestamp}, List)
	end,
        Tail = orddict:erase(CurrentClientId,ClientList), 
	updateClientList(Tail, ClientLifetime, NewList)
.

%% -------------------------------------------
%% f�gt einen Client mit einem aktuellen Zeitstempel in die Clientliste ein
addClient(ClientId, LastMsgId, ClientList) ->
	io:fwrite("Client mit ClientID ~p, LastMsgId ~p und Timestamp ~p soll zur Clientliste hinzugef�gt werden\n", [ClientId, LastMsgId, timeMilliSecond()]),
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
	
	
	
	
