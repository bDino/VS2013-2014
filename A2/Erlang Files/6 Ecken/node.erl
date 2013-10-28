-module(node).
-author("Milena Dreier, Dino Buskulic").
-export([start/1]).
-define(INFINITY,134217728).
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

    EdgeList_temp = [],

    
    {ok, ConfigListe} = file:consult(lists:concat([NodeName,".cfg"])),
    EdgeList = loadCfg(ConfigListe,EdgeList_temp),    
    
    %ServerPID = spawn(fun() -> loop(self(),Lifetime,ClientmanagerPID,QueuemanagerPID,0) end),
    
    global:register_name(NodeName,self()),
    %logging("server.log","...Server started and registered with Servername ...\n"),
    
    Edge = searchAKmG(EdgeList),
    {Weight, Neighbour, _EdgeState} = Edge,
    NewEdgeList = changeEdgeState(EdgeList, Edge, branch),
    Level = 0,
    FindCount = 0,
    Neighbour ! {connect, Level, {Weight, NodeName, Neighbour}},
    State = found,
    InBranch = nil, BestEdge = nil, BestWeight = nil, TestEdge = nil,
    ThisFragName = nil,
    
    loop(self(), Level, State, NewEdgeList, ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, FindCount),
    self()
.


loop(NodeName, NodeLevel, NodeState, EdgeList, ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, FindCount) ->
    
        receive
            {connect, Level, Edge} ->
                {Weight, Neighbour, _self} = Edge,
                case NodeLevel>Level of
                    true -> 
                        NewEdgeList = changeEdgeState(EdgeList, Edge, branch),
                        Neighbour ! {initiate, NodeLevel, ThisFragName, NodeState, {Weight, NodeName, Neighbour}};
                    false ->
                        NewEdgeList = EdgeList,
                        case (getEdgeState(EdgeList, Edge)==basic) of
                            %true ->
                                %%gar nichts
                            false ->
                                Neighbour ! {initiate, NodeLevel+1, Weight, find, {Weight, NodeName, Neighbour}}
                                %%nicht sicher über die nächsten Schritte
                                %NewNodeLevel = NodeLevel+1,
                                %NewFragName = Weight;
                        end
                    end,
                
            
                loop(NodeName, NodeLevel, NodeState, NewEdgeList, ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, FindCount);
            
            
            {initiate, Level, FragName, State, Edge} ->
                NewNodeLevel = Level,
                NewFragName = FragName,
                %NewNodeState = State,
                {_weight, EdgeNeighbour, _self} = Edge,
                NewInBranch = EdgeNeighbour,
                BestWeight = ?INFINITY,
                NewFindCount = sendinitiate(EdgeList, Edge, Level, FragName, State, NodeName,FindCount),
                
                %%wenn State=find dann find-count raufsetzen
                
                case State == find of
                    true ->
                        %%Test Procedure
                        AKmG = searchAKmG(EdgeList),
                        {OK, AKmGEdge} = AKmG,
                        case OK  of
                            true ->
                                NewTestEdge = AKmGEdge,
                                {Weight, Neighbour, _self} = NewTestEdge,
                                Neighbour ! {test, Level, FragName, {Weight, NodeName, Neighbour}},
                                NewNodeState = State;
                            false ->
                                NewTestEdge = nil,
                                NewNodeState = report_procedure(NewFindCount, TestEdge, State, BestWeight, NewInBranch)
                        end;
                    false ->
                        NewNodeState = State,
                        NewTestEdge = TestEdge
                end,
        
                loop(NodeName, NewNodeLevel, NewNodeState, EdgeList, NewFragName, NewInBranch, BestEdge, BestWeight, NewTestEdge, NewFindCount);
        
            
           
            {test, Level, FragName, Edge} ->
                %%aufwecken wenn er schläft
                %%wenn Level größer als NodeLevel dann warten...siehe unten
                {Weight, Neighbour, _self} = Edge,
                ThisEdge = {Weight, NodeName, Neighbour},
                case FragName == ThisFragName of
                    true ->  
                        %changeEdgeState for Edge: ThisEdge to Rejected!
                        case (getEdgeState(EdgeList, Edge) == basic) of
                            true -> 
                                    NewEdgeList = changeEdgeState(EdgeList, Edge, rejected),
                                    case TestEdge == Edge of
                                        true -> 
                                            %Test Procedure
                                            AKmG = searchAKmG(EdgeList),
                                            {OK, AKmGEdge} = AKmG,
                                            case OK  of
                                                true ->
                                                    NewTestEdge = AKmGEdge,
                                                    {Weight, Neighbour, _self} = NewTestEdge,
                                                    Neighbour ! {test, Level, FragName, {Weight, NodeName, Neighbour}},
                                                    NewNodeState = NodeState;
                                                false ->
                                                    NewTestEdge = nil,
                                                    NewNodeState = report_procedure(FindCount, NewTestEdge, NodeState, BestWeight, InBranch)
                                            end;
                                        false -> 
                                            Neighbour ! {reject, ThisEdge},
                                            NewNodeState = NodeState,
                                            NewTestEdge = TestEdge
                                    end;
                            false -> 
                                    NewEdgeList = EdgeList,
                                    NewNodeState = NodeState,
                                    NewTestEdge = TestEdge
                        end;
                        
                    false ->  
                        NewEdgeList = EdgeList,
                        case NodeLevel >= Level of
                            true ->     Neighbour ! {accept, ThisEdge};
                            false ->    NodeName ! {test, Level, FragName, Edge}
                        end,
                        NewNodeState = NodeState,
                        NewTestEdge = TestEdge
                end,
                loop(NodeName, NodeLevel, NewNodeState, NewEdgeList, ThisFragName, InBranch, BestEdge, BestWeight, NewTestEdge, FindCount);
                
        
            %%---------------------------------------------------------------------------
            %% TestNode muss mit übergeben werden und BestWeight und BestNode vorher gespeichert werden!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            {accept, Edge} ->
                NewTestEdge = nil,
                {Weight, Neighbour, _self} = Edge,
                case (Weight < BestWeight) of
                    true -> 
                        NewBestEdge = {Weight, Neighbour, NodeName},
                        NewBestWeight = Weight;
                       
                    false ->
                        NewBestEdge = BestEdge,
                        NewBestWeight = BestWeight
                end,
                NewNodeState = report_procedure(FindCount, NewTestEdge, NodeState, NewBestWeight, InBranch),
            
                loop(NodeName, NodeLevel, NewNodeState, EdgeList, ThisFragName, InBranch, NewBestEdge, NewBestWeight, NewTestEdge, FindCount);
            
                        
                    
            {report, Weight, Edge} ->
            %% getBranches and send report over Branch-Edges
            %% if Branch == Core 
                {Weight, Neighbour, _self} = Edge,
                case InBranch == Neighbour of
                    true ->
                        case NodeState == find of
                            true ->
                                NewEdgeList = EdgeList,
                                %%warten!!!??????????????????????????????????????????????
                                NodeName ! {report, Weight, Edge};
                            false ->
                                case Weight>BestWeight of
                                    true -> 
                                        %%changeroot procedure
                                        {BNWeight, BestEdgeNeighbour, _self} = BestEdge,
                                        case getEdgeState(EdgeList,BestEdge) == branch of
                                            true ->
                                                NewEdgeList = EdgeList,
                                                BestEdgeNeighbour ! {changeroot, {BNWeight, NodeName, BestEdgeNeighbour}};
                                            false ->
                                                BestEdgeNeighbour ! {connect, NodeLevel, {BNWeight, NodeName, BestEdgeNeighbour}},
                                                NewEdgeList = changeEdgeState(EdgeList, BestEdge, branch)
                                        end;
                                    false -> 
                                        NewEdgeList = EdgeList,
                                        %nur wenn weight = INFINITY ist
                                        case Weight == BestWeight andalso BestWeight == ?INFINITY of
                                            true ->
                                                exit("Algo ist durch")
                                                %%Algo ist fertig!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!            EXIT EXIT EXIT EXIT
                                        end
                                end 
                        end,
                        NewFindCount = FindCount,
                        NewBestWeight = BestWeight,
                        NewBestEdge = BestEdge,
                        NewNodeState = NodeState;
            
                    false ->
                        NewEdgeList = EdgeList,
                        NewFindCount = FindCount - 1,
                        case Weight<BestWeight of
                            true ->
                                NewBestWeight = Weight,
                                NewBestEdge = {Weight, Neighbour, NodeName};
                            false ->
                                NewBestWeight = BestWeight,
                                NewBestEdge = BestEdge
                        end,
                        case NewFindCount == 0 andalso TestEdge == nil of
                            true ->
                                NewNodeState = found,
                                {IBWeight, InNeighbour, _self} = InBranch,
                                InNeighbour ! {report, NewBestWeight, {IBWeight, NodeName, InNeighbour}};
                            false ->
                                NewNodeState = NodeState
                        end
                end,
                loop(NodeName, NodeLevel, NewNodeState, NewEdgeList, ThisFragName, InBranch, NewBestEdge, NewBestWeight, TestEdge, NewFindCount);
        
            
            {changeroot, _Edge} ->
                case getEdgeState(EdgeList, BestEdge)== branch of
                    true -> 
                        {Weight, Neighbour, _self} = BestEdge,
                        Neighbour ! {changeroot, {Weight, NodeName, Neighbour}}
                end,
                    
                loop(NodeName, NodeLevel, NodeState,EdgeList,ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, FindCount)
        end
    
