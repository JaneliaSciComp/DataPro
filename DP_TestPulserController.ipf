//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContConstructor() : Graph
	TestPulserConstructor()
	TestPulserViewConstructor()
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContDigitizerChanged()
	// Used to notify the Test Pulser controller that the Digitzer model has changed.
	// Currently, prompts an update of the TestPulser view only.
	TestPulserViewDigitizerChanged()
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContDacIndexTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	TestPulserViewUpdate()	
End	


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContSetDACIndex(newValue)
	Variable newValue
	
	TestPulserSetDACIndex(newValue)
	TestPulserViewUpdate()			
End	


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContSetADCIndex(newValue)
	Variable newValue
	
	TestPulserSetADCIndex(newValue)
	TestPulserViewUpdate()			
End	


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContStart()
	// Deliver repeated test pulses, acquire response, display.

	// Set DF
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	// Declare instance variables
	NVAR dacIndex	// index of DAC channel to use for test pulse
	NVAR adcIndex	// index of ADC channel to use for test pulse
	NVAR amplitude, duration
	NVAR dt
	NVAR ttlOutput		// boolean, true iff we're to also have a TTL output go high when pulsing
	NVAR ttlOutIndex		// index of the TTL output channel to use
	NVAR doBaselineSubtraction
	NVAR RSeal
	NVAR updateRate
	
	// Build the test pulse wave
	Wave testPulseTTL=SimplePulseBoolean(dt,2*duration,0.5*duration,duration)		// free wave
	Variable nScans=numpnts(testPulseTTL)
	Make /FREE /N=(nScans) testPulse
	testPulse=amplitude*testPulseTTL

	// Create the wave we'll display, which is all-zeros for now
 	Make /O /N=(nScans) TestPulse_ADC		// This is a bound wave, b/c it has to live on after we exit
	Setscale /P x, 0, dt, "ms", TestPulse_ADC

	// Bring the test pulse panel to the front
	DoWindow /F TestPulserView
	
	// Multiplex the TTL wave, if called for
	if (ttlOutput)
		testPulseTTL=(2^ttlOutIndex)*testPulseTTL	// multiplexing
	endif
	
	// Build FIFOout for the test pulse
	Variable outGain=DigitizerModelGetDACPntsPerNtv(dacIndex)
	Variable inGain=DigitizerModelGetADCNtvsPerPnt(adcIndex)
	String daSequence=num2str(dacIndex)
	String adSequence=num2str(adcIndex)
	if (ttlOutput)
		daSequence+="D"
		adSequence+=num2str(adcIndex)
		Make /FREE /N=(nScans*2) FIFOout
		Setscale /P x, 0, dt/2, "ms", FIFOout
		//FIFOout[0,;2]=testPulse[p/2]*outGain*dacMultiplier[dacIndex]
		FIFOout[0,;2]=testPulse[p/2]*outGain		// units: digitizer points
		FIFOout[0,;2]=min(max(-32768,FIFOout[p]),32767)		// limit to 16 bits
		FIFOout[1,;2]=testPulseTTL[p/2]
	else
		//Duplicate /FREE testPulse FIFOout	
		Make /FREE /N=(nScans) FIFOout
		Setscale /P x, 0, dt, "ms", FIFOout
		//Duplicate /FREE testPulse FIFOout	
		//FIFOout=testPulse*outGain*dacMultiplier[dacIndex]
		FIFOout=testPulse*outGain		// units: digitizer points
		FIFOout=min(max(-32768,FIFOout[p]),32767)	// limit to 16 bits
	endif
	//Variable seqLength=strlen(daSequence)		// will be 1 if no TTL, 2 if TTL
	
	// Specify the time windows for measuring the baseline and the pulse amplitude
	Variable totalDuration=2*duration
	Variable t0Base=0
	Variable tfBase=1/8*totalDuration
	Variable t0Pulse=5/8*totalDuration
	Variable tfPulse=6/8*totalDuration
		
	// Deliver test pulse, plot response, repeat until user wants to stop
	Variable base, pulse
	Variable timer
	Variable usElapsed
	Variable adcMode=DigitizerModelGetADCMode(adcIndex)
	Variable dacMode=DigitizerModelGetDACMode(dacIndex)		
	Variable i
	TitleBox proTipTitleBox,win=TestPulserView,disable=0		// tell the user how to break out of the loop
	timer=startMSTimer		// start the timer
	for (i=0; !EscapeKeyWasPressed(); i+=1)
		// execute the sample sequence
		Wave FIFOin=SamplerSampleData(adSequence,daSequence,FIFOout)
		// extract TestPulse_ADC from FIFOin
		if (ttlOutput)
			TestPulse_ADC=FIFOin[2*p]*inGain
		else
			TestPulse_ADC=FIFOin*inGain
		endif
		//KillWaves FIFOin		// Don't need FIFOin anymore
		if (doBaselineSubtraction)
			Wavestats /Q/R=[5,45] TestPulse_ADC
			TestPulse_ADC-=V_avg
		endif
		// If first iteration, do first-time things
		if (i==0)
			// if TestPulse_ADC is not currently being shown in the graph, append it
			String traceList=TraceNameList("TestPulserView",";",3)  // 3 means all traces
			Variable nTraces=ItemsInList(traceList)
			Variable waveInGraph=(nTraces>0)		// assume that if there's a wave in there, it's TestPulse_ADC	
			if (!waveInGraph)
				AppendToGraph /W=TestPulserView TestPulse_ADC
				ModifyGraph grid(left)=1
				ModifyGraph tickUnit(bottom)=1
			endif
			// set display range, axis labels, etc.
			TestPulserContYLimitsToTrace()
			TestPulserViewUpdateAxisLabels()
		endif
		// Calculate the seal resistance
		base=mean(TestPulse_ADC,t0Base,tfBase)
		pulse=mean(TestPulse_ADC,t0Pulse,tfPulse)
		if (adcMode==0 && dacMode==1)
			// ADC channel is a current channel, DAC channel is a voltage channel
			RSeal=amplitude/(pulse-base)
		elseif (adcMode==1 && dacMode==0)
			// output channel is a voltage channel
			RSeal=(pulse-base)/amplitude
		else
			//Printf "ADC and DAC channel for test pulse are of same type, therefore the 'resistance' is unitless!\r"
			RSeal=nan
		endif
		ValDisplay RSealValDisplay,win=TestPulserView,value= _NUM:RSeal
		WhiteOutIffNan("RSealValDisplay","TestPulserView",RSeal)
		// Calculate the update rate
		usElapsed=stopMSTimer(timer)
		// Make sure we really had a timer for that last iteration
		if (timer!=-1)
			updateRate=1e6/usElapsed	// Hz
		else
			updateRate=nan	// Hz
		endif		
		timer=startMSTimer
		ValDisplay updateRateValDisplay,win=TestPulserView,value= _NUM:updateRate
		//ValDisplay updateRateValDisplay,win=TestPulserView,value= _NUM:msElapsed2
		WhiteOutIffNan("updateRateValDisplay","TestPulserView",updateRate)
		// Update the graph
		DoUpdate /W=TestPulserView
	endfor
	usElapsed=stopMSTimer(timer)	// stop the timer, and free it
	//while (HaltProcedures()<1)
	TitleBox proTipTitleBox,win=TestPulserView,disable=1		// hide the tip

	//// Kill the graph
	//DoWindow /K TestPulseGraph
	
	// Bring the test pulse panel forward now that we're done
	DoWindow /F TestPulserView
	
	// Kill the ADC wave, so it's not hanging around in the DF after we exit
	//KillWaves TestPulse_ADC
	
	// Restore the original DF
	SetDataFolder savedDF
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContStartButton(ctrlName) : ButtonControl
	String ctrlName
	TestPulserContStart()
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserBaseSubCheckboxUsed(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	NVAR doBaselineSubtraction
	doBaselineSubtraction=checked
	
	SetDataFolder savedDF
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContTTLOutputCheckBox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	NVAR ttlOutput
	ttlOutput=checked
	SetVariable ttlOutChannelSetVariable, win=TestPulserView, disable=(ttlOutput?0:2)
	
	SetDataFolder savedDF
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserContYLimitsToTrace()
	// Adjusts the Y axis limits to accommodate the test pulse trace.
	// private method
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	if (WaveExists(TestPulse_ADC))	
		// set display range, axis labels, etc.
		Variable miny, maxy
		Wavestats /Q TestPulse_ADC
		miny=1.2*V_min
		maxy=1.2*V_max
		miny-=maxy/10
		if (miny>-0.2)
			miny=-0.2
		endif
		if (maxy<0.2)
			maxy=0.2
		endif
		Setaxis /W=TestPulserView left, miny, maxy
	endif

	SetDataFolder savedDF
End


