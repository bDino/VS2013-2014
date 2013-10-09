-module(queuemanager).
-author("Milena Dreier, Dino Buskulic").
-export([start/1]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,
		 pushSL/2,popSL/1,popfiSL/1,findSL/2,findneSL/2,lengthSL/1,minNrSL/1,maxNrSL/1,emptySL/0,notemptySL/1,delete_last/1,shuffle/1,
		 timeMilliSecond/0,reset_timer/3,
		 type_is/1,to_String/1,list2String/1,
		 bestimme_mis/2]).

%% -------------------------------------------
% Queuemanager
%% -------------------------------------------
%%
%% -------------------------------------------
%% startet den Queuemanager
%% wird von server.erl aufgerufen
% Param: DLQCapacity -> die Kapazität der Delivery Queue
%
start(DLQCapacity) ->

    HoldBackQueu = emptySL(),
    DeliveryQueue = emptySL(),
    logging("server.log","...Queuemanager started ...\n"),
    loop(HoldBackQueu, DeliveryQueue, DLQCapacity)
.


%% -------------------------------------------
%% loop-Funktion des Queuemanagers wird immer wieder wiederholt
%% reagiert im receive-Block auf an ihn gesendete Nachrichten
loop(HBQ,DLQ, DLQCapacity) -> 
    io:fwrite("Queuemanager im LOOP\n"),
    receive
    	%% dropmessage fügt der übergebenen Message einen Zeitstempel an und legt sie anschließend in der HBQ ab
    	%% wenn: HBQ > DLQCapacity/2 werden Messages aus der HBQ in die DLQ übertragen: transportToDLQ(?)
        {dropmessage, {Message, Number}} ->
            io:fwrite("DROPMESSAGE im queuemanager mit Message Number ~p\n",[Number]),
            ModifiedMsg = lists:concat([Message,". HBQ in : ",timeMilliSecond()]),
            logging("server.log",ModifiedMsg),
            Elem = {Number, ModifiedMsg},
            NewHBQ = pushSL(HBQ,Elem),
            io:fwrite("HBQ: ~p\n",[NewHBQ]),
            
            
            case checkIfEnoughMessages(NewHBQ, DLQCapacity) of
            	true -> transportToDLQ(NewHBQ, DLQ, DLQCapacity);
            	false -> loop(HBQ,DLQ, DLQCapacity)
            end;
         
        %% getmessagesbynumber bekommt die Nummer der zuletzt erhaltenen Nachricht übergeben und gibt die Nachricht aus 
        %% die sich als nächstes in der DLQ befindet   
        {getmessagesbynumber, LastMsgId, ClientManagerId} ->
                io:fwrite("QUEUEMANAGER getMessageByNumber ~p\n",[LastMsgId]),
       		
       		LastNumber = maxNrSL(DLQ), 
       		
       		case LastMsgId < LastNumber andalso notemptySL(DLQ) of
                        true ->      
                    		io:fwrite("QUEUEMANAGER DLQ NOT EMPTY ~p\n",[DLQ]),
       	
                            MsgNr = LastMsgId+1,
                            %% Fehlercode wenn DLQ leer -> nicht möglich, da Abfrage zuvor
                            %% Fehlercode wenn Element nicht vorhanden und auch kein größeres -> nicht möglich, da LastMsgId < LastNumber
                            Message = findneSL(DLQ,MsgNr),
                                case (MsgNr == LastNumber) of 
                                        true -> Terminated = true;
                                        false -> Terminated = false
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

%% -------------------------------------------
%% Kontrolliert ob Nachrichten aus der HBQ in die DLQ gepackt werden können, dh ob |HBQ| > Kapazität(DLQ)
checkIfEnoughMessages(HBQ, DLQCapacity) ->
	Length = lengthSL(HBQ),
        io:fwrite("CHECKIFENOUGHMESSAGES! Länge HBQ: ~p\n",[Length]),
	Length > DLQCapacity/2
.

%% -------------------------------------------
%% Lässt Nachrichten von der HBQ in die DLQ übertragen wenn zwischen beiden Queues keine Lücke ist, sonst füllt er die Lücke mit einer
%% Fehlernachricht
transportToDLQ(HBQ, DLQ, DLQCapacity) ->
        LastKey = maxNrSL(DLQ),
	NewKey = LastKey+1,
        MinNrHBQ = minNrSL(HBQ),
	
	case (MinNrHBQ-NewKey) > 1 of
            true ->     fillOffset(HBQ, DLQ, NewKey,MinNrHBQ, DLQCapacity);
            false ->    transport(HBQ, DLQ, MinNrHBQ, DLQCapacity)
	end
.

%% -------------------------------------------
%% Füllt die Lücke zwischen DLQ und HBQ mit einer entsprechenden Fehlermeldung
%% Fehlermeldung bekommt MsgId der letzten nicht übertragenden Nachricht aus dieser Lücke
%% TODO: Client könnte denken dass das seine Nachricht ist und sie dementsprechend anders ausgeben	
fillOffset(HBQ, DLQ, NewKey,MinNrHBQ, DLQCapacity) ->
        Message = lists:concat(["***Fehlernachricht fuer Nachrichtennummer ",NewKey," bis ",MinNrHBQ-1," um ",timeMilliSecond]),
        logging("server.log",Message),
	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
	NewDLQ = pushSL(ReadyDLQ, {MinNrHBQ-1,Message}),
	transport(HBQ, NewDLQ, MinNrHBQ, DLQCapacity)
.

%% -------------------------------------------
%% Schreibt das erste Element aus der HBQ in die DLQ
transport(HBQ, DLQ,MinNrHBQ, DLQCapacity) ->
        io:fwrite("TRANSPORT FROM HBQ TO DLQ ~p\n",[MinNrHBQ]),
       		
	Element = findSL(HBQ, MinNrHBQ),
	Tail = popSL(HBQ),
	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
        ModifiedMsg = lists:concat([Element," DLQ in : ",timeMilliSecond()]),
        logging("server.log",ModifiedMsg),
	NewDLQ = pushSL(ReadyDLQ,{MinNrHBQ,  ModifiedMsg}),
	
	transport_rek(Tail, NewDLQ, MinNrHBQ, DLQCapacity)
.

%% --------
%% Schreibt solange Elemente aus der HBQ in die DLQ bis eine Lücke erreicht wurde oder die HBQ leer ist
%% Ruft anschließend wieder die loop-Funktion auf
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

%% -------------------------------------------
%% Löscht das erste Element aus der DLQ wenn diese voll ist, sonst gibt er sie unverändert zurück	
deleteIfFull(DLQ, DLQCapacity) ->
	Length = lengthSL(DLQ),
	
	case Length = DLQCapacity of
		true ->         NewDLQ = popSL(DLQ);
		false ->        NewDLQ = DLQ
	end,
	NewDLQ
.




	
    