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

    global:register_name(NodeName,self()),
    {ok, ConfigListe} = file:consult(lists:concat(["4Ecken/",NodeName,".cfg"])),
    EdgeList = loadCfg(ConfigListe,EdgeList_temp),    
    
    {_True,Edge} = searchAKmG(EdgeList),
    {Weight, Neighbour, _EdgeState,EName} = Edge,
    NewEdgeList = changeEdgeState(EdgeList, Edge, branch),
    Level = 0,
    FindCount = 0,
    
    io:format("~p: Sending Connect to Neighbour ~p\n", [timeMilliSecond(),EName]),
    Neighbour ! {connect, Level, {Weight, self(), Neighbour,EName}},
    State = found,
    InBranch = nil, BestEdge = nil, BestWeight = nil, TestEdge = nil,
    ThisFragName = nil,
    
    loop(self(), Level, State, NewEdgeList, ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, FindCount),
    self()
.


loop(NodeName, NodeLevel, NodeState, EdgeList, ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, FindCount) ->
    %io:format("\nGRAPH:--------------------------------------------------------\n"),
    %io:format("~p: ~p received connect from Node ~p\n", [timeMilliSecond(),NodeName,Neighbour]),
    
        receive
            {connect, Level, Edge} ->
                {Weight, Neighbour, _self,NName} = Edge,
                io:format("~p: ~p received connect from Node ~p\n", [timeMilliSecond(),NodeName,NName]),
                case Level<NodeLevel of
                    true -> 
                        NewEdgeList = changeEdgeState(EdgeList, Edge, branch),
                        io:format("~p: Sending initiate to Neighbour ~p\n", [timeMilliSecond(),NName]),
                        Neighbour ! {initiate, NodeLevel, ThisFragName, NodeState, {Weight, NodeName, Neighbour,NName}},
                        case NodeState==find of
                            true -> NewFindCount = FindCount+1;
                            false-> NewFindCount = FindCount
                        end;
                    false ->
                        NewFindCount = FindCount,
                        NewEdgeList = EdgeList,
                        case (getEdgeState(EdgeList, Edge) == basic) of
                            true ->
                                NodeName ! {connect, Level, Edge};
                            false ->
                                io:format("~p: Sending initiate to Neighbour ~p\n", [timeMilliSecond(),NName]),
                                Neighbour ! {initiate, NodeLevel+1, Weight, find, {Weight, NodeName, Neighbour,NName}}
                        end
                    end,
                loop(NodeName, NodeLevel, NodeState, NewEdgeList, ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, NewFindCount);
            
            
            {initiate, Level, FragName, State, Edge} ->
                {_weight,_EdgeNeighbour,_self,NName} = Edge,
                io:format("~p: Me received initiate from Node ~p\n", [timeMilliSecond(),NName]),
                NewNodeLevel = Level,
                NewFragName = FragName,
                %NewNodeState = State,
                NewInBranch = Edge,
                NewBestWeight = ?INFINITY,
                NewBestEdge = nil,
                
                io:format("~p: ~p makes a new Fragment with ~p. FragName = ~p, FragLevel = ~p\n", [timeMilliSecond(), self(),NName, FragName, Level]),
                
                NewFindCount = sendinitiate(EdgeList, Edge, Level, FragName, State, NodeName, FindCount),
                
                
                case State == find of
                    true ->
                        %%Test Procedure
                        AKmG = searchAKmG(EdgeList),
                        {OK, AKmGEdge} = AKmG,
                        case OK  of
                            true ->
                                NewTestEdge = AKmGEdge,
                                {Weight, Neighbour, _edgeState,TEName} = NewTestEdge,
                                io:format("~p: Sending test to Neighbour ~p\n", [timeMilliSecond(),TEName]),
                                Neighbour ! {test, Level, FragName, {Weight, NodeName, Neighbour,TEName}},
                                NewNodeState = State;
                            false ->
                                NewTestEdge = nil,
                                NewNodeState = report_procedure(NewFindCount, NewTestEdge, State, NewBestWeight, NewInBranch, NodeName)
                        end;
                    false ->
                        NewNodeState = State,
                        NewTestEdge = TestEdge
                end,
        
                loop(NodeName, NewNodeLevel, NewNodeState, EdgeList, NewFragName, NewInBranch, NewBestEdge, NewBestWeight, NewTestEdge, NewFindCount);
        
            
           
            {test, Level, FragName, Edge} ->
                {Weight,Neighbour,_self,EName} = Edge,
                io:format("~p: Me received test from Node ~p\n", [timeMilliSecond(),EName]),
                %%aufwecken wenn er schläft
                %%wenn Level größer als NodeLevel dann warten...siehe unten
                ThisEdge = {Weight, NodeName, Neighbour,EName},
                case NodeLevel>=Level of
                    true ->
                        io:format("~p: TEST: Level von Me größer gleich Level von ~p: ~p >= ~p\n", [timeMilliSecond(),EName, NodeLevel, Level]),
                        case FragName == ThisFragName of
                            true -> 
                                io:format("~p: TEST: FragName ~p gleich von Me und ~p\n", [timeMilliSecond(), FragName, EName]),
                                %changeEdgeState for Edge: ThisEdge to Rejected!
                                case (getEdgeState(EdgeList, Edge) == basic) of
                                    true -> 
                                        io:format("~p: TEST: Basic-Edge zwischen Me und ~p\n", [timeMilliSecond(), EName]),
                                        NewEdgeList = changeEdgeState(EdgeList, Edge, rejected),
                                        case TestEdge == Edge of
                                            true -> 
                                                io:format("~p: TEST: Test-Edge ist gleich Edge ~p\n", [timeMilliSecond(), Edge]),
                                                %Test Procedure
                                                AKmG = searchAKmG(EdgeList),
                                                {OK, AKmGEdge} = AKmG,
                                                io:format("~p: AKmG von ~p: ~p\n", [timeMilliSecond(), NodeName,AKmG]),
                                                case OK  of
                                                    true ->
                                                        NewTestEdge = AKmGEdge,
                                                        {Weight, AKmGNeighbour, _self,EName} = NewTestEdge,
                                                        io:format("~p: Sending test to Neighbour ~p in TESTREAKTION\n", [timeMilliSecond(),AKmGNeighbour]),
                                                        AKmGNeighbour ! {test, Level, FragName, {Weight, NodeName, Neighbour,EName}},
                                                        NewNodeState = NodeState;
                                                    false ->
                                                        NewTestEdge = nil,
                                                        NewNodeState = report_procedure(FindCount, NewTestEdge, NodeState, BestWeight, InBranch, NodeName)
                                                end;
                                            false -> 
                                                io:format("~p: Sending reject to Neighbour ~p\n", [timeMilliSecond(),EName]),
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
                                NewNodeState = NodeState,
                                NewTestEdge = TestEdge,
                                NewEdgeList = EdgeList,
                                io:format("~p: Sending accept to Neighbour ~p\n", [timeMilliSecond(),EName]),
                                Neighbour ! {accept, ThisEdge}
                        end;
                    false ->    
                        NodeName ! {test, Level, FragName, Edge},
                        NewNodeState = NodeState,
                        NewTestEdge = TestEdge,
                        NewEdgeList = EdgeList
                end,
        
                io:format("~p: EDGELIST von Me am Ende der TESTREAKTION: ~p\n", [timeMilliSecond(), NewEdgeList]),
                loop(NodeName, NodeLevel, NewNodeState, NewEdgeList, ThisFragName, InBranch, BestEdge, BestWeight, NewTestEdge, FindCount);
                
        
            %%---------------------------------------------------------------------------
            %% TestNode muss mit übergeben werden und BestWeight und BestNode vorher gespeichert werden!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            {accept, Edge} ->
            {_, _, _,EName} = Edge,
            io:format("~p, Me received accept from Node ~p\n", [timeMilliSecond(), EName]),
                NewTestEdge = nil,
                {Weight, Neighbour, _self,_} = Edge,
                case (Weight < BestWeight) of
                    true -> 
                        NewBestEdge = {Weight, Neighbour, NodeName},
                        NewBestWeight = Weight;
                       
                    false ->
                        NewBestEdge = BestEdge,
                        NewBestWeight = BestWeight
                end,
                NewNodeState = report_procedure(FindCount, NewTestEdge, NodeState, NewBestWeight, InBranch, NodeName),
            
                loop(NodeName, NodeLevel, NewNodeState, EdgeList, ThisFragName, InBranch, NewBestEdge, NewBestWeight, NewTestEdge, FindCount);
            
            
            {reject, Edge} ->
                {_Weight, _Neighbour, _self,EName} = Edge,
                io:format("~p, Me received reject from Node ~p\n", [timeMilliSecond(), EName]),
                case getEdgeState(EdgeList, Edge) == basic of
                    true ->
                        io:format("~p, ~p marked as rejected in Node ~p in REJECT\n", [timeMilliSecond(), Edge, NodeName]),
                        NewEdgeList = changeEdgeState(EdgeList, Edge, rejected);
                        
                    false ->
                        NewEdgeList = EdgeList
                end,
                %%TESTPROCEDURE
                %vllt im true case oben?
                AKmG = searchAKmG(NewEdgeList),
                {OK, AKmGEdge} = AKmG,
                io:format("~p: AKmG von ~p: ~p\n", [timeMilliSecond(), self(),AKmG]),
                case OK  of
                    true ->
                        NewNodeState= NodeState,
                        NewTestEdge = AKmGEdge,
                        {Weight, TestNeighbour, _state,NTEName} = NewTestEdge,
                        io:format("~p: Sending test to Neighbour ~p\n", [timeMilliSecond(),NTEName]),
                        TestNeighbour ! {test, NodeLevel, ThisFragName, {Weight, NodeName, TestNeighbour,NTEName}};
                    false ->
                        NewTestEdge = nil,
                        NewNodeState = report_procedure(FindCount, NewTestEdge, NodeState, BestWeight, InBranch, NodeName)
                end,
                io:format("~p: EDGELIST von ~p am Ende der REJECT: ~p\n", [timeMilliSecond(), NodeName,NewEdgeList]),
                loop(NodeName, NodeLevel, NewNodeState, NewEdgeList, ThisFragName, InBranch, BestEdge, BestWeight, NewTestEdge, FindCount);
                
                        
                    
            {report, Weight, Edge} ->
            %% getBranches and send report over Branch-Edges
            %% if Branch == Core 
                {_EdgeWeight, Neighbour, _self,EdgeName} = Edge,
                {_, IBNeighbour, _,_} = InBranch,
                io:format("~p: ME received report from Node ~p, INBRANCH = ~p, FindCount = ~p, TestEdge = ~p, BestWeight = ~p, Weight = ~p\n", [timeMilliSecond(), EdgeName, InBranch, FindCount, TestEdge, BestWeight, Weight]),
                case IBNeighbour == Neighbour of
                    true ->
                        io:format("~p: INBRANCH = ~p\n", [timeMilliSecond(), InBranch]),
                        case NodeState == find of
                            true ->
                                io:format("~p: NodeState == find\n", [timeMilliSecond()]),
                                NewEdgeList = EdgeList,
                                %%warten!!!??????????????????????????????????????????????
                                NodeName ! {report, Weight, Edge};
                            false ->
                                case Weight>BestWeight of
                                    true -> 
                                        io:format("~p: NodeState = ~p, Weight:~p > BestWeight:~p\n", [timeMilliSecond(), NodeState, Weight, BestWeight]),
                                        %%changeroot procedure
                                        {BNWeight, BestEdgeNeighbour, _self,BEName} = BestEdge,
                                        case getEdgeState(EdgeList,BestEdge) == branch of
                                            true ->
                                                NewEdgeList = EdgeList,
                                                io:format("~p: Sending changeroot to Neighbour ~p\n", [timeMilliSecond(),BEName]),
                                                BestEdgeNeighbour ! {changeroot, {BNWeight, NodeName, BestEdgeNeighbour,BEName}};
                                            false ->
                                                io:format("~p: Sending Connect to Neighbour ~p\n", [timeMilliSecond(),BEName]),
                                                BestEdgeNeighbour ! {connect, NodeLevel, {BNWeight, NodeName, BestEdgeNeighbour,BEName}},
                                                NewEdgeList = changeEdgeState(EdgeList, BestEdge, branch)
                                        end;
                                    false -> 
                                        NewEdgeList = EdgeList,
                                        %nur wenn weight = INFINITY ist
                                        io:format("~p: Weight = ~p, BestWeight = ~p, Infinity = ~p\n", [timeMilliSecond(), Weight, BestWeight, ?INFINITY]),
                                        case Weight == BestWeight andalso BestWeight == ?INFINITY of
                                            true ->
                                                io:format("Algo ist fertig"),
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
                                io:format("~p: Weight:~p < BestWeight:~p\n", [timeMilliSecond(), Weight, BestWeight]),
                                NewBestWeight = Weight,
                                NewBestEdge = Edge;
                            false ->
                                NewBestWeight = BestWeight,
                                NewBestEdge = BestEdge
                        end,
                        case NewFindCount == 0 andalso TestEdge == nil of
                            true ->
                                NewNodeState = found,
                                {IBWeight, InNeighbour, _self,INName} = InBranch,
                                io:format("~p: Sending report to Neighbour ~p\n", [timeMilliSecond(),INName]),
                                InNeighbour ! {report, NewBestWeight, {IBWeight, NodeName, InNeighbour,INName}};
                            false ->
                                NewNodeState = NodeState
                        end
                end,
                loop(NodeName, NodeLevel, NewNodeState, NewEdgeList, ThisFragName, InBranch, NewBestEdge, NewBestWeight, TestEdge, NewFindCount);
        
            
            {changeroot, Edge} ->
                {_w, _Neighbour, _s,EName} = Edge,
                io:format("~p: Me received initiate from Node ~p\n", [timeMilliSecond(), EName]),
                {BNWeight, BestEdgeNeighbour, _self,_BEName} = BestEdge,
                case getEdgeState(EdgeList,BestEdge) == branch of
                    true ->
                        NewEdgeList = EdgeList,
                        io:format("~p: Sending changeroot to Neighbour ~p\n", [timeMilliSecond(),EName]),
                        BestEdgeNeighbour ! {changeroot, {BNWeight, NodeName, BestEdgeNeighbour,EName}};
                    false ->
                        io:format("~p: Sending Connect to Neighbour ~p\n", [timeMilliSecond(),EName]),
                        BestEdgeNeighbour ! {connect, NodeLevel, {BNWeight, NodeName, BestEdgeNeighbour,EName}},
                        NewEdgeList = changeEdgeState(EdgeList, BestEdge, branch)
                end,
                loop(NodeName, NodeLevel, NodeState,NewEdgeList,ThisFragName, InBranch, BestEdge, BestWeight, TestEdge, FindCount)
        end
    
