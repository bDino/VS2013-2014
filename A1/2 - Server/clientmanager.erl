-module(clientmanager).
-author("Milena Dreier, Dino Buskulic").
-export([start/3]).
-import(werkzeug, [get_config_value/2, logging/2, logstop/0, timeMilliSecond/0]).

%%Syntax Eintrag ClientList: ClientId, {LastMsgId, Timestamp}

%%TODO: Client vergessen!

start(ClientLifetime, QueueManagerPID, ServerPID) ->
	ClientList = orddict:new(),
	run(ClientList, ClientLifetime, QueueManagerPID, ServerPID)
.


run(ClientList, ClientLifetime, QueueManagerPID, ServerPID) ->
	receive
		{getmessages, ClientId,ServerID} ->
			NewClientList = updateClientList(ClientList, ClientLifetime),
			getmessages(ClientId, NewClientList, ClientLifetime, QueueManagerPID, ServerPID,ServerID)
		
	end  
.
	
	
getmessages(ClientId, ClientList, ClientLifetime, QueueManagerPID, ServerPID,ServerID) ->
	io:fwrite("Client ~p fragt seine n�chste Nachricht ab\n",[ClientId]),
	case orddict:is_key(ClientId, ClientList) of
		true ->
			io:fwrite("Client ~p ist in Clientliste ~p vorhand\n",[ClientId, ClientList]),
			{LastMsgId, Timestamp} = orddict:fetch(ClientId, ClientList);
		false -> 
			LastMsgId = 0
		end,
	
	NewClientList = addClient(ClientId, LastMsgId, ClientList),
	QueueManagerPID ! {getmessagesbynumber, LastMsgId, self()},
	
	receive
		{Message, NewMsgId, Terminated} ->
		    {MsgId, NewTimestamp} = orddict:fetch(ClientId, NewClientList),
			ClientListWithNewMsgId = orddict:store(ClientId, {NewMsgId, NewTimestamp}, NewClientList),
            io:fwrite("CLientmanager hat Message vom QeueuManager bekommen und sendet an ServerPID: ~p -> ID: ~p\n",[ServerPID,ServerID]),
			ServerID ! {Message, NewMsgId, Terminated}
	end,
			 
	run(ClientListWithNewMsgId, ClientLifetime, QueueManagerPID, ServerPID)
.
	

updateClientList(ClientList, ClientLifetime) -> updateClientList(ClientList, ClientLifetime, []).


updateClientList([],_,List) -> List;

updateClientList([{CurrentClientId, {lastMsgId, Timestamp}}], ClientLifetime, List) ->
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
			 
%%	when (currentTimeInSec()-Timestamp) > ClientLifetime ->
%%	updateClientList(Tail, ClientLifetime, [{CurrentClientId, {lastMsgId, Timestamp}}|List]).
	


addClient(ClientId, LastMsgId, ClientList) ->
	io:fwrite("Client mit ClientID ~p, LastMsgId ~p und Timestamp ~p soll zur Clientliste hinzugef�gt werden\n", [ClientId, LastMsgId, timeMilliSecond()]),
	NewClients = orddict:store(ClientId, {LastMsgId, currentTimeInSec()}, ClientList),
        io:fwrite("Clientliste: ~p\n", [NewClients]),
	NewClients
.	


currentTimeInSec() ->
	{MegaSecs,Secs,MicroSecs} = now(),
	((MegaSecs*1000000 + Secs)*1000000 + MicroSecs) / 1000000
.
	
	
	
	
