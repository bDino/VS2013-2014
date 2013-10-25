-module(node).
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
start(NodeName) ->
    
    EdgeList = edges:start(),

    %ServerPID = spawn(fun() -> loop(self(),Lifetime,ClientmanagerPID,QueuemanagerPID,0) end),
    
    global:register_name(NodeName,self()),
    %logging("server.log","...Server started and registered with Servername ...\n"),
    
    {Weight, Neighbour, EdgeState} = edges:searchAKmG(EdgeList),
    Level = 0,
    NewEdgeState = branch,
    Edge = {Weight, NodeName, Neighbour, NewEdgeState},
    Neighbour ! {connect, Level, Edge},
    State = found,
    
    loop(NodeName, Level, State, EdgeList),
    self()
.


loop(NodeName, NodeLevel, NodeState, EdgeList, ThisFragName) ->
    
        receive
            {connect, Level, Edge} ->
                loop(NodeName, Level, State);
            
            {initiate, Level, FragName, NodeState, Edge} ->
                {Weight, Neighbour, EdgeState} = edges:searcgAKmG(EdgeList),
                Neighbour ! {Test, NodeLevel, ThisFragName, {Weight, NodeName, Neighbour}},
        
                receive
                    {accept, Edge} ->
                        
                    {reject, Edge} ->
                end;
        
                loop(NodeName, Level, State);
        
            {test, Level, FragName, Edge} ->
                {Weight, Neighbour, _self} = Edge,
                ThisEdge = {Weight, NodeName, Neighbour},
                case FragName == ThisFragName of
                    true ->    
                        Neighbour ! {reject, ThisEdge};
                    false ->    
                        case NodeLevel >= Level of
                            true ->     Neighbour ! {accept, ThisEdge};
                            false ->    %%Warten bis NodeLevel sich verändert hat
                
        
            {report, Weight, Edge} ->
                loop(NodeName, Level, State);
        
            {changeroot, Edge} ->
                loop(NodeName, Level, State)
        end
    
.