.


sendinitiate([Head|EdgeList], Edge, Level, FragName, NodeState, NodeName, FindCount) ->
    {Weight, Neighbour, State,HName} = Head,
    {_Weight, EdgeNeighbour, _self,_EName} = Edge,
    case EdgeNeighbour == Neighbour of
        true ->
            NewFindCount = FindCount;
        false ->
            case State == branch of
                true ->
                    io:format("~p: Sending initiate to Neighbour ~p\n", [timeMilliSecond(),HName]),
                    Neighbour ! {initiate, Level, FragName, NodeState, {Weight, NodeName, Neighbour,HName}},
                        case NodeState == find of
                            true -> 
                                NewFindCount = FindCount+1;
                            false -> 
                                NewFindCount = FindCount
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
            {Weight1, _, _,_} = Edge,
            {Weight2, _, _,_} = Edge2,
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
    {_Weight, Neighbour, _self,_EName} = Edge,
    EdgeWithState = lists:keyfind(Neighbour, 2, EdgeList),
    
    {_weight,_neighbour, State,_} = EdgeWithState,
    State
.


test_procedure(EdgeList, FindCount, TestEdge, NodeState, BestWeight, InBranch, Level, FragName, NodeName) ->
    AKmG = searchAKmG(EdgeList),
    {OK, Edge} = AKmG,
    case OK  of
            true ->
                TestEdge = Edge,
                {Weight, Neighbour, _self,TEName} = TestEdge,
                Neighbour ! {test, Level, FragName, {Weight, NodeName, Neighbour,TEName}};
            false ->
                TestEdge = nil,
                NewNodeState = report_procedure(FindCount, TestEdge, NodeState, BestWeight, InBranch, NodeName)
    end
                
