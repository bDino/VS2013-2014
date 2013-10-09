-module(client).
-author("Milena Dreier, Dino Buskulic").
-export([start/0]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0,delete_last/1,shuffle/1,reset_timer/3,type_is/1,to_String/1,bestimme_mis/2]).

start() ->
    {ok, ConfigListe} = file:consult("client.cfg"),
    {ok, Lifetime} = get_config_value(lifetime, ConfigListe),
    {ok, Servername} = get_config_value(servername, ConfigListe),
    {ok, Sendeintervall} = get_config_value(sendeintervall, ConfigListe),
    {ok, Clients} = get_config_value(clients,ConfigListe),
    
    FirstTimeout = 2000 + random:uniform(2000),
    NumberList = [],
    
    {Name,ServerNode} = Servername,
    
    
    case net_adm:ping(ServerNode) of
         %We received an answer from the server-node.
        pong ->
            
            ServerPID = global:whereis_name(Name),
            io:format("A connection to the server with PID ~p and Name ~p could be established :). \n", [ServerPID, Name]),
            
            % Start the number of clients specified in the config file.
            spawnAllClients(Clients,ServerPID,NumberList,FirstTimeout,Lifetime);

        % The server-node failed to answer :(.
        pang -> io:format("A connection to the server with PID ~p could not be established :(. \n", [Servername])
    end
.    
    

spawnAllClients(ClientNumber,Server,NumberList,FirstTimeout,ClientLifetime) when (ClientNumber > 1) ->
    ClientLog = lists:concat(["Client ",ClientNumber,".log"]),
    ClientPID = spawn(fun() -> startEditor(ClientLog,ClientNumber,Server,0,NumberList,FirstTimeout) end),
    %timer:kill_after(ClientLifetime * 1000,ClientPID),
    spawnAllClients(ClientNumber - 1,Server,NumberList,FirstTimeout,ClientLifetime);
 
spawnAllClients(1,Server,NumberList,FirstTimeout,ClientLifetime) ->
    ClientPID = spawn(fun() -> startEditor("Client 1.log",1,Server,0,NumberList,FirstTimeout) end),
    timer:kill_after(ClientLifetime * 1000,ClientPID)   
.

startEditor(ClientLog,ClientNumber,Server,SentMsg,NumberList,FirstTimeout) ->
    io:fwrite("EDITOR with log ~p started\nSend To Server ~p\n",[ClientLog,Server]),
    Server ! {getmsgid, self()},        
        receive
            {nnr, Number} -> 
            
                logging(ClientLog, lists:concat(["Received next Message Number: ",Number,"\n"])),
                NewList = [Number|NumberList],
        
                    case (SentMsg == 5) of 
                        true ->
                            logging(ClientLog,lists:concat(["Forgott to send Message Number: ",Number,"\n"])),
                            SleepTime = 2000 + random:uniform(3000),
                            logging(ClientLog,lists:concat(["Set Client to Sleep: ",SleepTime,"\n"])),
                            timer:sleep(SleepTime),
                            
                            startReader(0,Server,NumberList,ClientLog,FirstTimeout,ClientNumber);
                        false ->
                            Message = lists:concat(["Client : ",ClientNumber,".Nachricht :", Number ,"te Nachricht C out: ",timeMilliSecond(),"\n"]),
                            Server ! {dropmessage, {Message, Number}},
                            startEditor(ClientLog,ClientNumber,Server,SentMsg + 1,NewList,FirstTimeout)
                    end;
    
            Any -> logging(ClientLog,"Failed to retrieve next message number!\n"),
                startEditor(ClientLog,ClientNumber,Server,SentMsg + 1,NumberList,FirstTimeout)
        end
.


startReader(NumberOfMessages,Server,NumberList,ClientLog,FirstTimeout,ClientNumber) when (NumberOfMessages < 5) ->
    logging(ClientLog,lists:concat(["Started Reader Mod: ",timeMilliSecond(),"\n"])),
    Server ! {getmessages, self()},
    
    receive
        {reply,Number,Nachricht,Terminated} ->
            case (lists:member(Number,NumberList)) of 
                true -> logging(ClientLog,lists:concat([Nachricht,"******* C in: ",timeMilliSecond(),"\n"]));
                false -> logging(ClientLog,lists:concat([Nachricht," C in: ",timeMilliSecond(),"\n"]))
            end,
            
            case (Terminated == false) of
                true -> startReader(NumberOfMessages,Server,NumberList,ClientLog,FirstTimeout,ClientNumber);
                false -> startEditor(ClientLog,ClientNumber,Server,0,NumberList,FirstTimeout)
            end
    end
.