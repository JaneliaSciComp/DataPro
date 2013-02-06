//	DataPro//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18//	Nelson Spruston//	Northwestern University//	project began 10/27/1998//	last updated 1/12/2000Function NewTestPulseWindow() : Graph	// Save the data folder	String savDF=GetDataFolder(1)		// If the data folder doesn't exist, create it	if (!DataFolderExists("root:DP_TestPulseWindow")) 		NewDataFolder /S root:DP_TestPulseWindow		Variable /G amplitude=1		// test pulse amplitude, units determined by channel type		Variable /G duration=10		// test pulse duration, ms		Variable /G dt=0.02		// sample interval for the test pulse, ms		Variable /G adcIndex=0		// index of the ADC channel to be used for the test pulse		Variable /G dacIndex=0		// index of the DAC channel to be used for the test pulse			Variable /G ttlOutput=0		// whether or not to do a TTL output during test pulse		Variable /G ttlOutIndex=0	   // index of the TTL used for gate output, if ttlOutput is true		Variable /G doBaselineSubtraction=1	// whether to do baseline subtraction		Variable /G RSeal=nan	// GOhm		Variable /G updateRate=nan		// Hz		endif		// Set the data folder	SetDataFolder root:DP_TestPulseWindow		// Declare instance variables	NVAR ttlOutput	NVAR doBaselineSubtraction		NVAR RSeal	NVAR updateRate		// Kill any pre-existing window		if (GraphExists("TestPulseWindow"))		DoWindow /K TestPulseWindow	endif		// Create the graph window	Display /W=(760,450,760+300,450+300) /N=TestPulseWindow /K=1 as "Test Pulse"		// If TestPulse_ADC exists, put it in there	if (WaveExists(TestPulse_ADC))		AppendToGraph /W=TestPulseWindow TestPulse_ADC		ModifyGraph grid(left)=1		ModifyGraph tickUnit(bottom)=1		MatchYAxisLimitsToTrace()		SyncAxisLabelsToModel()	endif		// Draw the top "panel"	ControlBar /T /W=TestPulseWindow 80	// Control widgets for the test pulse		Button startButton,pos={18,10},size={80,20},proc=TPStartButtonProc,title="Start"	TitleBox proTipTitleBox,pos={10,30+4},frame=0,title="(hit ESC key to stop)",disable=1	SetVariable test_dac,pos={110+30,10},size={70,1},title="DAC #"	SetVariable test_dac,limits={0,3,1},value= root:DP_TestPulseWindow:dacIndex	SetVariable test_adc,pos={110+30,30},size={70,1},title="ADC #"	SetVariable test_adc,limits={0,7,1},value= root:DP_TestPulseWindow:adcIndex	SetVariable testPulseAmplitudeSetVariable,pos={200+30,10},size={100,1},title="amplitude"	SetVariable testPulseAmplitudeSetVariable,limits={-1000,1000,1},value= root:DP_TestPulseWindow:amplitude	SetVariable duration,pos={200+30,30},size={100,1},title="duration  "	SetVariable duration,limits={1,1000,1},value= root:DP_TestPulseWindow:duration	TitleBox msTitleBox,pos={300+30+4,30+1},frame=0,title="ms"		CheckBox testPulseBaseSubCheckbox,pos={110+30,56},size={58,14},title="Base Sub"	Checkbox testPulseBaseSubCheckbox,value=doBaselineSubtraction	Checkbox testPulseBaseSubCheckbox,proc=TestPulseBaseSubCheckboxUsed	CheckBox ttlOutputCheckbox,pos={200+30+20,56},size={58,14},title="TTL Output"	CheckBox ttlOutputCheckbox,proc=ttlOutputCheckboxUsed,value=ttlOutput	SetVariable ttlOutChannelSetVariable,pos={280+30+20,56-1},size={44,1},title="#"	SetVariable ttlOutChannelSetVariable,limits={0,3,1},value= root:DP_TestPulseWindow:ttlOutIndex	SetVariable ttlOutChannelSetVariable,disable=2-2*ttlOutput	// Draw the bottom "panel"	ControlBar /B /W=TestPulseWindow 30	// Widgets for showing the seal resistance	ValDisplay RSealValDisplay,pos={236,380},size={120,17},fSize=12,format="%10.3f"	ValDisplay RSealValDisplay,limits={0,0,0},barmisc={0,1000},value= _NUM:RSeal	ValDisplay RSealValDisplay,title="Resistance:"	TitleBox GOhmTitleBox,pos={236+126,380+1},frame=0,title="GOhm"	WhiteOutIffNan("RSealValDisplay","TestPulseWindow",RSeal)		// ValDisplay for showing the update rate	ValDisplay updateRateValDisplay,pos={10,380},size={120,17},fSize=12,format="%6.1f"	ValDisplay updateRateValDisplay,limits={0,0,0},barmisc={0,1000},value= _NUM:updateRate	ValDisplay updateRateValDisplay,title="Update rate:"	TitleBox hzTitleBox,pos={10+126,380+1},frame=0,title="Hz"	WhiteOutIffNan("updateRateValDisplay","TestPulseWindow",updateRate)		// Restore the original DF	SetDataFolder savDFEndFunction DeliverTestPulses()	// Deliver repeated test pulses, acquire response, display.	// Set DF	String savDF=GetDataFolder(1)	SetDataFolder root:DP_TestPulseWindow	// Declare instance variables	NVAR dacIndex	// index of DAC channel to use for test pulse	NVAR adcIndex	// index of ADC channel to use for test pulse	NVAR amplitude, duration	NVAR dt	NVAR ttlOutput		// boolean, true iff we're to also have a TTL output go high when pulsing	NVAR ttlOutIndex		// index of the TTL output channel to use	NVAR doBaselineSubtraction	NVAR RSeal	NVAR updateRate		// Build the test pulse wave	Wave TestPulse_TTL=SimplePulseBoolean(dt,0.5*duration,duration,0.5*duration)		// free wave	Variable nScans=numpnts(TestPulse_TTL)	Make /FREE /N=(nScans) TestPulse_DAC	TestPulse_DAC=amplitude*TestPulse_TTL	// Create the wave we'll display, which is all-zeros for now	Make /O /N=(nScans) TestPulse_ADC	Setscale /P x, 0, dt, "ms", TestPulse_ADC	// Bring the test pulse panel to the front	DoWindow /F TestPulseWindow		// Multiplex the TTL wave, if called for	if (ttlOutput)		//Duplicate /FREE /O TestPulse_DAC TestTrig_TTL		//TestTrig_TTL=0		//TestTrig_TTL[1,11]=2^ttlOutIndex		//Wave TestPulse_TTL=GetTestPulseBoolean()  // free wave		TestPulse_TTL=(2^ttlOutIndex)*TestPulse_TTL	// multiplexing	endif		// Build FIFOout for the test pulse	Variable outgain=GetDACPointsPerNativeUnit(dacIndex)	Variable ingain=GetADCNativeUnitsPerPoint(adcIndex)	String daseq=num2str(dacIndex)	String adseq=num2str(adcIndex)	if (ttlOutput)		daseq+="D"		adseq+=num2str(adcIndex)		Make /FREE /N=(nScans*2) FIFOout		Setscale /P x, 0, dt/2, "ms", FIFOout		//FIFOout[0,;2]=TestPulse_DAC[p/2]*outgain*dacMultiplier[dacIndex]		FIFOout[0,;2]=TestPulse_DAC[p/2]*outgain		FIFOout[1,;2]=TestPulse_TTL[p/2]	else		//Duplicate /FREE TestPulse_DAC FIFOout			Make /FREE /N=(nScans) FIFOout		Setscale /P x, 0, dt, "ms", FIFOout		//Duplicate /FREE TestPulse_DAC FIFOout			//FIFOout=TestPulse_DAC*outgain*dacMultiplier[dacIndex]		FIFOout=TestPulse_DAC*outgain	endif		// Specify the time windows for measuring the baseline and the pulse amplitude	Variable totalDuration=2*duration	Variable t0Base=0	Variable tfBase=1/8*totalDuration	Variable t0Pulse=5/8*totalDuration	Variable tfPulse=6/8*totalDuration		// execute the sample sequence for the first time	Wave FIFOin=SampleData(adseq,daseq,FIFOout)  // FIFOin is a free wave	// extract TestPulse_ADC from FIFOin	if (ttlOutput)		TestPulse_ADC=FIFOin[2*p]*ingain	else		TestPulse_ADC=FIFOin*ingain	endif	KillWaves FIFOin		// Don't need FIFOin anymore	if (doBaselineSubtraction)				Wavestats /Q/R=[5,45] TestPulse_ADC		TestPulse_ADC-=V_avg	endif	// if TestPulse_ADC is not currently being shown in the graph, append it	String traceList=TraceNameList("TestPulseWindow",";",3)  // 3 means all traces	Variable nTraces=ItemsInList(traceList)	Variable waveInGraph=(nTraces>0)		// assume that if there's a wave in there, it's TestPulse_ADC		if (~waveInGraph)		AppendToGraph /W=TestPulseWindow TestPulse_ADC		ModifyGraph grid(left)=1		ModifyGraph tickUnit(bottom)=1	endif	// set display range, axis labels, etc.	MatchYAxisLimitsToTrace()	SyncAxisLabelsToModel()		// repeat until user wants to stop	Variable base, pulse	Variable timer=-1	Variable usElapsed	Variable adcMode=GetADCChannelMode(adcIndex)	Variable dacMode=GetDACChannelMode(dacIndex)			TitleBox proTipTitleBox,win=TestPulseWindow,disable=0		// tell the user how to break out of the loop	do		// execute the sample sequence		Wave FIFOin=SampleData(adseq,daseq,FIFOout)		// extract TestPulse_ADC from FIFOin		if (ttlOutput)			TestPulse_ADC=FIFOin[2*p]*ingain		else			TestPulse_ADC=FIFOin*ingain		endif		KillWaves FIFOin		// Don't need FIFOin anymore		if (doBaselineSubtraction)			Wavestats /Q/R=[5,45] TestPulse_ADC			TestPulse_ADC-=V_avg		endif		// Calculate the seal resistance		base=mean(TestPulse_ADC,t0Base,tfBase)		pulse=mean(TestPulse_ADC,t0Pulse,tfPulse)		if (adcMode==1 && dacMode==2)			// ADC channel is a current channel, DAC channel is a voltage channel			RSeal=amplitude/(pulse-base)		elseif (adcMode==2 && dacMode==1)			// output channel is a voltage channel			RSeal=(pulse-base)/amplitude		else			Printf "ADC and DAC channel for test pulse are of same type, therefore the 'resistance' is unitless!\r"			RSeal=nan		endif		ValDisplay RSealValDisplay,win=TestPulseWindow,value= _NUM:RSeal		WhiteOutIffNan("RSealValDisplay","TestPulseWindow",RSeal)		// Calculate the update rate		usElapsed=stopMSTimer(timer)		timer=startMSTimer		updateRate=1e6/usElapsed	// Hz		ValDisplay updateRateValDisplay,win=TestPulseWindow,value= _NUM:updateRate		WhiteOutIffNan("updateRateValDisplay","TestPulseWindow",updateRate)		// Update the graph		DoUpdate	while (!EscapeKeyWasPressed())	usElapsed=stopMSTimer(timer)	// stop the timer	//while (HaltProcedures()<1)	TitleBox proTipTitleBox,win=TestPulseWindow,disable=1		// hide the tip	//// Kill the graph	//DoWindow /K TestPulseGraph		// Bring the test pulse panel forward now that we're done	DoWindow /F TestPulseWindow		// Kill the ADC wave, so it's not hanging around in the DF after we exit	//KillWaves TestPulse_ADC		// Restore the original DF	SetDataFolder savDFEndFunction TPStartButtonProc(ctrlName) : ButtonControl	String ctrlName	DeliverTestPulses()EndFunction TestPulseBaseSubCheckboxUsed(ctrlName,checked) : CheckBoxControl	String ctrlName	Variable checked	String savDF=GetDataFolder(1)	SetDataFolder root:DP_TestPulseWindow	NVAR doBaselineSubtraction	doBaselineSubtraction=checked		SetDataFolder savDFEndFunction ttlOutputCheckboxUsed(ctrlName,checked) : CheckBoxControl	String ctrlName	Variable checked	String savDF=GetDataFolder(1)	SetDataFolder root:DP_TestPulseWindow	NVAR ttlOutput	ttlOutput=checked	SetVariable ttlOutChannelSetVariable,win=TestPulseWindow,disable=2-2*ttlOutput		SetDataFolder savDFEndFunction MatchYAxisLimitsToTrace()	// private method	String savDF=GetDataFolder(1)	SetDataFolder root:DP_TestPulseWindow	if (WaveExists(TestPulse_ADC))			// set display range, axis labels, etc.		Variable miny, maxy		Wavestats /Q TestPulse_ADC		miny=1.2*V_min		maxy=1.2*V_max		miny-=maxy/10		if (miny>-0.2)			miny=-0.2		endif		if (maxy<0.2)			maxy=0.2		endif		Setaxis left, miny, maxy	endif	SetDataFolder savDFEndFunction SyncAxisLabelsToModel()	// private method	String savDF=GetDataFolder(1)	SetDataFolder root:DP_TestPulseWindow	NVAR adcIndex		if (WaveExists(TestPulse_ADC))			Label bottom "\\F'Helvetica'\\Z12\\f01Time (ms)"		String adcModeString=GetADCChannelModeString(adcIndex)		String adcUnitsString=GetADCChannelUnitsString(adcIndex)			Label left sprintf2s("\\F'Helvetica'\\Z12\\f01%s (%s)",adcModeString,adcUnitsString)	endif	SetDataFolder savDFEnd