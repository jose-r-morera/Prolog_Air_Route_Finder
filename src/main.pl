% Air Routes Finder in Prolog
%
% Inteligencia Artificial - Grado en Ingeniería Informática, ULL
% José Ramón Morera Campos
% alu0101471846@ull.edu.es
% 19/12/2023

% AIR ROUTES FINDER

% Given an Origin Airport and a Destination Airport, we search the flights between them with the shortest duration, considering connection flights.

% Import data
:- consult('data/flights.pl'). 
:- consult('data/airports.pl'). 

% Arcs: nodes that are connected
arc([Origin,FlightID,Cost],Destination) :- flight(FlightID,Origin,Destination,_,Cost,_).

% Calculate the distance between two coordinates
haversine_distance(Lat1, Lon1, Lat2, Lon2, Distance) :-
    R is 6371, % Earth radius in kilometers
    DLat is (Lat2 - Lat1) * pi / 180,
    DLon is (Lon2 - Lon1) * pi / 180,
    A is sin(DLat / 2) * sin(DLat / 2) + cos(Lat1 * pi / 180) * cos(Lat2 * pi / 180) * sin(DLon / 2) * sin(DLon / 2),
    C is 2 * atan2(sqrt(A), sqrt(1 - A)),
    Distance is R * C.

% Calculate the heuristic of a node (an airport)
h(N,Hvalue,Target) :- N = Target,!, Hvalue is 0; 
	airport(_,_,_,N,_,La1,Lo1), airport(_,_,_,Target,_,La2,Lo2),
	haversine_distance(La1, Lo1, La2, Lo2, Hvalue). % Usamos la distancia con el último nodo

% F(x): compare two nodes by their heuristic h(x), and their cumulative cost g(x).
less_than([Node1,_,Cost1],[Node2,_,Cost2],Target) :-
    h(Node1,Hvalue1,Target), h(Node2,Hvalue2,Target),
    F1 is Cost1+Hvalue1, F2 is Cost2+Hvalue2,
    F1 =< F2.

% Eliminate one elment from a list
% remove(Elemento, Lista, Resultado)
remove(_, [], []).
remove(R, [R|T], T).
remove(R, [H|T], [H|T2]) :- H \= R, remove(R, T, T2).

% Add to the nodes pending to check.
% add_to_frontier(A, B, C, D)
% A: Nodes added
% B: Frontier
% C: Result = A+B
% D: Target node, used to determine the addition order to the frontier
add_to_frontier([],X,X,_).                            % Stop
% Airport not on the list
add_to_frontier([[Airport,FID,Cost]|X],Frontier,New,Target) :- not(member([Airport,_,_],Frontier)), 
                                                insert([Airport,FID,Cost],Frontier,Result,Target),   
											    add_to_frontier(X,Result,New,Target).               % Recursive call
% Airport is on the list, but current flight gets a better (shorter) time
add_to_frontier([[Airport,FID,Cost]|X],Frontier,New,Target) :- member([Airport,OldFlightID,OldCost],Frontier),
                                                OldCost > Cost,
                                                remove([Airport,OldFlightID,OldCost], Frontier, NewFrontier),
                                                insert([Airport,FID,Cost],NewFrontier,Result,Target),   
											    add_to_frontier(X,Result,New,Target).    % Recursive call
add_to_frontier([[Airport,_,_]|X],Frontier,New,Target):- member([Airport,_,_],Frontier), add_to_frontier(X,Frontier,New,Target).

% Insert in the list, first the nodes with lower cost.
% insert(A, B, C, D)
% A: Element to add
% B: List where it is added
% C: Result = A+B
% D: Target node, used to determine the addition order
insert(X,[Y|T],[Y|NT],Target):- less_than(Y,X,Target),insert(X,T,NT,Target). % Y is inserted first. The X node has a higher cost, recursive node.
insert(X,[Y|T],[X,Y|T],Target):- less_than(X,Y,Target). % Insert first X
insert(X,[],[X],_).                                     % Base case, in an empty list, X is inserted

% Check whether flight A starts after flight B
after(A, B):- flight(A, _, _, TimeA, _, _), flight(B, _, _, TimeB, _, _), TimeA @> TimeB.
after(_, 0). % Save code 0 for the initial iteration

% A* search
% a_star(A, B, C)
% A: Frontier nodes list
% B: Target node
% C: List of nodes travelled
a_star([[Target, FlightID, Cost] | _],Target,[Target, FlightID, Cost]).
a_star([[Airport,CurrentID,CurrentCost] | FRest],Target,Route) :-
	% Todos los nodos acesibles desde el actual (y el vuelo con el que se accede)
	findall([X,FlightID, CumulativeCost], (arc([Airport,FlightID,Cost],X), CumulativeCost is Cost+CurrentCost, after(FlightID, CurrentID)), NodeList), 
	add_to_frontier(NodeList,FRest,Result,Target),                    	% Add pairs (node, flight) to the list
	a_star(Result,Target,Found),
    append([Airport, CurrentID, CurrentCost], Found, Route). % Add to the history list

% Function to format the result
pretty_route([Airport, _, _| X], Result) :- 
    pretty_route_aux(X, Rest),
    format(string(Result),"\n\nStarting airport: ~w\n~w", [Airport, Rest]).
pretty_route_aux([Airport, Flight, Duration| X], Result) :- 
    pretty_route_aux(X, Rest),
    format(string(Result),"Airport: ~w, FlightID: ~d, Accumulated time: ~d.\n~w", [Airport, Flight, Duration, Rest]).
pretty_route_aux([], ""). % Base case

% FMain function: search of a route between two airports
search :- 
    write('Enter the origin airport code: \n'), read(Origin),
    write('Enter the destination airport code: \n'), read(Destination),
    a_star([[Origin, 0, 0]|[]], Destination, Route),
    pretty_route(Route, PrettyRoute),
    write('Shortest route from '), write(Origin), write(' to '), write(Destination), write(': '), write(PrettyRoute), nl.