.


sendinitiate([Head|EdgeList], Edge, Level, FragName, NodeState, NodeName, FindCount) ->
    {Weight, Neighbour, State} = Head,
    {_Weight, EdgeNeighbour, _self} = Edge,
    case EdgeNeighbour == Neighbour of
        false ->
            case State == branch of
                true ->
                    Neighbour ! {initiate, Level, FragName, {Weight, NodeName, Neighbour}},
                        case NodeState == find of
                            true -> NewFindCount = FindCount+1;
                            false -> NewFindCount = FindCount
                        end;
                false ->
                    NewFindCount = FindCount
            end
    end,
    sendinitiate(EdgeList, Edge, Level, FragName, NodeState, NodeName, NewFindCount)    
;

sendinitiate([], _Edge, _Level, _FragName, _NodeState, _NodeName, FindCount) ->
    FindCount
.

searchAKmG([Edge|Tail]) ->
    EdgeList = [Edge|Tail],
    case getEdgeState(EdgeList,Edge) == basic of
        true ->
            searchAKmG(Tail, Edge);
        false ->
            searchAKmG(Tail)
    end
;

searchAKmG([]) ->
    {false, {}}
    %io:fwrite("Fehler: keine neue Basic Edge in Liste\n")
    %%Fehlernachricht!!!!!!
    %%keine neue Basic Edge in der Liste