.

report_procedure(FindCount, TestEdge, NodeState, BestWeight, InBranch, NodeName) ->
    io:format("~p: REPORTPROCEDURE mit FindCount: ~p, TestEdge = ~p, NodeState= ~p, BestWeight= ~p, InBranch= ~p\n", [timeMilliSecond(),FindCount, TestEdge, NodeState, BestWeight, InBranch]),
    case (FindCount == 0 andalso TestEdge == nil) of       
        true -> 
            NewNodeState = found,
            {Weight, Neighbour, _self,InBranchName} = InBranch,
            io:format("~p: Sending report to Neighbour ~p with BestWeight ~p\n", [timeMilliSecond(),InBranchName, BestWeight]),
            Neighbour ! {report, BestWeight, {Weight, NodeName, Neighbour,InBranchName}};
        false ->
            NewNodeState = NodeState
    end,
    NewNodeState
.


 changeEdgeState(EdgeList, Edge, State) ->
    {Weight, Neighbour, _self,EName} = Edge,
    NewEdgeList = lists:keyreplace(Neighbour, 2, EdgeList, {Weight, Neighbour, State,EName}),
    NewEdgeList
.


loadCfg([Head|Tail],EdgeList) -> 
    {Weight,NodeName} = Head,
    
    {Name,FullNodeName} = NodeName,
    
    NodePid = ping_node(FullNodeName, Name),
   
    
    Edge = {Weight,NodePid,basic,Name},
    NewEdgeList = [Edge|EdgeList],
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
                    false -> 
                        io:format("A connection to the node with PID ~p and Name ~p could be established :). \n", [PID, Name]),
                        NewPID = PID
                end;
                    
        % The server-node failed to answer :(.
        pang -> 
            timer:sleep(1000),
            io:format("Ping for PID ~p went wrong. \n", [FullName]),
            NewPID = ping_node(FullName, Name)
    end,
    NewPID
.

%returnGraphAsString([Head|Tail]) ->
%
%;
%
%returnGraphAsString([]) ->
%    ""
%.


    
