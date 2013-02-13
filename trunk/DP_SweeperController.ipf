#pragma rtGlobals=1		// Use modern global access method.

Function SweeperControllerSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	// Callback for SetVariables that don't require any bounds checking
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SweeperParametersChanged()		// Make the model self-consistent
	SweeperViewSweeperChanged()	// Tell the view that the model has changed
End

Function SCGetDataButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	AcquireTrial()
End

Function HandleADCCheckbox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	Variable iADCChannel=str2num(ctrlName[3])
	WAVE adcChannelOn
	adcChannelOn[iADCChannel]=checked
	SetDataFolder savedDF
End

Function HandleADCBaseNameSetVariable(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper

	WAVE /T adcBaseName
	
	Variable i=str2num(ctrlName[3])  // ADC channel index
	adcBaseName[i]=varStr

	SetDataFolder savedDF
End

Function HandleDACCheckbox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	Variable iDACChannel=str2num(ctrlName[3])
	WAVE dacChannelOn
	dacChannelOn[iDACChannel]=checked
	SetDataFolder savedDF
End

Function HandleDACWavePopupMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper

	WAVE /T dacWavePopupSelection

	Variable iChannel	
	iChannel=str2num(ctrlName[3])
	dacWavePopupSelection[iChannel]=popStr

	SetDataFolder savedDF
End

Function HandleDACMultiplierSetVariable(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	
	WAVE dacMultiplier

	Variable i=str2num(ctrlName[13])  // DAC channel index
	dacMultiplier[i]=varNum
		
	SetDataFolder savedDF
End

Function HandleTTLCheckbox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	Variable iTTLChannel=str2num(ctrlName[3])
	WAVE ttlOutputChannelOn
	ttlOutputChannelOn[iTTLChannel]=checked
	SetDataFolder savedDF
End

Function HandleTTLWavePopupMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper

	WAVE /T ttlWavePopupSelection

	Variable iChannel
	iChannel=str2num(ctrlName[3])
	ttlWavePopupSelection[iChannel]=popStr

	SetDataFolder savedDF
End

Function AcquireTrial()
	// Acquire a single trial, which is composed of n sweeps
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	Variable start_time, last_time
	String temp_comments, doit
	NVAR nSweepsPerTrial
	NVAR sweepInterval
	//NVAR error
	String comment
	Variable iSweepWithinTrial
	for (iSweepWithinTrial=0;iSweepWithinTrial<nSweepsPerTrial; iSweepWithinTrial+=1)	
		if (iSweepWithinTrial<1)
			start_time = DateTime
		else
			start_time = last_time + sweepInterval
		endif
		if (nSweepsPerTrial==1)
			sprintf comment "stim %d of %d",iSweepWithinTrial+1,nSweepsPerTrial
		else
			sprintf comment "stim %d of %d, with inter-stim-interval of %d",iSweepWithinTrial+1,nSweepsPerTrial,sweepInterval
		endif
		sprintf doit, "Sleep /A %s", Secs2Time(start_time,3)
		Execute doit
		AcquireSweep(comment)  // this calls DoUpdate() inside
		//if (error>0)
		//	error=0
		//	Abort 
		//endif
		last_time = start_time
		//SaveStimHistory()
	endfor
	//comment=""
	SetDataFolder savedDF
End

Function AnnotateADCWaveBang(w,stepAsString,comment)
	Wave w
	String stepAsString,comment

	Note /K w
	ReplaceStringByKeyInWaveNote(w,"COMMENTS",comment)	
	ReplaceStringByKeyInWaveNote(w,"WAVETYPE","adc")
	ReplaceStringByKeyInWaveNote(w,"TIME",time())
	ReplaceStringByKeyInWaveNote(w,"STEP",stepAsString)	
End

Function AcquireSweep(comment)
	// Acquire a single sweep, which consists of n traces, each trace corresponding to a single 
	// ADC channel.  Add the supplied comment to the acquired waves.
	String comment
	
	// Get the number of all extant DP Browsers, so that we can tell them when sweeps get added
	Wave browserNumbers=GetAllBrowserNumbers()  // returns a free wave
	
	// Save the current data folder, set it
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	
	NVAR iSweep
	WAVE /T adcBaseName
	NVAR autoAnalyzeChecked

	String thisWaveNameRel
	//String savename
	String thisstr, doit, whichadc
	Variable leftmin, leftmax
	
	DoWindow /F SweepControl	
	StepPulseParametersChanged()
	SynPulseParametersChanged()
	Wave FIFOout=GetFIFOout()
	if (numpnts(FIFOout)==0)
		Abort "There must be at least one valid DAC or TTL output wave"
	endif
	
	// Get the ADC and DAC sequences from the model
	String daseq=GetDACSequence()
	String adseq=GetADCSequence()
	Variable seqLength=GetSequenceLength()

	// Actually acquire the data for this sweep
	Wave FIFOin=SamplerSampleData(adseq,daseq,seqLength,FIFOout) 
	// raw acquired data is now in root:DP_Sweeper:FIFOin wave
		
	// Get the number of ADC channels in use
	Variable nADCInUse=GetNumADCChannelsInUse()
	
	// Extract individual traces from FIFOin, store them in the appropriate waves
	//String nameOfVarHoldingADCWaveBaseName
	WAVE /T unitsFromMode
	Variable iADCChannel		// index of the relevant ADC channel
	WAVE adcMode	// wave s.t. adcMode[i] gives the channel type-code for ADC i
	String stepAsString=StringByKeyInWaveNote(FIFOout,"STEP")	// will add to ADC waves	
	Variable nSamplesPerTrace=numpnts(FIFOin)/nADCInUse
	Variable ingain
	Variable iTrace
	Variable dtFIFOin=deltax(FIFOin)
	String units
	for (iTrace=0; iTrace<nADCInUse; iTrace+=1)
		SetDataFolder root:DP_Sweeper  // added by ALT 2012-05-23
			// Must be here for adc1, adc2, etc. to get saved to waves with the right names
		iADCChannel=str2num(adseq[iTrace])
		//sprintf nameOfVarHoldingADCWaveBaseName "adcBaseName%d", iADCChannel
		//SVAR base=$nameOfVarHoldingADCWaveBaseName
		sprintf thisWaveNameRel "%s_%d", adcBaseName[iTrace], iSweep
		//sprintf savename "%s.bwav", thisWaveNameRel
		SetDataFolder root:
		Make /O /N=(nSamplesPerTrace) $thisWaveNameRel
		String thisWaveNameAbs="root:"+thisWaveNameRel
		WAVE thisWave=$thisWaveNameAbs
		AnnotateADCWaveBang(thisWave,stepAsString,comment)
		ingain=GetADCNativeUnitsPerPoint(iADCChannel)
		thisWave=FIFOin[nADCInUse*p+iTrace]*ingain
			// copy this trace out of the FIFO, and scale it by the gain
		Setscale /P x, 0, nADCInUse*dtFIFOin, "ms", thisWave
		//units=unitsFromMode[adcMode[iADCChannel]]
		units=GetADCChannelUnitsString(iADCChannel)
		SetScale d 0, 0, units, thisWave
		//Save /O /P=home thisWave as savename
	endfor
	
	// Update the sweep number in the DP Browsers
	Variable nBrowsers=numpnts(browserNumbers)
	Variable i
	for (i=0;i<nBrowsers;i+=1)
		SetICurrentSweepAndSyncView(browserNumbers[i],iSweep)
	endfor
	
	// Update some of the acquisition counters
	iSweep+=1
	
	// Update the windows, so user can see the new sweep
	DoUpdate

	// If called for, run the per-user function
	if (autoAnalyzeChecked)
		AutoAnalyze()
		DoUpdate
	endif

	// Restore the original data folder
	SetDataFolder savedDF
End