.

searchAKmG([Edge2|Tail], Edge) ->
    List = [Edge2|Tail],
    case getEdgeState(List,Edge2) == basic of
        true ->
            {Weight1, _, _} = Edge,
            {Weight2, _, _} = Edge2,
            case (Weight2<Weight1) of
                true -> searchAKmG(Tail, Edge2);
                false -> searchAKmG(Tail, Edge)
            end;
        false ->
            searchAKmG(Tail, Edge)
    end
;

searchAKmG([], Edge) ->
    {true, Edge}
.


getEdgeState(EdgeList, Edge) ->
    {_Weight, Neighbour, _self} = Edge,
    EdgeWithState = lists:keyfind(Neighbour, 2, EdgeList),
    {_weight,_neighbour, State} = EdgeWithState,
    State
.


test_procedure(EdgeList, FindCount, TestEdge, NodeState, BestWeight, InBranch, Level, FragName, NodeName) ->
    AKmG = searchAKmG(EdgeList),
    {OK, Edge} = AKmG,
    case OK  of
            true ->
                TestEdge = Edge,
                {Weight, Neighbour, _self} = TestEdge,
                Neighbour ! {test, Level, FragName, {Weight, NodeName, Neighbour}};
            false ->
                TestEdge = nil,
                NewNodeState = report_procedure(FindCount, TestEdge, NodeState, BestWeight, InBranch)
    end
                
.

report_procedure(FindCount, TestEdge, NodeState, BestWeight, InBranch) ->
    case (FindCount == 0 andalso TestEdge == nil) of       
        true -> 
            NewNodeState = found,
            InBranch ! {report, BestWeight};
        false ->
            NewNodeState = NodeState
    end,
    NewNodeState
.


 changeEdgeState(EdgeList, Edge, State) ->
    {Weight, Neighbour, _self} = Edge,
    NewEdgeList = lists:keyreplace(Neighbour, 2, EdgeList, {Weight, Neighbour, State}),
    NewEdgeList
.


loadCfg([Head|Tail],EdgeList) -> 
    {Weight,NodeName} = Head,
    
    {Name,FullNodeName} = NodeName,
    
    NodePid = ping_node(FullNodeName, Name),
   
    
    Edge = {Weight,NodePid,basic},
    NewEdgeList = lists:append(Edge,EdgeList),
    loadCfg(Tail,NewEdgeList)
;

loadCfg([],EdgeList) -> EdgeList.



ping_node(FullName, Name) ->
     %Verbindungsaufbau zum Nachbarn
    case net_adm:ping(FullName) of
         %We received an answer from the node.
        pong ->
            
            PID = global:whereis_name(Name),
                
                case PID == undefined of
                
                    true -> 
                        timer:sleep(1000),
                        NewPID = ping_node(FullName,Name);
                        %io:format("The PID For the Node ~p could not be retrieved!\n",[Name]);
                    false -> 
                        io:format("A connection to the node with PID ~p and Name ~p could be established :). \n", [PID, Name]),
                        NewPID = PID
                end;
                    
        % The server-node failed to answer :(.
        pang -> 
            timer:sleep(1000),
            io:format("Ping for PID ~p went wrong. \n", [FullName]),
            PID = ping_node(FullName, Name)
    end,
    PID
.


    