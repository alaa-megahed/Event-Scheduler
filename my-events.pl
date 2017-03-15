% =============================
% The Structure of the Schedule
% =============================
% Schedule = list of events, each event has the following structure
%          = [event(Group_Name, Course_Code, Event_Name, Event_Type,slot(Week,Day,Slot_Number))]


% ===============
% Schedule Facts
% ===============
% Define course events, groups, quizslots, holidays and precedence constraints.

event_in_course(csen403, labquiz1, assignment).
event_in_course(csen403, labquiz2, assignment).
event_in_course(csen403, project1, evaluation).
event_in_course(csen403, project2, evaluation).
event_in_course(csen403, quiz1, quiz).
event_in_course(csen403, quiz2, quiz).
event_in_course(csen403, quiz3, quiz).

event_in_course(csen401, quiz1, quiz).
event_in_course(csen401, quiz2, quiz).
event_in_course(csen401, quiz3, quiz).
event_in_course(csen401, milestone1, evaluation).
event_in_course(csen401, milestone2, evaluation).
event_in_course(csen401, milestone3, evaluation).

event_in_course(csen402, quiz1, quiz).
event_in_course(csen402, quiz2, quiz).
event_in_course(csen402, quiz3, quiz).

event_in_course(math401, quiz1, quiz).
event_in_course(math401, quiz2, quiz).
event_in_course(math401, quiz3, quiz).

event_in_course(elct401, quiz1, quiz).
event_in_course(elct401, quiz2, quiz).
event_in_course(elct401, quiz3, quiz).
event_in_course(elct401, assignment1, assignment).
event_in_course(elct401, assignment2, assignment).

event_in_course(csen601, quiz1, quiz).
event_in_course(csen601, quiz2, quiz).
event_in_course(csen601, quiz3, quiz).
event_in_course(csen601, project, evaluation).
event_in_course(csen603, quiz1, quiz).
event_in_course(csen603, quiz2, quiz).
event_in_course(csen603, quiz3, quiz).

event_in_course(csen602, quiz1, quiz).
event_in_course(csen602, quiz2, quiz).
event_in_course(csen602, quiz3, quiz).

event_in_course(csen604, quiz1, quiz).
event_in_course(csen604, quiz2, quiz).
event_in_course(csen604, quiz3, quiz).
event_in_course(csen604, project1, evaluation).
event_in_course(csen604, project2, evaluation).


holiday(3,monday).
holiday(5,tuesday).
holiday(10,sunday).


studying(csen403, group4MET).
studying(csen401, group4MET).
studying(csen402, group4MET).
studying(csen402, group4MET).

studying(csen601, group6MET).
studying(csen602, group6MET).
studying(csen603, group6MET).
studying(csen604, group6MET).

should_precede(csen403,project1,project2).
should_precede(csen403,quiz1,quiz2).
should_precede(csen403,quiz2,quiz3).

quizslot(group4MET, tuesday, 1).
quizslot(group4MET, thursday, 1).
quizslot(group6MET, saturday, 5).

% ==================
% Schedule Generator
% ==================


%This predicate generates event structure in form of event(Group_Name, Course_Code, Event_Name, Event_Type) from the given facts
generate_event(Event):-
							event_in_course(Course_Code,Event_Name,Event_Type),
							studying(Course_Code,Group_Name),
							Event = event(Group_Name, Course_Code, Event_Name, Event_Type).

%generates list of all events in the database 							
generate_all_events(Events):-
							setof(Event,generate_event(Event),Events).
						
%generates the slot structure --> slot(Group_Name, Week, Day, Slot_Number) 
generate_slot(Week,Slot):-
							quizslot(Group_Name,Day,Slot_Number), \+holiday(Week,Day),
							Slot =slot(Group_Name,Week,Day,Slot_Number).
%generates a list of valid slots in all weeks of the schedule 
generate_all_slots(Number_Of_Weeks,Slots):-
							generate_all_slots_helper(1,Number_Of_Weeks,[],Temp_Slots),
							flatten(Temp_Slots,Slots).
%generates all slots in one week 							
generate_all_slots_helper(Weeks1,Weeks,Slots,Slots):-
							Weeks1 is Weeks +1.
generate_all_slots_helper(Curr_Week,Number_Of_Weeks,Acc,Slots):-
							Curr_Week =< Number_Of_Weeks,
							Next_Week is Curr_Week + 1,
							setof(Slot,generate_slot(Curr_Week,Slot), Cur_Week_Slots),
							generate_all_slots_helper(Next_Week,Number_Of_Weeks,[Cur_Week_Slots|Acc],Slots).

schedule(Weeks, Schedule):-
							generate_all_events(Events),
							generate_all_slots(Weeks,Slots),
							generate_schedule(Events,Slots,Schedule), write(Schedule),nl. 
							
generate_schedule(Events,Slots,Schedule):-
							generate_schedule_helper(Events,Slots,[],[],Schedule).

/* 
  matches an event with a slot, adds it to an accumulator and then calls test_schedule to check its validity up to that point until the list of events is empty
  then we have obtained a valid schedule 
*/							
generate_schedule_helper([],_,_,Schedule,Schedule).

