-module(queuemanager).
-author("Milena Dreier, Dino Buskulic").
-export([start/1]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0]).

start(DLQCapacity) ->

    HoldBackQueu = orddict:new(),
    DeliveryQueue = orddict:new(),
    
    loop(HoldBackQueu, DeliveryQueue, DLQCapacity)
.

%TODO: TimeStamp für HBQ und DLQ
loop(HBQ,DLQ, DLQCapacity) -> 

    receive
        {dropmessage, {Message, Number}} ->
            ModifiedMsg = io:format("~p HBQ in : ~p",[Message,now()]),
            NewHBQ = orddict:store(Number,ModifiedMsg,HBQ),
            case checkIfEnoughMessages(NewHBQ, DLQCapacity) of
            	true -> transportToDLQ(NewHBQ, DLQ, DLQCapacity);
            	false -> loop(HBQ,DLQ, DLQCapacity)
            end
            
        {getmessagesbynumber, LastMsgId, ClientManagerId} ->
       		KeyList = orddict:fetch_keys(DLQ),	
       		LastNumber = lists:last(KeyList), 
       		
       		case (LastMsgId < LastNumber) of
				true -> MessageNumber = getmessagenumber(LastMsgId, DLQ, LastNumber),
						Message = orddict:fetch(MessageNumber, DLQ),
						case (MessageNumber < LastNumber) of 
							true -> Terminated = false;
							false -> Terminated = true
						end;	
				false -> Message = "Nichtleere Dummy Nachricht",
						 Terminated = true,
						 MessageNumber = LastMsgId
			end,
        	ClientManagerId ! {Message, MessageNumber, Terminated}
    end
.
  
getmessagenumber(LastMsgId, DLQ, LastNumber) ->
	NewMsgId = LastMsgId +1,
	
	case (orddict:is_key(NewMsgId, DLQ) of
        	true -> NewMsgId;
        	false -> getmessagenumber(NewMsgId, DLQ);
    end
.

	 

checkIfEnoughMessages(HBQ, DLQCapacity) ->
	Length = orddict:length(HBQ),
	Length > DLQCapacity/2
.


transportToDLQ(HBQ, DLQ, DLQCapacity) ->
	KeyList = orddict:fetch_keys(DLQ),
	LastKey = list:last(KeyList),
	NewKey = LastKey+1,
	case orddict:is_key(NewKey, HBQ) of
		true -> transport(HBQ, DLQ, DLQCapacity);
		false -> fillOffset(HBQ, DLQ, NewKey, DLQCapacity)
	end
.
	
fillOffset(HBQ, DLQ, NewKey, DLQCapacity) ->
	[Head|Tail] = orddict:fetch_keys(HBQ),
	Message = io:format("***Fehlernachricht fuer Nachrichtennummern ~p bis ~p um 16.05 18:01:30,580",[NewKey,Head-1]),
	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
	NewDLQ = orddict:store(Head-1, Message, ReadyDLQ),
	transport(HBQ, NewDLQ, DLQCapacity)
.


transport(HBQ, DLQ, DLQCapacity) ->
	KeyList = orddict:fetch_keys(HBQ),
	[Head|Tail] = KeyList,
	Element = orddict:fetch(Head, HBQ),
	orddict:erase(Head, HBQ),
	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
        ModifiedMsg = io:format("~p DLQ in : ~p",[Element,now()]),
	NewDLQ = orddict:store(Head, ModifiedMsg, ReadyDLQ),
	
	transport(Tail, NewDLQ, Head, DLQCapacity)
.

transport(HBQ, DLQ, LastHead, DLQCapacity) ->
	[Head|Tail] = orddict:fetch_keys(HBQ),
	case Head = (LastHead+1) of
		true -> Element = orddict:fetch(Head, HBQ),
				orddict:erase(Head, HBQ),
				ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
				NewDLQ = orddict:store(Head, Element, ReadyDLQ),
				transport(Tail, NewDLQ, Head, DLQCapacity);
		false -> loop(HBQ, DLQ, DLQCapacity)
	end
.
	
deleteIfFull(DLQ, DLQCapacity) ->
	Length = orddict:length(DLQ),
	
	case Length = DLQCapacity of
		true -> [Head|Tail] = orddict:fetch_key(DLQ),
				NewDLQ = orddict:erase(Head, DLQ);
		false -> NewDLQ = DLQ
	end,
	NewDLQ
.




	
    