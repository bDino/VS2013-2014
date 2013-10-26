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
                {Weight, Neighbour, _self} = Edge,
                case NodeLevel>Level of
                    true -> 
                        NewEdgeList = changeEdgeState(EdgeList, Edge, branch),
                        Neighbour ! {initiate, NodeLevel, ThisFragName, NodeState, {Weight, NodeName, Neighbour};
                    false ->
                        NewEdgeList = EdgeList,
                        case (getEdgeState(EdgeList, Edge)==basic) of
                            true ->
                                %%gar nichts
                            false ->
                                Neighbour ! {initiate, NodeLevel+1, Weight, find, {Weight, NodeName, Neighbour}
                                %%nicht sicher über die nächsten Schritte
                                %NewNodeLevel = NodeLevel+1,
                                %NewFragName = Weight;
                        end
                    end
                
            
                loop(NodeName, NodeLevel, NodeState, NewEdgeListe, ThisFragName);
            
            
            {initiate, Level, FragName, State, Edge} ->
                NewNodeLevel = Level,
                NewFragName = FragName,
                NewNodeState = State,
                {Weight, Neighbour, _self} = Edge,
                InBranch = Neighbour,
                %%einkommende Kante speichern (Edge)
                sendInitiate(EdgeList, Edge),
                %%wenn State=find dann find-count raufsetzen
                
                case State == find of
                    true ->
                        test_procedure(EdgeList)
                end,
        
                loop(NodeName, NewNodeLevel, NewNodeState, EdgeList, NewFragName);
        
            
           
            {test, Level, FragName, Edge} ->
                %%aufwecken wenn er schläft
                %%wenn Level größer als NodeLevel dann warten...siehe unten
                {Weight, Neighbour, _self} = Edge,
                ThisEdge = {Weight, NodeName, Neighbour},
                case FragName == ThisFragName of
                    true ->  
                        %changeEdgeState for Edge: ThisEdge to Rejected!
                        case (getEdgeState(EdgeList, Edge) == basic) of
                            true -> NewEdgeList = changeEdgeState(EdgeList, Edge, rejected),
                                    case TestNode == Neighbour of
                                        true -> test_procedure(EdgeList);
                                        false -> Neighbour ! {reject, ThisEdge}
                                    end;
                            false -> NewEdgeList = EdgeList
                        end;
                        
                    false ->  
                        NewEdgeList = EdgeList,
                        case NodeLevel >= Level of
                            true ->     Neighbour ! {accept, ThisEdge};
                            false ->    %%Warten bis NodeLevel sich verändert hat
                        end
                end,
                loop(NodeName, NodeLevel, NodeState, NewEdgeList, ThisFragName);
                
        
            %%---------------------------------------------------------------------------
            %% TestNode muss mit übergeben werden und BestWeight und BestNode vorher gespeichert werden!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            {accept, Edge} ->
                NewTestNode = nil,
                {Weight, Neighbour, _self} = Edge,
                case (Weight < BestWeight) of
                    true -> 
                        NewBestNode = Neighbour,
                        NewBestWeight = Weight;
                       
                    false ->
                        NewBestNode = BestNode,
                        NewBestWeight = BestWeight
                end,
                case (FindCount == 0) of       
                    true -> 
                        NewNodeState = found,
                        InBranch ! {report, NewBestWeight};
                    false ->
                        NewNodeState = NodeState
                    end,
            
                loop(NodeName, NodeLevel, NewNodeState, EdgeList, ThisFragName);
            
                        
                    
            {report, Weight, Edge} ->
            %% getBranches and send report over Branch-Edges
            %% if Branch == Core 
                {Weight, Neighbour, _self} = Edge,
                case InBranch = Edge of
                    true ->
                        case NodeState == find of
                            true ->
                                NewEdgeList = EdgeList,
                                %%warten;
                            false ->
                                case Weight>BestWeight of
                                    true -> 
                                        %%changeroot procedure
                                        case (getEdgeState(BestNode) == branch) of
                                            {BNWeight, BestNodeNeighbour, _self} = BestNode,
                                            true ->
                                                NewEdgeList = EdgeList,
                                                BestNodeNeighbour ! {changeroot, {BNWeight, NodeName, BestNodeNeighbour}};
                                            false ->
                                                BestNodeNeighbour ! {connect, NodeLevel, {BNWeight, NodeName, BestNodeNeighbour}},
                                                NewEdgeList = changeEdgeState(EdgeList, BestNode, branch)
                                        end;
                                    false -> 
                                        NewEdgeList = EdgeList,
                                        case (Weight == BestWeight == ) of
                                            true ->
                                                exit
                                                %%Algo ist fertig!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!            EXIT EXIT EXIT EXIT
                                        end
                                end 
                        end;
            
                    false ->
                        NewEdgeList = EdgeList,
                        NewFindCount = FindCound - 1,
                        case Weight<BestWeight of
                            true ->
                                NewBestWeight = Weight,
                                NewBestNode = Neighbour;
                            false ->
                                NewBestWeight = BestWeight,
                                NewBestNode = BestNode
                        end,
                        case FindCount == 0 andalso TestNode == nil of
                            true ->
                                NewNodeState = found,
                                {IBWeight, InNeighbour, _self} = InBranch,
                                InNeighbour ! {report, NewBestWeight, {IBWeight, NodeName, InNeighbour}};
                            false ->
                                NewNodeState = NodeState
                        end
                end,
                loop(NodeName, NodeLevel, NewNodeState, NewEdgeList, ThisFragName);
        
            {changeroot, Edge} ->
            %% sende Changeroot weiter nach außen(an alle außer an die von denen es herkommt???)
                loop(NodeName, Level, State)
        end
    
.


searchAKmG(EdgeList) ->
    {Edge|Tail} = EdgeList,
    case getEdgeState(Edge) == basic of
        true ->
            searchAKmG(Tail, Edge);
        false ->
            searchAKmG(Tail)
    end
.

searchAKmG([]) ->
    %%Fehlernachricht!!!!!!
    %%keine neue Basic Edge in der Liste
.

searchAKmG(List, Edge) ->
    {Edge2|Tail} = List,
    case getEdgeState(Edge2) == basic of
        true ->
            {Weight1, _, _} = Edge,
            {Weight2, _, _} = Edge2,
            case (Weight2<Weight1) of
                true -> searchAKmG(Tail, Edge2);
                false -> seachAKmG(Tail, Edge)
            end
        false ->
            searchAKmG(Tail, Edge)
    end
.

searchAKmG([], Edge) ->
    Edge
.


getEdgeState(EdgeList, Edge) ->
    {Weight, Neighbour, _self} = Edge,
    EdgeWithState = orddict:fetch(Neighbour, Edge),
    {_weight,_neighbour, _self, State} = EdgeWithState,
    State
.







    