-module(clientmanager).
-author("Milena Dreier, Dino Buskulic").
-export([start/3]).
%%-import(werkzeug, [get_config_value/2, logging/2, logstop/0, timeMilliSecond/0]).

%%Syntax Eintrag ClientList: ClientId, {LastMsgId, Timestamp}

%%TODO: Client vergessen!

start(ClientLifetime, QueueManagerPID, ServerPID) ->
	ClientList = orddict:new(),
	run(ClientList, ClientLifetime, QueueManagerPID, ServerPID)
.


run(ClientList, ClientLifetime, QueueManagerPID, ServerPID) ->
	receive
		{getmessages, ClientId} ->
			NewClientList = updateClientList(ClientList, ClientLifetime),
			getmessages(ClientId, NewClientList, ClientLifetime, QueueManagerPID, ServerPID)
		
	end
.
	
	
getmessages(ClientId, ClientList, ClientLifetime, QueueManagerPID, ServerPID) ->

	case orddict:is_key(ClientId, ClientList) of
		true ->
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
			ServerPID ! {Message, NewMsgId, Terminated}
	end,
			
	run(ClientListWithNewMsgId, ClientLifetime, QueueManagerPID, ServerPID)
.
	

updateClientList(ClientList, ClientLifetime) -> updateClientList(ClientList, ClientLifetime, []).

updateClientList([],_,List) -> List;
updateClientList([{CurrentClientId ,{lastMsgId, Timestamp}} | Tail], ClientLifetime, List) ->
	Lifetime = currentTimeInSec()-Timestamp,
	case (Lifetime > ClientLifetime) of
		true -> NewList = List;
		false -> NewList = orddict:store(CurrentClientId, {lastMsgId, Timestamp}, List)
	end,
	updateClientList(Tail, ClientLifetime, NewList)
.
			 
%%	when (currentTimeInSec()-Timestamp) > ClientLifetime ->
%%	updateClientList(Tail, ClientLifetime, [{CurrentClientId, {lastMsgId, Timestamp}}|List]).
	


addClient(ClientId, LastMsgId, ClientList) ->
	newList = orddict:store(ClientId, {LastMsgId, currentTimeInSec()}, ClientList)
.	


currentTimeInSec() ->
	{MegaSecs,Secs,MicroSecs} = now(),
	((MegaSecs*1000000 + Secs)*1000000 + MicroSecs) / 1000000
.
	
	
	
	
