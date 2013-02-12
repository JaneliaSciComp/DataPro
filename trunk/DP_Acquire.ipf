//	DataPro//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18//	Nelson Spruston//	Northwestern University//	project began 10/27/1998#pragma rtGlobals=1		// Use modern global access method.//---------------------- DataPro Acquire STARTUP ----------------------////_______________________DataPro TEST PULSE MACROS_________________________////Function /WAVE GetTestPulse()//	// Returns a test pulse wave, suitable for pushing to a DAC channel.////	// Set the DF//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	//	// test pulse parameters//	NVAR sinttp, tpamp, tpdur////	// Restore the DF//	SetDataFolder savedDF//		//	// Generate the (free) wave//	Wave TestPulse_TTL=SimplePulse(sinttp,0.5*tpdur,tpdur,0.5*tpdur,tpamp)//		//	// return//	return TestPulse_DAC//End////Function /WAVE GetTestPulseBoolean()//	// Returns a test pulse wave, suitable for pushing to a TTL channel.////	// Set the DF//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	//	// test pulse parameters//	NVAR sinttp, tpdur//	//	// Generate the (free) wave//	Wave TestPulse_TTL=SimplePulseBoolean(sinttp,0.5*tpdur,tpdur,0.5*tpdur)//		//	// Restore the DF//	SetDataFolder savedDF//	//	// return//	return TestPulse_TTL//End//Function TPWinButtonProc(ctrlName) : ButtonControl//	String ctrlName//	if (wintype("TestPulseDisplay")<1)//		Execute "TestPulseDisplay()"//	else//		DoWindow /F TestPulseDisplay	//	endif//	if (wintype("SweepControl")<1)//		Execute "SweepControl()"//	else//		DoWindow /F SweepControl	//	endif//	SetTPValues()//End//Function BsubCheck(ctrlName,checked) : CheckBoxControl//	String ctrlName//	Variable checked//End//Function TPampProc(ctrlName,varNum,varStr,varName) : SetVariableControl//	String ctrlName//	Variable varNum//	String varStr//	String varName//	//	NVAR testPulseTTLOutput//	NVAR tpamp, tpgateamp//	if (testPulseTTLOutput)//		tpamp=tpgateamp//	endif//End//_______________________DataPro DATA ACQUISITION MACROS_________________________////Function EPhys_Image()//	Variable sidx_handle, status, exposure, canceled//	String message, command//	if (ccd_opened<1)//		SIDX_Begin()//	endif////	if (sidx_handle==  4.306e+07)////		SIDX_Begin_Auto()////	endif////	SIDX_Setup()//	image_trig=1//	SIDX_Setup_Auto()//	image_roi=2		// zero for full frame, one for specific ROI, two for ROI with background//	im_plane=0//	FluorescenceON()//	Execute "Sleep /S 0.1"//	sprintf command, "Image_Stack(image_trig,0)"//	Execute command//	print "done with image stack"//	sprintf command, "Get_DFoverF_from_Stack(%d)", iSweepPrevious//	Execute command//	sprintf command, "Append_DFoverF(%d)", iSweepPrevious//	Execute command//	FluorescenceOFF()//	printf "%s%d: Image with EPhys done\r", imageseq_name, iSweepPrevious//EndFunction DataButtonProc(ctrlName) : ButtonControl	// Raise or create the three windows used for data acquisition	String ctrlName		RaiseOrCreateMainWindows()EndFunction RaiseOrCreateMainWindows()	// Raise or create the three main windows used for data acquisition	RaiseOrCreateView("DigitizerView")	RaiseOrCreateView("SweeperView")	RaiseOrCreateDataProBrowser()	NewTestPulseWindow()EndFunction HandleGetDataButton(ctrlName) : ButtonControl	String ctrlName	AcquireTrial()EndFunction DPampProc(ctrlName,varNum,varStr,varName) : SetVariableControl	String ctrlName	Variable varNum	String varStr	String varName//	SetDPvalues()	StepPulseParametersChanged()EndFunction DPdurCheckProc(ctrlName,checked) : CheckBoxControl	String ctrlName	Variable checked	if (cmpstr(ctrlName,"stepPulseDuration_check0")!=0)		CheckBox stepPulseDuration_check0 value=0		CheckBox stepPulseDuration_check1 value=1	else		CheckBox stepPulseDuration_check1 value=0		CheckBox stepPulseDuration_check0 value=1	endif//	SetDPvalues()	StepPulseParametersChanged()EndFunction DPdurProc(ctrlName,varNum,varStr,varName) : SetVariableControl	String ctrlName	Variable varNum	String varStr	String varName//	SetDPvalues()	StepPulseParametersChanged()End//______________________DataPro Imaging PROCEDURES__________________________//Function ImagingButtonProc(ctrlName) : ButtonControl	String ctrlName	if (wintype("ImagingPanel")<1)		Execute "ImagingPanel()"	else		DoWindow /F ImagingPanel		endifEndFunction FluONButtonProc(ctrlName) : ButtonControl	String ctrlName	FluorescenceON()EndFunction FluorescenceON()	String command	NVAR wheel=fluo_on_wheel	SetVDTPort("COM1")	Execute "VDTWriteBinary 238"	sprintf command "VDTWriteBinary 8%d", wheel	Execute command//	print "fluorescence on"EndFunction FluOFFButtonProc(ctrlName) : ButtonControl	String ctrlName	FluorescenceOFF()EndFunction FluorescenceOFF()	SetVDTPort("COM1")	Execute "VDTWriteBinary 238"	Execute "VDTWriteBinary 80"//	print "fluorescence off"EndFunction SetVDTPort(name)	String name	Execute "VDTGetPortList"	SVAR port=S_VDT	NVAR imaging=imaging	String command	imaging=1	if (cmpstr(port,"")==0)		imaging=0		Abort "A serial port could not be located"	else		sprintf command, "VDTOperationsPort %s", name		Execute command	endifEndFunction ImagingCheckProc(ctrlName,checked) : CheckBoxControl	String ctrlName	Variable checked	NVAR imaging=imaging	Execute "VDTGetPortList"	SVAR port=S_VDT	if (checked>0)		imaging=1		SetVDTPort("COM1")	else		imaging=0	endifEnd//______________________DataPro Data Acquisition HISTORY__________________________////________________________written by Don Cooper________________________________////Function SaveStimHistory()//	String savedDF=GetDataFolder(1)//	NewDataFolder /O/S root:DP_Digitizer//	Variable StimHsize, wavenum//	String theMultDac, theDacGain, theDacPopup//	NVAR nSweepsPerTrial//	NVAR iSweep=iSweep, HoldV=HoldV,NumRepeats=NumRepeats, IStimI=IStimI, TempV=TempV, Rseal=Rseal//	NVAR MadeStimHist=MadeStimHist, dacGain1=dacGain1, stepPulseAmplitude=stepPulseAmplitude, stepPulseDuration=stepPulseDuration//	NVAR dacGain2=dacGain2, pn=pn//	//SVAR wave_comments//	String daseq=GetDACSequence()////	String history="StimHistory"////  ***daseq*** = string listing which DAC's are checked          //     sprintf theMultDac "multdac%s", daseq[0]//     sprintf theDacGain "dacGain%s", daseq[0]//     sprintf theDacPopup "dacpopup_%s", daseq[0]//     NVAR theMD=$theMultDac, theDG=$theDacGain//     wavenum=iSweep-1//// make a table... but check to see if it's already been made first//	if (exists("StimHistory")!=1)//		Make/T/O/N=(2,11) StimHistory//		StimHistory[0][0]="Stimulus Wave"//		StimHistory[0][1]="Wave Multiplier"//		StimHistory[0][2]="Holding Potential"//		StimHistory[0][3]="Gain"//		StimHistory[0][4]="Current Step"		//for step_pulses//		StimHistory[0][5]="Step Duration"		//for step_pulses//		StimHistory[0][6]="pN"//		StimHistory[0][7]="Comments"//		StimHistory[0][8]="Time"//		StimHistory[0][9]="Temp"//		Stimhistory[0][10]="Seal"//	endif////	insert appropriate row(s) in table//	StimHsize= dimsize(StimHistory,0)//	if (StimHsize<=wavenum)//		if (StimHsize==wavenum)//			InsertPoints wavenum,1, StimHistory//		else//			InsertPoints StimHsize,(1+wavenum-StimHsize), StimHistory//		endif//	endif//// enter all the other data //	ControlInfo /W=Digitizer $theDacPopup//	StimHistory[wavenum][0]=S_Value                   		//the stimulus wave//	StimHistory[wavenum][1]=num2str(theMD)         	//the wave multiplier//	StimHistory[wavenum][2]=num2str(HoldV)     		//the holding potential//	StimHistory[wavenum][3]=num2str(theDG)          	//gain on stimulator//	StimHistory[wavenum][6]=num2str(pn)             	//pN//	StimHistory[wavenum][7]=""		            		//comments//	StimHistory[wavenum][8]=time()                    		//approx. time of data acqisition//	StimHistory[wavenum][9]=num2str(TempV)		//Temperature//	StimHistory[wavenum][10]=num2str(RSeal)		//SR//	if (cmpstr(S_value,"StepPulse_DAC")==0)			//if the stim is a "step pulse"...//		StimHistory[wavenum][4]=num2str(stepPulseAmplitude)     		 //the current step//		StimHistory[wavenum][5]=num2str(stepPulseDuration)     		 //step duration//	else//		StimHistory[wavenum][4]=""     		 //don't put anything//		StimHistory[wavenum][5]=""     		 //don't put anything//	endif//	SetDataFolder savedDF//End//______________________DataPro Data Acquisition PROCEDURES__________________________////Function MakeITCseq()//	// Determines the sequencing strings required by the ITC functions for proper A/D and D/A.//	// Reads: dacChannelOn, ttlOutputChannelOn, adcChannelOn//	// Writes: daseq, adseq, nADCInUse, nDACInUse, seqlength//	//	// Shut up//	Silent 1//	//	// Change to the Digitizer data folder//	String savedDF=GetDataFolder(1)//	NewDataFolder /O/S root:DP_Digitizer////	// Declare the DF vars we need//	NVAR nDACInUse, nADCInUse, seqlength//	SVAR daseq, adseq//	WAVE dacChannelOn, ttlOutputChannelOn, adcChannelOn////	// Build up the strings that the ITC functions use to sequence the//	// inputs and outputs	//	daseq=""//	adseq=""//	Variable i//	for (i=0; i<4; i+=1)//		if (dacChannelOn[i]>0)//			daseq+=num2str(i)//		endif//	endfor//	for (i=0; i<4; i+=1)//		if (ttlOutputChannelOn[i]>0)//			daseq+="D"//			break//		endif//	endfor//	for (i=0; i<8; i+=1)//		if (adcChannelOn[i]>0)//			adseq+=num2str(i)//		endif//	endfor//	//	// Because the DA and AD sequences must be the same length, we find the least common multiple//	// of the number of channels in use, and duplicate the sequences as needed.//	// (But why not use Noops?  Especially if, for instance, nDACInUse is zero?)//	nDACInUse=strlen(daseq)//	nADCInUse=strlen(adseq)//	seqlength=LCM(nDACInUse, nADCInUse)	//	calculate the length of the AD and DA sequence strings (must be the same)//	String shortdaseq, shortadseq//	if (nDACInUse!=nADCInUse)//		shortdaseq=daseq; shortadseq=adseq//		daseq=""; adseq=""//		for (i=0; i<seqlength/nDACInUse; i+=1)//			daseq+=shortdaseq//		endfor//		for (i=0; i<seqlength/nADCInUse; i+=1)//			adseq+=shortadseq//		endfor//	endif//	//	// Restore the original DF//	SetDataFolder savedDF//End//___________________________DataPro CLAMP MODE___________________________//Function ToggleClampButtonProc(ctrlName) : ButtonControl	String ctrlName	print "switch all clamp modes together - not yet implemented"	Variable i=0//	do//		SwitchClampMode(i,x)//		i+=1//	while(i<8)End//______________________DataPro ADC AND DAC CONTROL____________________//Function ADC_DACButtonProc(ctrlName) : ButtonControl	String ctrlName	RaiseOrCreateView("DigitizerView")End//__________________________DataPro DAC PULSE BUILDER___________________________////Function DACBuilderButtonProc(ctrlName) : ButtonControl//	String ctrlName//	if (wintype("DACPulses")<1)//		Execute "DACPulses()"//	else//		DoWindow /F DACPulses	//	endif//End////Function ReadwaveButtonProc(ctrlName) : ButtonControl//	String ctrlName//	LoadWave//End////Function FiveSegButtonProc(ctrlName) : ButtonControl//	String ctrlName//	LaunchFiveSegBuilder()//End////Function LaunchFiveSegBuilder()//	if (wintype("FiveSegBuilder")<1)//		FiveSegBuilder()//		Execute "StepVarChange()"//	else//		DoWindow /F FiveSegBuilder//	endif//End////Function StepVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl//	String ctrlName//	Variable varNum//	String varStr//	String varName//	Execute "StepVarChange()"//End//Function FromFileCheckProc(ctrlName,checked) : CheckBoxControl//	String ctrlName//	Variable checked//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	NVAR ffseg=ffseg//	String doit//	if (checked>0)//		ffseg=str2num(ctrlName[3])////		print ffseg//		Execute "FFWaveInput()"//	else//		Execute "StepVarChange()"//	endif//	SetDataFolder savedDF//End////Proc FFWaveInput(waveinput)//	String waveinput//	Prompt waveinput, "Select wave to insert:", popup Wavelist("*_DAC",";","")+Wavelist("*_TTL",";","")//	String waveoutput//	sprintf waveoutput, "ffwave%d", ffseg//	if (deltax($waveinput)!=deltax(Step5DAC))//		CheckBox ff_2 win=FiveSegBuilder, value=0//		Abort "Sample Interval Mismatch"//	else//		Duplicate /O $waveinput $waveoutput//		StepVarChange()//	endif//End//Proc StepVarChange()//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	//	//WAVE duration, amplitude, Step5DAC//	//NVAR dtFiveSegment//	//	Variable i, first, last, totaldur, firstp, lastp//	String ffstr, notestr//	Vars2Wave("stepDuration","duration",5)//	Vars2Wave("stepAmplitude","amplitude",5)//	PauseUpdate//	totaldur=0//	i=0//	do//		sprintf ffstr, "ff_%d", i//		ControlInfo $ffstr//		if (V_value>0)//			sprintf ffstr, "ffwave%d", i//			duration[i]=numpnts($ffstr)*deltax($ffstr)//			//print duration[i]//			Wave2Vars("duration","stepDuration",5)//		endif//		totaldur+=duration[i]//		i+=1//	while(i<5)//	print totaldur, dt//	Redimension /N=(totaldur/dt) Step5DAC//	Setscale /P x, 0, dt, "ms", Step5DAC//	Note /K Step5DAC//	ReplaceStringByKeyInWaveNote(Step5DAC,"WAVETYPE","step5dac")//	ReplaceStringByKeyInWaveNote(Step5DAC,"TIME",time())//	ReplaceStringByKeyInWaveNote(Step5DAC,"STEP",num2str(amplitude[1]))//	first=0//	i=0//	do//		last=first+duration[i]//		sprintf ffstr, "ff_%d", i//		ControlInfo $ffstr//		if (V_value<1)//			Step5DAC(first,last)=amplitude[i]//		else//			sprintf ffstr, "ffwave%d", i//			amplitude[i]=0//			firstp=x2pnt(Step5DAC, first)//			lastp=x2pnt(Step5DAC, last)//			Step5DAC[firstp,lastp]=$ffstr[p-firstp]//			Wave2Vars("amplitude","stepAmplitude",5)//		endif//		first=last+dt//		sprintf notestr, "AMP%d", i//		ReplaceStringByKeyInWaveNote(Step5DAC,notestr,num2str(amplitude[i]))//		sprintf notestr, "DUR%d", i//		ReplaceStringByKeyInWaveNote(Step5DAC,notestr,num2str(duration[i]))//		i+=1//	while(i<5)//	ResumeUpdate//	Duplicate /O Step5DAC NewDAC//	//	SetDataFolder savedDF//End//Function EditFiveSegWave(ctrlName,popNum,popStr) : PopupMenuControl//	String ctrlName//	Variable popNum//	String popStr//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	String showstr//	sprintf showstr, "ShowFiveSegWave(\"%s\")", popStr//	Execute showstr//	SetDataFolder savedDF//End////Proc ShowFiveSegWave(popstr)//	String popstr//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	String keyword, keyval//	Variable i//	if (cmpstr(popstr,"_New_")==0)//		stepDuration0=10; stepDuration1=10; stepDuration2=10; stepDuration3=10; stepDuration4=10//		stepAmplitude1=10; stepAmplitude3=10;//		StepVarChange()//	else//		keyval=StringByKeyInWaveNote($popstr,"WAVETYPE")//		if (cmpstr(keyval,"step5dac")==0)//			//dt=deltax($popstr)//			do//				sprintf keyword, "DUR%d", i//				duration[i]=NumberByKeyInWaveNote($popstr,keyword)//				sprintf keyword, "AMP%d", i//				amplitude[i]=NumberByKeyInWaveNote($popstr,keyword)//				i+=1//			while(i<5)//			Wave2Vars("duration", "stepDuration", 5)//			Wave2Vars("amplitude", "stepAmplitude", 5)//			StepVarChange()//		else//			Abort("This is not a five segment wave; choose another")//		endif//	endif//	SetDataFolder savedDF//End//Function TrainButtonProc(ctrlName) : ButtonControl//	String ctrlName//	LaunchTrainBuilder()//End//Function LaunchTrainBuilder()//	if (wintype("TrainBuilder")<1)//		Execute "TrainVarChange()"//		Execute "TrainBuilder()"//	else//		DoWindow /F TrainBuilder//	endif//End//Function TrainVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl//	String ctrlName//	Variable varNum//	String varStr//	String varName//	Execute "TrainVarChange()"//End//Proc TrainVarChange()//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	Variable i, j, first, last, totaldur//	String notestr//	trainDuration1=(trainNumber/trainFrequency)*1000//	Vars2Wave("trainDuration","duration",3)//	PauseUpdate//	totaldur=0//	i=0//	do//		totaldur+=duration[i]//		i+=1//	while(i<3)//	Redimension /N=(totaldur/dt) TrainDAC//	Setscale /P x, 0, dt, "ms", TrainDAC//	Note /K TrainDAC//	ReplaceStringByKeyInWaveNote(TrainDAC,"WAVETYPE","traindac")//	ReplaceStringByKeyInWaveNote(TrainDAC,"TIME",time())//	TrainDAC=trainBase//	first=0//	i=0//	do//		if (i==1)//			j=0//			do//				last=first+trainDuration//				TrainDAC(first,last)=trainBase+trainAmplitude//				first+=1000/trainFrequency+dt//				j+=1//			while(j<trainNumber)//		else//			last=first+duration[i]//			TrainDAC(first,last)=trainBase//		endif//		first=last+dt//		sprintf notestr, "TRAINDUR%d", i//		ReplaceStringByKeyInWaveNote(TrainDAC,notestr, num2str(duration[i]))//		i+=1//	while(i<3)//	ReplaceStringByKeyInWaveNote(TrainDAC,"TRAINNUM", num2str(trainNumber))//	ReplaceStringByKeyInWaveNote(TrainDAC,"TRAINFREQ", num2str(trainFrequency))//	ReplaceStringByKeyInWaveNote(TrainDAC,"TRAINBASE", num2str(trainBase))//	ReplaceStringByKeyInWaveNote(TrainDAC,"TRAINAMP", num2str(trainAmplitude))//	ReplaceStringByKeyInWaveNote(TrainDAC,"TRAINUPDUR", num2str(trainDuration))//	ResumeUpdate//	Duplicate /O TrainDAC NewDAC//	SetDataFolder savedDF//End//Function EditTrainWave(ctrlName,popNum,popStr) : PopupMenuControl//	String ctrlName//	Variable popNum//	String popStr//	String showstr//	sprintf showstr, "ShowTrainWave(\"%s\")", popStr//	Execute showstr//End////Proc ShowTrainWave(popstr)//	String popstr//	String savedDF=GetDataFolder(1)//	SetDataFolder root:DP_Digitizer//	String keyword, keyval//	Variable i//	if (cmpstr(popstr,"_New_")==0)//		trainDuration0=10; trainDuration1=10; trainDuration2=10; trainNumber=10//		trainFrequency=10; trainAmplitude=10; trainBase=0; trainDuration=2//		TrainVarChange()//	else//		keyval=StringByKeyInWaveNote($popstr, "WAVETYPE")//		if (cmpstr(keyval,"traindac")==0)//			//dt=deltax($popstr)//			do//				sprintf keyword, "TRAINDUR%d", i//				duration[i]=NumberByKeyInWaveNote($popstr,keyword)//				i+=1//			while(i<3)//			Wave2Vars("duration", "trainDuration", 3)//			sprintf keyword, "TRAINNUM"//			trainNumber=NumberByKeyInWaveNote($popstr,keyword)//			sprintf keyword, "TRAINFREQ"//			trainFrequency=NumberByKeyInWaveNote($popstr,keyword)//			sprintf keyword, "TRAINAMP"//			trainAmplitude=NumberByKeyInWaveNote($popstr,keyword)//			sprintf keyword, "TRAINBASE"//			trainBase=NumberByKeyInWaveNote($popstr,keyword)//			sprintf keyword, "TRAINUPDUR"//			trainDuration=NumberByKeyInWaveNote($popstr,keyword)//			TrainVarChange()//		else//			Abort("This is not a train wave; choose another")//		endif//	endif//	SetDataFolder savedDF//End////Function RampButtonProc(ctrlName) : ButtonControl//	String ctrlName//	LaunchRampBuilder()//End////Function LaunchRampBuilder()//	if (wintype("RampBuilder")<1)//		Execute "RampVarChange()"//		Execute "RampBuilder()"//	else//		DoWindow /F RampBuilder//	endif//End////Function RampVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl//	String ctrlName//	Variable varNum//	String varStr//	String varName//	Execute "RampVarChange()"//End////Proc RampVarChange()//	String savedDF= GetDataFolder(1)//	SetDataFolder root:DP_Digitizer://	Variable i, j, first, last, totaldur, slope//	String notestr//	Vars2Wave("rampDuration","duration",3)//	Vars2Wave("rampAmplitude","amplitude",3)////	amplitude[0]=amplitude[1]////	rampAmplitude0=rampAmplitude1//	PauseUpdate//	totaldur=0//	i=1//	do//		totaldur+=duration[i]//		i+=1//	while(i<5)//	Redimension /N=(totaldur/dt) RampDAC//	Setscale /P x, 0, dt, "ms", RampDAC//	Note /K RampDAC//	ReplaceStringByKeyInWaveNote(RampDAC,"WAVETYPE","rampdac")//	ReplaceStringByKeyInWaveNote(RampDAC,"TIME",time())//	slope=(rampAmplitude3-rampAmplitude1)/rampDuration2//	first=0//	i=1//	do//		if (i==2)//			last=first+rampDuration2//			RampDAC(first,last)=rampAmplitude1+slope*(x-rampDuration1)//		else//			last=first+duration[i]//			RampDAC(first,last)=amplitude[i]//		endif//		first=last+dt//		sprintf notestr, "RAMPDUR%d", i//		ReplaceStringByKeyInWaveNote(RampDAC,notestr, num2str(duration[i]))//		sprintf notestr, "RAMPAMP%d", i//		ReplaceStringByKeyInWaveNote(RampDAC,notestr, num2str(amplitude[i]))//		i+=1//	while(i<5)//	ResumeUpdate//	Duplicate /O RampDAC NewDAC//	SetDataFolder savedDF//End////Function EditRampWave(ctrlName,popNum,popStr) : PopupMenuControl//	String ctrlName//	Variable popNum//	String popStr//	String showstr//	sprintf showstr, "ShowRampWave(\"%s\")", popStr//	Execute showstr//End////Proc ShowRampWave(popstr)//	String popstr//	String keyword, keyval//	Variable i//	if (cmpstr(popstr,"_New_")==0)//		rampDuration0=10; rampDuration1=50; rampDuration2=10//		rampAmplitude1=-10; rampAmplitude2=10//		RampVarChange()//	else//		keyval=StringByKeyInWaveNote("WAVETYPE",$popstr)//		if (cmpstr(keyval,"rampdac")==0)//			//dt=deltax($popstr)//			do//				sprintf keyword, "RAMPDUR%d", i//				duration[i]=NumberByKeyInWaveNote($popstr,keyword)//				sprintf keyword, "RAMPAMP%d", i//				amplitude[i]=NumberByKeyInWaveNote($popstr,keyword)//				i+=1//			while(i<3)//			Wave2Vars("duration", "rampDuration", 3)//			Wave2Vars("amplitude", "rampAmplitude", 3)//			RampVarChange()//		else//			Abort("This is not a ramp wave; choose another")//		endif//	endif//End////Function PSCButtonProc(ctrlName) : ButtonControl//	String ctrlName//	LaunchPSCBuilder()//End////Function LaunchPSCBuilder()//	if (wintype("PSCBuilder")<1)//		Execute "PSCVarChange()"//		Execute "PSCBuilder()"//	else//		DoWindow /F PSCBuilder//	endif//End////Function PSCVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl//	String ctrlName//	Variable varNum//	String varStr//	String varName//	Execute "PSCVarChange()"//End////Proc PSCVarChange()//	Variable i, j, first, last, totaldur, max, scale, rise, decay1, decay2, err//	String notestr, savedDF//	savedDF=GetDataFolder(1)//	SetDataFolder "root:DP_Digitizer"//	Vars2Wave("pscDuration","duration",3)//	PauseUpdate//	totaldur=0//	i=0//	do//		totaldur+=duration[i]//		i+=1//	while(i<3)//	Redimension /N=(totaldur/dt) PSCDAC//	Setscale /P x, 0, dt, "ms", PSCDAC//	Note /K PSCDAC//	ReplaceStringByKeyInWaveNote(PSCDAC,"WAVETYPE","pscdac")//	ReplaceStringByKeyInWaveNote(PSCDAC,"TIME",time())//	ReplaceStringByKeyInWaveNote(PSCDAC,"PSCAMP",num2str(pscAmplitude))//	ReplaceStringByKeyInWaveNote(PSCDAC,"PSCTAUR",num2str(pscTauRise))//	ReplaceStringByKeyInWaveNote(PSCDAC,"PSCTAUD1",num2str(pscTauDecay1))//	ReplaceStringByKeyInWaveNote(PSCDAC,"PSCTAUD2",num2str(pscTauDecay2))//	ReplaceStringByKeyInWaveNote(PSCDAC,"WTTD2",num2str(weightOfTauDecay2))//	scale=1.37		// correct value is unique for each psc wave; adjusted in loop below//	first=0//	i=0//	do//		if (i==1)//			last=first+pscDuration1//			PSCDAC(first,last)=pscAmplitude*scale*-exp((pscDuration0-x)/pscTauRise)//			PSCDAC(first,last)+=(1-weightOfTauDecay2)*pscAmplitude*scale*exp((pscDuration0-x)/pscTauDecay1)//			PSCDAC(first,last)+=weightOfTauDecay2*pscAmplitude*scale*exp((pscDuration0-x)/pscTauDecay2)//			do//				Wavestats /Q/R=(first,last) PSCDAC//				if (abs(V_min)<V_max)//					err=(V_max-pscAmplitude)/pscAmplitude//				else//					err=(V_min-pscAmplitude)/pscAmplitude//				endif//				PSCDAC=PSCDAC*(1-err)//			while(abs(err)>0.001)//		else//			last=first+duration[i]//			PSCDAC(first,last)=0//		endif//		first=last+dt//		sprintf notestr, "PSCDUR%d", i//		ReplaceStringByKeyInWaveNote(PSCDAC,notestr,num2str(duration[i]))//		i+=1//	while(i<3)//	ResumeUpdate//	Duplicate /O PSCDAC NewDAC//	SetDataFolder savedDF//End////Function EditPSCWave(ctrlName,popNum,popStr) : PopupMenuControl//	String ctrlName//	Variable popNum//	String popStr//	String showstr//	sprintf showstr, "ShowPSCWave(\"%s\")", popStr//	Execute showstr//End////Proc ShowPSCWave(popstr)//	String popstr//	String keyword, keyval, savedDF//	Variable i//	savedDF=GetDataFolder(1)//	SetDataFolder "DP_Digitizer"//	if (cmpstr(popstr,"_New_")==0)//		pscDuration0=10; pscDuration1=50; pscDuration2=10; pscAmplitude=10//		pscTauRise=0.2; pscTauDecay1=2; pscTauDecay2=10; weightOfTauDecay2=0.5//		PSCVarChange()//	else//		keyval=StringByKeyInWaveNote("WAVETYPE", $popstr)//		if (cmpstr(keyval,"pscdac")==0)//			pscAmplitude=NumberByKeyInWaveNote($popstr,"PSCAMP")//			pscTauRise=NumberByKeyInWaveNote($popstr,"PSCTAUR")//			pscTauDecay1=NumberByKeyInWaveNote($popstr,"PSCTAUD1")//			pscTauDecay2=NumberByKeyInWaveNote($popstr,"PSCTAUD2")//			weightOfTauDecay2=NumberByKeyInWaveNote($popstr,"WTTD2")//			//dt=deltax($popstr)//			do//				sprintf keyword, "PSCDUR%d", i//				duration[i]=NumberByKeyInWaveNote($popstr,keyword)//				i+=1//			while(i<3)//			Wave2Vars("duration", "pscDuration", 3)//			PSCVarChange()//		else//			Abort("This is not a PSC wave; choose another")//		endif//	endif//	SetDataFolder savedDF//EndFunction ViewDACButtonProc(ctrlName) : ButtonControl	String ctrlName	Execute "DACViewer()"End//Function HandleViewDacPopupSelection(ctrlName,itemNum,itemStr) : PopupMenuControl//	String ctrlName//	Variable itemNum//	String itemStr////	// Save current data folder, set to one we want.//	String savedFolderName= GetDataFolder(1)//	SetDataFolder root:DP_Digitizer://	//	// Remove the current trace, put in the new one.//	RemoveFromGraph /Z $"#0"//	if ( cmpstr(itemStr,"(none)")!=0 )//		AppendToGraph $itemStr//		ModifyGraph grid(left)=1  // put the grid back//	endif//	//	// Restore the original data folder.//	SetDataFolder savedFolderName//End//Function ResetAxesProc(ctrlName,varNum,varStr,varName) : SetVariableControl//	String ctrlName//	Variable varNum//	String varStr//	String varName//	RescaleTopAxes()//End//Function CursorsCheckProc(ctrlName,checked) : CheckBoxControl//	String ctrlName//	Variable checked//	SVAR thiswave=thiswave//	PlaceCursors(thiswave)//End//// Remove a list of waves from the top graph//Function RemoveWaves(list,graph)//	String list, graph//	String theWave//	Variable index=0//	DoWindow /F $graph//	do//		theWave=GetStrFromList(list,index,";")//		if (strlen(theWave)==0)//			break//		endif//		RemoveFromGraph $theWave//		index+=1//	while(1)	//  loop until break above//End