generate_schedule_helper([Event|R],Slots,Chosen_Slots,Acc,Schedule):-
							Event = event(Group_Name,Course_Code,Event_Name,Event_Type),
							Slot = slot(Group_Name,Week,Day,Slot_Number),
							member(Slot,Slots),
							\+member(Slot,Chosen_Slots),
							test_schedule([event(Group_Name,Course_Code,Event_Name,Event_Type,slot(Week,Day,Slot_Number))|Acc]),
							generate_schedule_helper(R,Slots,[Slot|Chosen_Slots],[event(Group_Name,Course_Code,Event_Name,Event_Type,slot(Week,Day,Slot_Number))|Acc],Schedule).

%tests	that the given schedule satisfies the required properties 						
test_schedule(Schedule):-
						\+myand(member(event(Group_Name,_,_,_,_),Schedule),\+precede(Group_Name,Schedule)),			
						\+myand(member(event(Group_Name,_,_,_,_),Schedule),\+no_consec_quizzes(Group_Name,Schedule)),
						\+myand(member(event(Group_Name,_,_,_,_),Schedule),\+no_same_day_quiz(Group_Name,Schedule)),
						\+myand(member(event(Group_Name,_,_,_,_),Schedule),\+no_same_day_assignment(Group_Name,Schedule)).


% ==================
% Schedule Checkers
% ==================

consec_quizzes(Group_Name,Schedule):-
								member(event(Group_Name,Course_Code,Quiz1,quiz,slot(Week1,_,_)),Schedule),
								member(event(Group_Name,Course_Code,Quiz2,quiz,slot(Week2,_,_)),Schedule), 
								Quiz1 \= Quiz2,
								(1 is Week2 - Week1 ; (-1) is Week2 - Week1 ; Week1 = Week2).
	
no_consec_quizzes(Group_Name,Schedule):-
								\+consec_quizzes(Group_Name,Schedule).
	
same_day_quiz(Group_Name,Schedule):-
								member(event(Group_Name,Course_Code1,Event_Name1,quiz,slot(Week,Day,_)),Schedule),
								member(event(Group_Name,Course_Code2,Event_Name2,quiz,slot(Week,Day,_)),Schedule),
								(Course_Code1 \= Course_Code2 ; Event_Name1 \= Event_Name2).
								
no_same_day_quiz(Group_Name,Schedule):-
								\+same_day_quiz(Group_Name,Schedule).
								
same_day_assignment(Group_Name,Schedule):-
								member(event(Group_Name,Course_Code1,Event_Name1,assignment,slot(Week,Day,_)),Schedule),
								member(event(Group_Name,Course_Code2,Event_Name2,assignment,slot(Week,Day,_)),Schedule),
								(Course_Code1 \= Course_Code2 ; Event_Name1 \= Event_Name2).		
								
no_same_day_assignment(Group_Name,Schedule):-
								\+same_day_assignment(Group_Name,Schedule).
				

	

not_precede(Group_Name,Schedule):-
						should_precede(Course_Code,Event_Name1,Event_Name2),
						member(event(Group_Name,Course_Code,Event_Name1,_,slot(Week1,Day1,Slot_Number1)),Schedule),
						member(event(Group_Name,Course_Code,Event_Name2,_,slot(Week2,Day2,Slot_Number2)),Schedule),
						(Week1 > Week2 ; Week1 = Week2, \+before(Day1,Day2) ; Week1 = Week2, Day1 = Day2 , Slot_Number1 > Slot_Number2).
						
precede(Group_Name,Schedule):-
						\+not_precede(Group_Name,Schedule).
						
before(saturday,sunday).
before(sunday,monday).
before(monday,tuesday).
before(tuesday,wednesday).
before(wednsday,thursday).
before(thursday,friday).
													
							
%this predicate was not used as we checked on this property in our implementation of generate schedule
valid_slots_schedule(Group_Name,Schedule):-
							\+myand(member(event(Group_Name,_,_,_,slot(Week,Day,Slot_Number)),Schedule),
							   member(event(Group_Name,_,_,_,slot(Week,Day,Slot_Number)),Schedule)).
							   							
%this predicate was not used as we checked on this property in our implementation of generate schedule														
available_timings_helper(G, slot(Day, Slot_Number)):- quizslot(G, Day, Slot_Number). 
									
available_timings(G,L):-
						setof(Timings, available_timings_helper(G, Timings), L). 
%this predicate was not used as we checked on this property in our implementation of generate schedule						
group_events(Group_Name,Events):-
								setof(Event,group_event(Group_Name,Event),Events).
								

group_event(Group_Name,Event):-
								event_in_course(Course_Code,Event_Name, Event_Type),
								studying(Course_Code,Group_Name),
								Event = event(Course_Code,Event_Name,Event_Type).
								
%this predicate was not used as we checked on this property in our implementation of generate schedule								
no_holidays(Group_Name,Schedule):-
								\+is_holiday(Group_Name,Schedule).
								
is_holiday(Group_Name,Schedule):-
					holiday(Week,Day),
					member(event(Group_Name,_,_,_,slot(Week,Day,_)),Schedule).
myand(X,Y):-
			X,Y.

myand(X,Y,Z):-
				X,Y,Z.

					