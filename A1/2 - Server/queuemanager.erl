-module(queuemanager).
-author("Milena Dreier, Dino Buskulic").
-export([start/1]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,
		 pushSL/2,popSL/1,popfiSL/1,findSL/2,findneSL/2,lengthSL/1,minNrSL/1,maxNrSL/1,emptySL/0,notemptySL/1,delete_last/1,shuffle/1,
		 timeMilliSecond/0,reset_timer/3,
		 type_is/1,to_String/1,list2String/1,
		 bestimme_mis/2]).

start(DLQCapacity) ->

    HoldBackQueu = emptySL(),
    DeliveryQueue = emptySL(),
    
    loop(HoldBackQueu, DeliveryQueue, DLQCapacity)
.

%TODO: TimeStamp für HBQ und DLQ
loop(HBQ,DLQ, DLQCapacity) -> 

    receive
        {dropmessage, {Message, Number}} ->
            ModifiedMsg = io:format("~p HBQ in : ~p",[Message,timeMilliSecond()]),
            logging("server.log",ModifiedMsg),
            NewHBQ = pushSL(HBQ,{Number,ModifiedMsg}),
            
            case checkIfEnoughMessages(NewHBQ, DLQCapacity) of
            	true -> transportToDLQ(NewHBQ, DLQ, DLQCapacity);
            	false -> loop(HBQ,DLQ, DLQCapacity)
            end;
            
        {getmessagesbynumber, LastMsgId, ClientManagerId} ->
                io:fwrite("QUEUEMANAGER getMessageByNumber ~p\n",[LastMsgId]),
       		
       		LastNumber = maxNrSL(DLQ), 
       		
       		case LastMsgId < LastNumber andalso notemptySL(DLQ) of
                        true ->      
                    io:fwrite("QUEUEMANAGER DLQ NOT EMPTY ~p\n",[DLQ]),
       	
                            MsgNr = LastMsgId+1,
                            Message = findneSL(DLQ,MsgNr),
                                case (MsgNr < LastNumber) of 
                                        true -> Terminated = false;
                                        false -> Terminated = true
                                end;	
                        false -> 
                                        io:fwrite("QUEUEMANAGER DLQ EMPTY ~p\n",[DLQ]),
                                        Message = "Nichtleere Dummy Nachricht",
                                        Terminated = true,
                                        MsgNr = LastMsgId
                end,
        
        	ClientManagerId ! {Message, MsgNr, Terminated}
    end
.	 

checkIfEnoughMessages(HBQ, DLQCapacity) ->
	Length = lengthSL(HBQ),
	Length > DLQCapacity/2
.


transportToDLQ(HBQ, DLQ, DLQCapacity) ->
        LastKey = maxNrSL(DLQ),
	NewKey = LastKey+1,
        MinNrHBQ = minNrSL(HBQ),
	
	case (MinNrHBQ-NewKey) > 1 of
            true ->     fillOffset(HBQ, DLQ, NewKey,MinNrHBQ, DLQCapacity);
            false ->    transport(HBQ, DLQ, MinNrHBQ, DLQCapacity)
	end
.
	
fillOffset(HBQ, DLQ, NewKey,MinNrHBQ, DLQCapacity) ->
        Message = io:format("***Fehlernachricht fuer Nachrichtennummern ~p bis ~p um 16.05 18:01:30,580",[NewKey,MinNrHBQ-1]),
        logging("server.log",Message),
	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
	NewDLQ = pushSL(ReadyDLQ, {MinNrHBQ-1,Message}),
	transport(HBQ, NewDLQ, MinNrHBQ, DLQCapacity)
.


transport(HBQ, DLQ,MinNrHBQ, DLQCapacity) ->
        io:fwrite("TRANSPORT FROM HBQ TO DLQ ~p\n",[MinNrHBQ]),
       		
	Element = findSL(HBQ, MinNrHBQ),
	Tail = popSL(HBQ),
	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
        ModifiedMsg = io:format("~p DLQ in : ~p",[Element, timeMilliSecond()]),
        logging("server.log",ModifiedMsg),
	NewDLQ = pushSL(ReadyDLQ,{MinNrHBQ,  ModifiedMsg}),
	
	transport_rek(Tail, NewDLQ, MinNrHBQ, DLQCapacity)
.

transport_rek(HBQ, DLQ, LastHead, DLQCapacity) ->
        io:fwrite("TRANSPORT REKURSIVE FROM HBQ TO DLQ ~p\n",[LastHead]),
	Head = minNrSL(HBQ),
	case Head == (LastHead+1) of
            true -> Element = findSL(HBQ,Head),
                            Tail = popSL(HBQ),
                            ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
                            NewDLQ = pushSL(ReadyDLQ,{Head,Element}),
                            transport_rek(Tail, NewDLQ, Head, DLQCapacity);
            false -> loop(HBQ, DLQ, DLQCapacity)
	end
.
	
deleteIfFull(DLQ, DLQCapacity) ->
	Length = lengthSL(DLQ),
	
	case Length = DLQCapacity of
		true ->         NewDLQ = popSL(DLQ);
		false ->        NewDLQ = DLQ
	end,
	NewDLQ
.




	
    