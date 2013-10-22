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
            
            {client_timeout, ClientId} ->
                    io:fwrite("Client ~p wird aus Clientliste entfernt\n", [ClientId]),
                    NewClientlist = orddict:erase(ClientId, ClientList),
                    loop(NewClientlist, ClientLifetime, QueueManagerPID)
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
			{LastMsgid, TRef} = orddict:fetch(ClientId, ClientList),
                        {Succes, _} = timer:cancel(TRef),
                        case Succes == error of
                            true ->     io:fwrite("Timer für Client ~p war nicht mehr aktiv!!\n",[ClientId]),
                                        LastMsgId = -1;
                            false ->    LastMsgId = LastMsgid
                        end;
		false -> 
                        io:fwrite("Client ~p ist nicht in Clientliste\n", [ClientId]),
			LastMsgId = -1
		end,
	
	{ok, TimerRef} = timer:send_after(ClientLifetime, {client_timeout, ClientId}),
	NewClientList = orddict:store(ClientId, {LastMsgId, TimerRef}, ClientList),
        %io:fwrite("QUEUEMANAGER wird aufgefordert die Message zur letzten Nummer: ~p auszugeben \n", [LastMsgId]),
	QueueManagerPID ! {getmessagesbynumber, LastMsgId, self()},
	
	receive
		{Message, NewMsgId, Terminated} ->
                %io:format("CMANAGER RECEIVED MSG ~p: ~p\n und TERMINATED IS ~p\n",[NewMsgId, Message, Terminated]),
                {_MsgId, NewTimerRef} = orddict:fetch(ClientId, NewClientList),
                ClientListWithNewMsgId = orddict:store(ClientId, {NewMsgId, NewTimerRef}, NewClientList),
                %io:fwrite("Clientliste mit aktualisiertem Client ~p: ~p\n", [ClientId, NewClientList]),
                ServerPID ! {Message, NewMsgId, Terminated}
	end,
			 
	loop(ClientListWithNewMsgId, ClientLifetime, QueueManagerPID)
.
		
		

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

	
	
	
