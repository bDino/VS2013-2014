-module(client).
-author("Milena Dreier, Dino Buskulic").
-export([start/1]).
-compile(export_all).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0,delete_last/1,shuffle/1,reset_timer/3,type_is/1,to_String/1,bestimme_mis/2]).

start(ServerPID) ->
    {ok, ConfigListe} = file:consult("client.cfg"),
    {ok, Lifetime} = get_config_value(lifetime, ConfigListe),
    {ok, Servername} = get_config_value(servername, ConfigListe),
    {ok, Sendeintervall} = get_config_value(sendeintervall, ConfigListe),
    NumberList = [],
    Server = {ServerPID,Servername},
    timer:kill_after(Lifetime * 1000,self()),
    ClientPID = spawn(fun() -> startEditor(Server,0,NumberList) end)
.

startEditor(Server,SentMsg,NumberList) when (SentMsg < 5) ->
    ClientLog = io:format("client " + self() + ".log"),
    Server ! {getmsgid, self()},

    receive
        {nid, Number} -> logging(ClientLog, io:format("Received next Message Number: ~p\n",[Number])),
        saveNumber(Number,NumberList);
        
        Any -> logging(ClientLog,"FAILED TO RETRIEVE NEXT MSG NUMBER!"),
        startEditor(Server,SentMsg + 1,NumberList)
    end
.

%startEditor(sentMsg) when (sentMsg = 5)

    

%Speichert eine Nachrichtennummer in der Liste
saveNumber(Number,NumberList) ->
    newList = lists:append(Number,NumberList),
    newList.
    	
%Prüft ob die Nachrichtennummer in der List ist
checknumber(number) ->
    lists:member(number).