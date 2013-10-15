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
    receive
    	%% dropmessage fügt der übergebenen Message einen Zeitstempel an und legt sie anschließend in der HBQ ab
    	%% wenn: HBQ > DLQCapacity/2 werden Messages aus der HBQ in die DLQ übertragen: transportToDLQ(?)
        {dropmessage, {Message, Number}} ->
            io:fwrite("DROPMESSAGE im queuemanager mit Message Number ~p\n",[Number]),
            ModifiedMsg = lists:concat([Message,". HBQ in : ",timeMilliSecond()]),
            logging("server.log",ModifiedMsg),
            Elem = {Number, ModifiedMsg},
            UpdatedHBQ = pushSL(HBQ,Elem),
            
            case checkIfEnoughMessages(UpdatedHBQ, DLQCapacity) of
            	true -> {NewHBQ, NewDLQ} = transportToDLQ(UpdatedHBQ, DLQ, DLQCapacity);
            	false -> NewDLQ = DLQ,
                         NewHBQ = UpdatedHBQ
            end,
        
            io:fwrite("#####QEUES TRANSPORTED: HBQ: ~p\n DLQ: ~p\n",[NewHBQ,NewDLQ]),
            loop(NewHBQ, NewDLQ, DLQCapacity);
         
        %% getmessagesbynumber bekommt die Nummer der zuletzt erhaltenen Nachricht übergeben und gibt die Nachricht aus 
        %% die sich als nächstes in der DLQ befindet   
        {getmessagesbynumber, LastMsgId, ClientManagerId} ->
                
       		LastNumber = minNrSL(DLQ), 
       		io:fwrite("QUEUEMANAGER LastNumber ~p  -   LastMsgId ~p\n",[LastNumber,LastMsgId]),
       		
       		case LastMsgId =< LastNumber+1 andalso notemptySL(DLQ) of
                        true ->      
                    		io:fwrite("QUEUEMANAGER DLQ NOT EMPTY ~p\n",[DLQ]),
       	
                            %% Fehlercode wenn DLQ leer -> nicht möglich, da Abfrage zuvor
                            %% Fehlercode wenn Element nicht vorhanden und auch kein größeres -> nicht möglich, da LastMsgId < LastNumber
                            Message = findneSL(DLQ,LastMsgId),
                                case (LastMsgId == maxNrSL(DLQ)) of 
                                        true -> Terminated = true;
                                        false -> Terminated = false
                                end;
                        false -> 
                            io:fwrite("QUEUEMANAGER DLQ EMPTY ~p\n",[DLQ]),
                            Message = "Nichtleere Dummy Nachricht",
                            Terminated = true
            end,
        	ClientManagerId ! {Message, LastMsgId, Terminated}
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
        
        %Abbruchbedingung für die Rekursion -> nur so lange übertragen bis die HBQ length noch ok ist
        case lengthSL(HBQ) > DLQCapacity/2 of
            true ->
                LastKey = maxNrSL(DLQ),
                NewKey = LastKey+1,
                MinNrHBQ = minNrSL(HBQ),
                
                Diff = MinNrHBQ-NewKey,
                
                io:format("TRANSPORT DLQ DIFF: ~p  LASTKEY: ~p  NEWKEY ~p  MIN NR HBQ ~p\n",[Diff,LastKey,NewKey,MinNrHBQ]),
                case Diff == 0 of
                    true ->     %Kann übertragen werden da DLQ leer und Erstes Elem in HBQ = 0
                                io:format("IN TRANSPORT ONCE\n"),
                                {NewHBQ,NewDLQ} = transportOnceFromHBQtoDLQ(HBQ,DLQ),
                                transportToDLQ(NewHBQ,NewDLQ,DLQCapacity);
                    
                    false ->    %Wenn eine Lücke enstanden ist, pushe Fehlernachricht in die DLQ mit der Nummer der letzten Nachricht
                                ModifiedMsg = lists:concat(["*****Fehlernachricht fuer Nachrichtennummer ",MinNrHBQ," bis ",NewKey," um ",timeMilliSecond]),
                                logging("server.log",ModifiedMsg),
                                ReadyDLQ = pushSL(DLQ, {MinNrHBQ,ModifiedMsg}),
                                transportToDLQ(HBQ,ReadyDLQ,DLQCapacity)
                end;
    
        false -> {HBQ,DLQ}
    
    end
    
