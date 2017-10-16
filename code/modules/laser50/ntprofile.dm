/*=============EXTRA NOTES=============
- There are 2 variables that save the department; client.prefs.prefs_department and (human)mob.CharRecords.char_department
^ Both mut be set properly, or things break.
=====================================*/
/datum/ntprofile
	var/mob/owner
/*-------DEPARTMENT-RELATED-------*/
	var/char_department = SRV
	var/department_playtime = 0
	var/department_experience = 0
	var/department_rank = 0
/*-------CHARACTER-RELATED-------*/
	var/bank_balance = 0
	var/pension_balance = 0
	var/bonuscredit = 0
	var/employeescore = 5 //Calculated at run-time.
	var/list/employee_records = list()
	var/neurallaces = 0
	var/promoted = 0 //May be obselete.
	var/permadeath = 0
/*--------OTHER-RELATED--------*/

/datum/ntprofile/proc/Reset_Profile()
	char_department = initial(char_department)
	department_playtime = initial(department_playtime)
	department_experience = initial(department_experience)
	department_rank = initial(department_rank)
/*-------CHARACTER-RELATED-------*/
	bank_balance = initial(bank_balance)
	pension_balance = initial(pension_balance)
	bonuscredit = initial(bonuscredit)
	employeescore = initial(employeescore)
	employee_records = list()
	neurallaces = initial(neurallaces)
	promoted = initial(promoted)
	permadeath = initial(permadeath)
	sleep(2)
	save_persistent()

/datum/ntprofile/New(var/mob/M)
	if(M)
		owner = M
		Load_Profile(M)

/datum/ntprofile/proc/Load_Profile() //Init the profile.. Human set as owner.
	load_persistent() //Load persistent info.
	load_score()
	assign_flag()
	calculate_department_rank(owner)
	add_employeerecord("NanoTrasen", "Beginning of Employment in [owner.client.prefs.prefs_department] Dept.", 5, 0, 0, 250, 1)

/datum/ntprofile/proc/load_persistent()
	if(owner) //Must be valid.
		if(!owner.client.prefs.loaded_character)	return 0 //ERROR Fuck this shit
		var/savefile/S = new /savefile("data/player_saves/[copytext(owner.client.ckey,1,2)]/[owner.client.ckey]/preferences.sav")
		if(!S)					return 0
		S.cd = GLOB.using_map.character_save_path(owner.client.prefs.default_slot)

		S["char_department"]		>> char_department
		S["department_playtime"]	>> department_playtime
		S["dept_experience"]		>> department_experience
		S["bank_balance"]			>> bank_balance
		S["department_rank"]		>> department_rank
		S["pension_balance"]		>> pension_balance
		S["permadeath"]				>> permadeath
		S["neurallaces"]			>> neurallaces
		S["employee_records"]		>> employee_records
		S["promotion"]				>> promoted
		S["bonuscredit"]			>> bonuscredit
		S["promoted"]				>> promoted

/datum/ntprofile/proc/save_persistent()
	if(owner) //Must be valid.
		if(!owner.client.prefs.loaded_character)	return 0 //ERROR Fuck this shit
		var/savefile/S = new /savefile("data/player_saves/[copytext(owner.client.ckey,1,2)]/[owner.client.ckey]/preferences.sav")
		if(!S)					return 0
		S.cd = GLOB.using_map.character_save_path(owner.client.prefs.default_slot)

		S["char_department"]		<< char_department
		S["department_playtime"]	<< department_playtime
		S["dept_experience"]		<< department_experience
		S["bank_balance"]			<< bank_balance
		S["department_rank"]		<< department_rank
		S["pension_balance"]		<< pension_balance
		S["permadeath"]				<< permadeath
		S["neurallaces"]			<< neurallaces
		S["employee_records"]		<< employee_records
		S["promotion"]				<< promoted
		S["bonuscredit"]			<< bonuscredit
		S["promoted"]				<< promoted

/datum/ntprofile/proc/load_score()
	if(!owner || !employee_records)	return 5
	var/totalscore = 0
	var/counter = 0
	for(var/datum/ntprofile/employeerecord/N in employee_records)
		N.recomscore += totalscore
		counter++
	employeescore = totalscore/counter
	return employeescore

/datum/ntprofile/proc/assign_flag() //Updates the character department and sets the proper flags.
	if(owner.client.prefs.prefs_department)
		switch(owner.client.prefs.prefs_department)
			if("Security")
				char_department |= SEC
			if("Medical")
				char_department |= MED
			if("Science")
				char_department |= SCI
			if("Engineering")
				char_department |= ENG
			if("Supply")
				char_department |= SUP
			if("Service")
				char_department |= SRV

/datum/ntprofile/employeerecord
	var/mob/living/carbon/human/maker = ""       //The maker of the Recommendation
	var/note = "" //The note to add.
	var/recomscore = 0        // The score (1-10) we apply to the overall NT score
	var/warrantspromotion = 0 //If this is enough to warrant a promotion, EG from regular to senior roles.
	var/paybonuspercent = 0   //The percentage of extra hourly pay this will give the reciever
	var/paybonuscredit = 0    //The amount of credits recieved on the next paycheck.
	var/nanotrasen = 0        //Is this an official NanoTrasen Recommendation? (Adds a little checkmark?)
	/*Recommendations are checked every paycheck, bonus credit that is outstanding (not 0) will be paid out*/

/datum/ntprofile/proc/add_employeerecord(var/recommaker, var/note, var/recomscore, var/warrantspromotion, var/paybonuspercent, var/paybonuscredit, var/nanotrasen)
	if(recommaker && note) //The 2 main dawgs
//		var/mob/living/carbon/human/Maker = recommaker
		var/datum/ntprofile/employeerecord/record = new(recommaker, note, recomscore, warrantspromotion, paybonuspercent, paybonuscredit, nanotrasen)
		if(record)
			for(var/datum/ntprofile/employeerecord/R in employee_records)
				if(R.note == record.note) // Assuming it is a double.
					return
			if(!employee_records)	employee_records = list()
			employee_records.Add(record)
			load_score() //Re-load the score, reset the average.

/datum/ntprofile/proc/display_employeerecords() //Displays all records.
	. = list()
	for(var/datum/ntprofile/employeerecord/R in employee_records)
		. += "<b>[R.nanotrasen ? "OFFICIAL " : ""]RECORD| </b>[R.maker]: [R.note] ([R.recomscore])"
	return .
/*		if(nanotrasen)
			employee_records.Add("NOTE: NanoTrasen (OFFICIAL) -- [note] (S: [recomscore]")
			calculate_bonus_credit(owner, paybonuscredit, paybonuspercent)
		else
			employee_records.Add("NOTE: [Maker] ([Maker.job]) -- [note] (S: [recomscore]")
			calculate_bonus_credit(owner, paybonuscredit, paybonuspercent)
*/
/*
/datum/ntprofile/proc/add_recommendation(var/maker, var/reason)
	if(!maker || !reason)	return
	if(!recommendations)
		recommendations = list()
	recommendations.Add(name = "[maker]", reason = "[reason]")
*/