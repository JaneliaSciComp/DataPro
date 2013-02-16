#pragma rtGlobals=1		// Use modern global access method.

Function SweeperControllerSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	// Callback for SetVariables that don't require any bounds checking or other special treatment
	String ctrlName
	Variable varNum
	String varStr
	String varName

	SweeperUpdateStepPulseWave()	// Update this wave
	SweeperUpdateSynPulseWave()	// Update this wave
	SweeperViewSweeperChanged()	// Tell the view that the model has changed	
	OVControllerSweeperWavesChanged()	// Tell the OutputViewer that the sweeper waves were (possibly) changed
End

Function SweeperControllerDtSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	SweeperSetDt(varNum)
	SweepContDtOrTotalDurChanged()
End

Function SweepContTotalDurationSVTwid(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	SweeperSetTotalDuration(varNum)
	SweepContDtOrTotalDurChanged()
End

Function SweepContDtOrTotalDurChanged()
	// private method, used to notify everyone that needs notifying after a change to dt or totalDuration
	SweeperViewSweeperChanged()	// Tell the view that the model has changed
	SineBuilderContSweepDtOrTChngd()
	PSCBuilderContSweepDtOrTChngd()
	RampBuilderContSweepDtOrTChngd()
	TrainBuilderContSweepDtOrTChngd()
	StepBuilderContSweepDtOrTChngd()
	OVControllerSweeperWavesChanged()	// Tell the OutputViewer that the sweeper waves have changed	
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
	SweeperViewDACEnablementChanged(iDACChannel)	
	SetDataFolder savedDF
End

Function HandleDACWavePopupMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper

	WAVE /T dacWaveName

	Variable iChannel	
	iChannel=str2num(ctrlName[3])
	dacWaveName[iChannel]=popStr

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
	SweeperViewTTLEnablementChanged(iTTLChannel)
	SetDataFolder savedDF
End

Function HandleTTLWavePopupMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper

	WAVE /T ttlOutputWaveName

	Variable iChannel
	iChannel=str2num(ctrlName[3])
	ttlOutputWaveName[iChannel]=popStr

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
	SweeperUpdateStepPulseWave()
	SweeperUpdateSynPulseWave()
	Wave FIFOout=GetFIFOout()
	if (numpnts(FIFOout)==0)
		Abort "There must be at least one valid DAC or TTL output wave"
	endif
	
	// Get the ADC and DAC sequences from the model
	String daSequence=GetDACSequence()
	String adSequence=GetADCSequence()
	Variable seqLength=GetSequenceLength()

	// Actually acquire the data for this sweep
	Wave FIFOin=SamplerSampleData(adSequence,daSequence,seqLength,FIFOout) 
	// raw acquired data is now in root:DP_Sweeper:FIFOin wave
		
	// Get the number of ADC channels in use
	Variable nADCInUse=GetNumADCChannelsInUse()
	
	// Extract individual traces from FIFOin, store them in the appropriate waves
	//String nameOfVarHoldingADCWaveBaseName
	Variable iADCChannel		// index of the relevant ADC channel
	String stepAsString=StringByKeyInWaveNote(FIFOout,"STEP")	// will add to ADC waves	
	Variable nSamplesPerTrace=numpnts(FIFOin)/nADCInUse
	Variable ingain
	Variable iTrace
	Variable dtFIFOin=deltax(FIFOin)
	String units
	for (iTrace=0; iTrace<nADCInUse; iTrace+=1)
		iADCChannel=str2num(adSequence[iTrace])
		sprintf thisWaveNameRel "%s_%d", adcBaseName[iTrace], iSweep
		String thisWaveNameAbs="root:"+thisWaveNameRel
		Make /O /N=(nSamplesPerTrace) $thisWaveNameAbs
		WAVE thisWave=$thisWaveNameAbs
		AnnotateADCWaveBang(thisWave,stepAsString,comment)
		ingain=GetADCNativeUnitsPerPoint(iADCChannel)
		thisWave=FIFOin[nADCInUse*p+iTrace]*ingain
			// copy this trace out of the FIFO, and scale it by the gain
		Setscale /P x, 0, nADCInUse*dtFIFOin, "ms", thisWave
		units=GetADCChannelUnitsString(iADCChannel)
		SetScale d 0, 0, units, thisWave
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

Function SweeperControllerAddDACWave(w,waveNameString)
	Wave w
	String waveNameString
	if (IsEmptyString(waveNameString))
		return -1		// have to return something
	endif
	SweeperAddDACWave(w,waveNameString)
	SweeperViewSweeperChanged()
	OVControllerSweeperWavesChanged()
End

Function SweeperControllerAddTTLWave(w,waveNameString)
	Wave w
	String waveNameString
	if (IsEmptyString(waveNameString))
		return -1		// have to return something
	endif
	SweeperAddTTLWave(w,waveNameString)
	SweeperViewSweeperChanged()
	OVControllerSweeperWavesChanged()
End

//Function SweepContAddDACOrTTLWave(w,waveNameString)
//	Wave w
//	String waveNameString
//	SweeperAddDACOrTTLWave(w,waveNameString)
//	SweeperViewSweeperChanged()
//	OVControllerSweeperWavesChanged()
//End

Function SweepControllerDigitizerChanged()
	// Used to notify the SweeperController that the Digitizer model has changed.
	SweeperViewDigitizerChanged()
End