.       

transportOnceFromHBQtoDLQ(HBQ,DLQ) ->
    Nr = minNrSL(HBQ),
    NewDLQElem = findneSL(HBQ,Nr),
    io:format("NEW ELEMENT NACH POPFI: ~p",[NewDLQElem]),
    NewDLQ = pushSL(DLQ,NewDLQElem),
    io:format("NEW DLQ NACH PUSHSL: ~p",[NewDLQ]),
    NewHBQ = popSL(HBQ),
    io:format("NEW HBQ NACH POPFI: ~p",[NewHBQ]),
    {NewHBQ,NewDLQ}
.


%% --------
%% Schreibt solange Elemente aus der HBQ in die DLQ bis eine Lücke erreicht wurde oder die HBQ leer ist
%% Ruft anschließend wieder die loop-Funktion auf
transport_rek(HBQ, DLQ, LastMsgID, DLQCapacity) ->
        io:fwrite("TRANSPORT REKURSIVE FROM HBQ TO DLQ ~p\n",[LastMsgID]),
	MsgId = minNrSL(HBQ),
	case MsgId == (LastMsgID+1) of
            true ->     Message = findSL(HBQ,MsgId),
                        NewHBQ = popSL(HBQ),
                        ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
                        ModifiedMsg = lists:concat([Message," DLQ in : ",timeMilliSecond()]),
                        NewDLQ = pushSL(ReadyDLQ,{MsgId,ModifiedMsg}),
                        transport_rek(NewHBQ, NewDLQ, MsgId, DLQCapacity);
            false ->    {HBQ, DLQ}
	end
        
.

%% -------------------------------------------
%% Löscht das erste Element aus der DLQ wenn diese voll ist, sonst gibt er sie unverändert zurück	
deleteIfFull(DLQ, DLQCapacity) ->
	Length = lengthSL(DLQ),
	
	case Length == DLQCapacity of
		true ->         NewDLQ = popSL(DLQ);
		false ->        NewDLQ = DLQ
	end,
	NewDLQ
.


%% -------------------------------------------
%% Schreibt das erste Element aus der HBQ in die DLQ
%%transport(HBQ, DLQ,MinNrHBQ, DLQCapacity) ->
%%        io:fwrite("TRANSPORT FROM HBQ TO DLQ ~p\n",[MinNrHBQ]),
%%       		
%%	Element = findSL(HBQ, MinNrHBQ),
%%	Tail = popSL(HBQ),
%%	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
%%        ModifiedMsg = lists:concat([Element," DLQ in : ",timeMilliSecond()]),
%%        logging("server.log",ModifiedMsg),
%%	NewDLQ = pushSL(ReadyDLQ,{MinNrHBQ,  ModifiedMsg}),
%%	
%%	transport_rek(Tail, NewDLQ, MinNrHBQ, DLQCapacity)
%%.


%% -------------------------------------------
%% Füllt die Lücke zwischen DLQ und HBQ mit einer entsprechenden Fehlermeldung
%% Fehlermeldung bekommt MsgId der letzten nicht übertragenden Nachricht aus dieser Lücke
%% TODO: Client könnte denken dass das seine Nachricht ist und sie dementsprechend anders ausgeben	
%%fillOffset(HBQ, DLQ, NewKey,MinNrHBQ, DLQCapacity) ->
%%        Message = lists:concat(["***Fehlernachricht fuer Nachrichtennummer ",NewKey," bis ",MinNrHBQ-1," um ",timeMilliSecond]),
%%        logging("server.log",Message),
%%	ReadyDLQ = deleteIfFull(DLQ, DLQCapacity),
%%	NewDLQ = pushSL(ReadyDLQ, {MinNrHBQ-1,Message}),
%%	transport(HBQ, NewDLQ, MinNrHBQ, DLQCapacity)
%%.	
    