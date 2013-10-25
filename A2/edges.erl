-module(edges).
-author("Milena Dreier, Dino Buskulic").
-export([start/0]).
-import(werkzeug,[get_config_value/2,logging/2,logstop/0,timeMilliSecond/0]).


%% -------------------------------------------
% Server
%% -------------------------------------------
%%
%% -------------------------------------------
%% startet den Server
%% liest die Config-Datei aus und startet die Prozesse Queuemanager und Clientmanager
%
start() ->

    EdgeList = emptySL(),
    
    %Speichern der Configparameter
    %Wie geht es die Daten aus der Datei auszulesen und in Orddict zu sichern?
    {ok, Configlist} = file:consult("node.cfg"),
    {ok, Servername} = get_config_value(servername,Configlist),
    %Configuration fertig
    
    EdgeList
    
.

searchAKmG(EdgeList) ->

    %findNeSL muss umgebaut werden und die Kante mit dem kleinsten Gewicht und dem Status basic ausgeben
    Edge = findNeSL(EdgeList),
    Edge

.
    