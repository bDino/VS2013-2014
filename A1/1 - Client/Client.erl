-module(client).
-author("Milena Dreier, Dino Buskulic").
-export([start/1]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0,delete_last/1,shuffle/1,reset_timer/3,type_is/1,to_String/1,bestimme_mis/2]).

start(ServerPID) ->
    {ok, ConfigListe} = file:consult("client.cfg"),
    {ok, Lifetime} = get_config_value(lifetime, ConfigListe),
    {ok, Servername} = get_config_value(servername, ConfigListe),
    {ok, Sendeintervall} = get_config_value(sendeintervall, ConfigListe),
    {ok, Clients} = get_config_value(clients,ConfigListe),
    
    FirstTimeout = 2000 + random:uniform(2000),
    NumberList = [],
    Server = {ServerPID,Servername},
    
    spawnAllClients(Clients,Server,NumberList,FirstTimeout,Lifetime)
.

spawnAllClients(ClientNumber,Server,NumberList,FirstTimeout,ClientLifetime) when (ClientNumber > 0) ->
    ClientPID = spawn(fun() -> startEditor(io:format("Client ~p.log",[ClientNumber]),Server,0,NumberList,FirstTimeout) end),
    timer:kill_after(ClientLifetime * 1000,ClientPID),
    spawnAllClients(ClientNumber - 1,Server,NumberList,FirstTimeout,ClientLifetime)
.

startEditor(ClientLog,Server,SentMsg,NumberList,FirstTimeout) ->
    Server ! {getmsgid, self()},
        receive
            {nid, Number} -> 
                logging(ClientLog, io:format("Received next Message Number: ~p\n",[Number])),
                NewList = lists:append(Number,NumberList),

                Server ! {dropmessage, {io:format("~pte Nachricht C out: ~p.",[Number,now()])}},
        
                    case (sentMsg = 5) of 
                        true ->
                            logging(ClientLog,io:format("Forgott to send Message Number: ~p\n",[Number])),
                            timer:sleep(2000 + random:uniform(3000)),
            
                            startReader(0,Server,NumberList,ClientLog);
                        false ->
                            startEditor(ClientLog,Server,SentMsg + 1,NewList,FirstTimeout)
                    end;
    
            Any -> logging(ClientLog,"Failed to retrieve next message number!\n"),
                startEditor(ClientLog,Server,SentMsg + 1,NumberList,FirstTimeout)
        end
.


startReader(NumberOfMessages,Server,NumberList,ClientLog) when (NumberOfMessages < 5) ->
    Server ! {getmessages, self()},
    
    receive
        {reply,Number,Nachricht,Terminated} ->
            case (lists:member(Number,NumberList)) of 
                true -> logging(ClientLog,io:format("~p ******* C in: ~p\n",[Nachricht,now()]));
                false -> logging(ClientLog,io:format("~p C in: ~p\n",[Number,Nachricht]))
            end,
            
            case (Terminated = true) of
                false -> startReader(NumberOfMessages,Server,NumberList,ClientLog)
            end
    end
.