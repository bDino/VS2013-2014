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
% Param: DLQCapacity -> die Kapazit�t der Delivery Queue
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
    	%% dropmessage f�gt der �bergebenen Message einen Zeitstempel an und legt sie anschlie�end in der HBQ ab
    	%% wenn: HBQ > DLQCapacity/2 werden Messages aus der HBQ in die DLQ �bertragen: transportToDLQ(?)
        {dropmessage, {Message, Number}} ->
            io:fwrite("DROPMESSAGE im queuemanager mit Message Number ~p\n",[Number]),
            ModifiedMsg = lists:concat([Message," HBQ in : ",timeMilliSecond()]),
            logging("server.log",ModifiedMsg),
            Elem = {Number, ModifiedMsg},
            UpdatedHBQ = pushSL(HBQ,Elem),
            
            case checkIfEnoughMessages(UpdatedHBQ, DLQCapacity) of
            	true -> {NewHBQ, NewDLQ} = transportToDLQ(UpdatedHBQ, DLQ, DLQCapacity);
            	false -> NewDLQ = DLQ,
                         NewHBQ = UpdatedHBQ
            end,
        
            loop(NewHBQ, NewDLQ, DLQCapacity);
         
        %% getmessagesbynumber bekommt die Nummer der zuletzt erhaltenen Nachricht �bergeben und gibt die Nachricht aus 
        %% die sich als n�chstes in der DLQ befindet   
        {getmessagesbynumber, LastMsgId, ClientManagerId} ->
                
       		LastNumber = minNrSL(DLQ), 
       		io:fwrite("QUEUEMANAGER LastNumber ~p  -   LastMsgId ~p\n",[LastNumber,LastMsgId]),
       		
       		case LastMsgId =< LastNumber andalso notemptySL(DLQ) of
                        true ->      
                            %% Fehlercode wenn DLQ leer -> nicht m�glich, da Abfrage zuvor
                            %% Fehlercode wenn Element nicht vorhanden und auch kein gr��eres -> nicht m�glich, da LastMsgId < LastNumber
                            Message = findneSL(DLQ,LastMsgId),
                                case (LastMsgId == maxNrSL(DLQ)) of 
                                        true -> Terminated = true;
                                        false -> Terminated = false
                                end;
                        false -> 
                            Message = "Nichtleere Dummy Nachricht",
                            Terminated = true
            end,
        	ClientManagerId ! {Message, LastMsgId, Terminated}
    end
.	 

%% -------------------------------------------
%% Kontrolliert ob Nachrichten aus der HBQ in die DLQ gepackt werden k�nnen, dh ob |HBQ| > Kapazit�t(DLQ)
checkIfEnoughMessages(HBQ, DLQCapacity) ->
	Length = lengthSL(HBQ),
        io:fwrite("CHECKIFENOUGHMESSAGES! L�nge HBQ: ~p\n",[Length]),
	Length > DLQCapacity/2
.

%% -------------------------------------------
%% L�sst Nachrichten von der HBQ in die DLQ �bertragen wenn zwischen beiden Queues keine L�cke ist, sonst f�llt er die L�cke mit einer
%% Fehlernachricht
transportToDLQ(HBQ, DLQ, DLQCapacity) ->
        
        %Abbruchbedingung f�r die Rekursion -> nur so lange �bertragen bis die HBQ length noch ok ist
        case lengthSL(HBQ) > DLQCapacity/2 of
            true ->
                LastKey = maxNrSL(DLQ),
                NewKey = LastKey+1,
                MinNrHBQ = minNrSL(HBQ),
                
                Diff = MinNrHBQ-NewKey,
                
                io:format("TRANSPORT DLQ DIFF: ~p  LASTKEY: ~p  NEWKEY ~p  MIN NR HBQ ~p\n",[Diff,LastKey,NewKey,MinNrHBQ]),
                case Diff == 0 of
                    true ->     %Kann �bertragen werden da DLQ leer und Erstes Elem in HBQ = 0
                                io:format("IN TRANSPORT ONCE\n"),
                                {NewHBQ,NewDLQ} = transportOnceFromHBQtoDLQ(HBQ,DLQ),
                                transportToDLQ(NewHBQ,NewDLQ,DLQCapacity);
                    
                    false ->    %Wenn eine L�cke enstanden ist, pushe Fehlernachricht in die DLQ mit der Nummer der letzten Nachricht
                                ModifiedMsg = lists:concat(["*****Fehlernachricht fuer Nachrichtennummer ",MinNrHBQ," bis ",NewKey," um ",timeMilliSecond]),
                                logging("server.log",ModifiedMsg),
                                ReadyDLQ = pushSL(DLQ, {MinNrHBQ,ModifiedMsg}),
                                transportToDLQ(HBQ,ReadyDLQ,DLQCapacity)
                end;
    
        false -> {HBQ,DLQ}
    
    end
    
.       

%%-------------------------------------------
%% Transport genau eine Nachricht von der HBQ in die DLQ und l�scht die kleinste aus der HBQ
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
