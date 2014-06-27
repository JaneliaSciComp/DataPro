#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function SweeperContConstructor()
	SweeperConstructor()
	SweeperViewConstructor()
End

Function SweeperControllerSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	// Callback for SetVariables that don't require any bounds checking or other special treatment
	String ctrlName
	Variable varNum
	String varStr
	String varName

	SweeperUpdateBuiltinPulseWave()	// Update this wave
	SweeperUpdateBuiltinTTLPulse()	// Update this wave
	SweeperViewSweeperChanged()	// Tell the view that the model has changed	
	OutputViewerContSweprWavsChngd()	// Tell the OutputViewer that the sweeper waves were (possibly) changed
End

Function SweeperContDtWantedSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	SweeperSetDtWanted(varNum)
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
	// private method, used to notify everyone that needs notifying after a change to dtWanted or totalDuration
	SweeperViewSweeperChanged()	// Tell the view that the model has changed
	BuilderContSweepDtOrTChngd("TTLPulse")
	BuilderContSweepDtOrTChngd("Pulse")
	BuilderContSweepDtOrTChngd("Sine")
	BuilderContSweepDtOrTChngd("PSC")
	BuilderContSweepDtOrTChngd("Ramp")
	BuilderContSweepDtOrTChngd("Train")
	BuilderContSweepDtOrTChngd("TrainWPP")
	BuilderContSweepDtOrTChngd("TTLTrain")
	BuilderContSweepDtOrTChngd("MulTrain")
	BuilderContSweepDtOrTChngd("TTLMTrain")
	BuilderContSweepDtOrTChngd("Stair")
	BuilderContSweepDtOrTChngd("Chirp")
	BuilderContSweepDtOrTChngd("WNoise")
	OutputViewerContSweprWavsChngd()	// Tell the OutputViewer that the sweeper waves have changed	
End

Function SCGetDataButtonPressed(ctrlName) : ButtonControl
	String ctrlName
	
	//if ( IsImagingModuleInUse() )
	//	Variable isTriggered=ImagerGetIsTriggered()
	//	if (isTriggered)
	//		ImagerContAcquireVideo()		// This will call SweeperControllerAcquireTrial()
	//	else
	//		SweeperControllerAcquireTrial()
	//	endif
	//else
	//	SweeperControllerAcquireTrial()
	//endif
	SweeperControllerAcquireTrial()
End

Function SweeperControllerADCCheckbox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	Variable iChannel=str2num(ctrlName[3])
	SweeperContSetADCChannelOn(iChannel,checked)
	SwitcherViewUpdate()
	ASwitcherViewUpdate()
	ImagerViewSomethingChanged()
End

Function SweeperContSetADCChannelOn(iChannel,on)
	Variable iChannel
	Variable on
	SweeperSetADCChannelOn(iChannel,on)
	SweeperViewADCEnablementChanged(iChannel)
End

Function SweeperControllerADCBaseNameSV(ctrlName,varNum,varStr,varName) : SetVariableControl
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

Function SweeperControllerDACCheckbox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	Variable iChannel=str2num(ctrlName[3])
	SweeperContSetDACChannelOn(iChannel,checked)
	SwitcherViewUpdate()
	ASwitcherViewUpdate()
End

Function SweeperContSetDACChannelOn(iChannel,on)
	Variable iChannel
	Variable on
	SweeperSetDACChannelOn(iChannel,on)
	SweeperViewDACEnablementChanged(iChannel)
End

Function SweeperControllerDACWavePopup(ctrlName,popNum,popStr) : PopupMenuControl
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

Function SweeperControllerDACMultiplier(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	
	WAVE dacMultiplier

	Variable i=str2num(ctrlName[13])  // DAC channel index
	//dacMultiplier[i]=varNum
	SweeperSetDACMultiplier(i,varNum)
	// The internal number is already set to i, so no need to update the view
		
	SetDataFolder savedDF
End

Function SweeperControllerTTLCheckbox(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	Variable iChannel=str2num(ctrlName[3])
	SweeperSetTTLOutputChannelOn(iChannel,checked)
	SweeperViewTTLEnablementChanged(iChannel)
	ImagerViewSomethingChanged()
End

Function SweeperControllerTTLWavePopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	Variable iChannel=str2num(ctrlName[3])
	SweeperSetTTLOutputWaveName(iChannel,popStr)
End

Function SweeperControllerAcquireTrial()
	// Acquire a single trial, which is composed of n sweeps
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Sweeper
	
	NVAR nSweepsPerTrial
	NVAR sweepInterval
	NVAR runHookFunctionsChecked
	
	Variable startTime, endTime, sweepDuration, sleepDuration 	// all in seconds
	String temp_comments, doit
	String comment
	
	// If called for, run the pre-trial hook function
	if (runHookFunctionsChecked)
		PreTrialHook()
	endif
	
	Variable iSweepWithinTrial
	for (iSweepWithinTrial=0;iSweepWithinTrial<nSweepsPerTrial; iSweepWithinTrial+=1)	
		if (nSweepsPerTrial==1)
			sprintf comment "stim %d of %d",iSweepWithinTrial+1,nSweepsPerTrial
		else
			sprintf comment "stim %d of %d, with inter-stim-interval of %g s",iSweepWithinTrial+1,nSweepsPerTrial,sweepInterval
		endif
		startTime = DateTime		// "Unlike most Igor functions, DateTime is used without parentheses."
		SweeperControllerAcquireSweep(comment,iSweepWithinTrial)
		endTime=DateTime
		sweepDuration=endTime-startTime
		sleepDuration=max(0,sweepInterval-sweepDuration)
		if (iSweepWithinTrial<nSweepsPerTrial-1)	// Don't sleep after the last sweep
 			Sleep /S sleepDuration	// sleep for sleepDuration seconds
 		endif
	endfor

	// If called for, run the post-trial hook function
	if (runHookFunctionsChecked)
		PostTrialHook()
	endif

	SetDataFolder savedDF
End

Function SweeperControllerAcquireSweep(comment,iSweepWithinTrial)
	// Acquire a single sweep, which consists of n traces, each trace corresponding to a single 
	// ADC channel.  Add the supplied comment to the acquired waves.
	String comment
	Variable iSweepWithinTrial
	
	// Get the number of all extant DP Browsers, so that we can tell them when sweeps get added
	Wave browserNumbers=GetAllBrowserNumbers()  // returns a free wave
	
	//// Save the current data folder, set it
	//String savedDF=GetDataFolder(1)
	//SetDataFolder root:DP_Sweeper
	
	// Bring the sweeper forward
	DoWindow /F SweepControl
	
	// Make sure the built-in stimuli are up-to-date	
	SweeperUpdateBuiltinPulseWave()
	SweeperUpdateBuiltinTTLPulse()
	
	// If called for, run the pre-sweep hook function
	Variable thisSweepIndex=SweeperGetNextSweepIndex()
	Variable runHookFunctionsChecked=SweeperGetDoRunHookFunctions()
	if (runHookFunctionsChecked)
		PreSweepHook(thisSweepIndex)
	endif
	
	// This is where Wave FIFOout=SweeperGetFIFOout() used to be
	
	// Get the ADC and DAC sequences from the model
	String daSequence=SweeperGetDACSequence()
	String adSequence=SweeperGetADCSequence()
	Variable seqLength=strlen(daSequence)		// both should be same length

	// If doing imaging, and triggered acquistion, configure the camera
	if ( IsImagingModuleInUse() && ImagerGetIsTriggered() )
		Variable wasVideoAcqStarted=ImagerContAcquireVideoStart()
		if (!wasVideoAcqStarted)
			Abort FancyCameraGetErrorMessage()
		endif
	endif

	// Get the wave that will be fed into the FIFO	(Have to do it after starting the video, b/c that's where the epi light gets turned on.
	Make /O /N=0 FIFOout
	SweeperGetFIFOoutBang(FIFOout)
	Variable nSamplesFIFO=numpnts(FIFOout)
	//Printf "nSamplesFIFO: %d\r", nSamplesFIFO
	// This shouldn't happen anymore, b/c the interface no longer allows it, but I'll leave it in
	if (numpnts(FIFOout)==0)
		Abort "There must be at least one valid DAC or TTL output wave"
	endif
	
	// Predict how many samples large the FIFO needs to be
	Variable nFIFOSamplesNeededNow=nFIFOSamplesNeeded(SweeperGetNumADCsOn(),SweeperGetNumDACsOn(),SweeperGetNumTTLOutputsOn(),SweeperGetNumberOfScans())
	//Printf "nFIFOSamplesNeededNow: %d\r", nFIFOSamplesNeededNow
	
	// Actually acquire the data for this sweep
	Variable absoluteTime=DateTime	// "Unlike most Igor functions, DateTime is used without parentheses."
	Make /O /N=(0) FIFOin
	SamplerSampleDataStart(adSequence,daSequence,FIFOout)
	
	// If doing imaging, and triggered acquistion, babysit the camera to get the frames without overflowing the buffer
	//Variable timerRef=startMSTimer
	//Sleep /S 10
	if ( IsImagingModuleInUse() && ImagerGetIsTriggered() )
		 ImagerContAcquireFramesLoop(thisSweepIndex)
	endif
	//Variable usElapsed=stopMSTimer(timerRef)
	//Variable secondsElapsed=usElapsed/1e6
	//Printf "Time inside (or skipping) ImagerContAcquireFramesLoop(): %f s\r", secondsElapsed

	// Now that that's done, read the data out of the digitizer once it's ready	
	SamplerSampleDataFinishBang(FIFOin,FIFOout)
	// raw acquired data is now in root:DP_Sweeper:FIFOin wave

	// Turn off the EpiLight (can't do this before getting the ephys data, b/c that screws up the digitizer)
	if ( IsImagingModuleInUse() && ImagerGetIsTriggered() )
		 EpiLightTurnOff()
		 ImagerViewEpiLightChanged()
	endif
		
	// Get the number of ADC channels in use
	Variable nADCInUse=SweeperGetNumADCsOn()
	
	// One subtle point is that that if there are multiple cycles through the ADC channels in the sequence,
	// all the repeats of the same ADC channel in the sequence will have the same sampled value.  Thus we 
	// the value of seqLength below in several places where naively you might think one would use nADCInUse.
	
	// Extract individual traces from FIFOin, store them in the appropriate waves
	//String nameOfVarHoldingADCWaveBaseName
	Variable iADCChannel		// index of the relevant ADC channel
	String stepAsString=StringByKeyInWaveNote(FIFOout,"STEP")	// will add to ADC waves	
	Variable nSamplesPerTrace=numpnts(FIFOin)/seqLength
	Variable adcNativesPerPoint
	Variable iTrace
	Variable dtFIFOin=deltax(FIFOin)
	String units
	for (iTrace=0; iTrace<nADCInUse; iTrace+=1)
		iADCChannel=str2num(adSequence[iTrace])
		String thisWaveNameRel=sprintf2sv("%s_%d", SweeperGetADCBaseName(iADCChannel), thisSweepIndex)
		String thisWaveNameAbs="root:"+thisWaveNameRel
		Make /O /N=(nSamplesPerTrace) $thisWaveNameAbs
		WAVE thisWave=$thisWaveNameAbs
		annotateADCWaveBang(thisWave,stepAsString,comment,absoluteTime)
		adcNativesPerPoint=DigitizerModelGetADCNtvsPerPnt(iADCChannel)
		thisWave=FIFOin[seqLength*p+iTrace]*adcNativesPerPoint
			// copy this trace out of the FIFO, and scale it by the gain
		Setscale /P x, 0, seqLength*dtFIFOin, "ms", thisWave
		units=DigitizerModelGetADCUnitsString(iADCChannel)
		SetScale d 0, 0, units, thisWave
	endfor

	// If doing imaging, and triggered acquistion, and using a faux camera, replace the exposure signal with a faked one
	if ( IsImagingModuleInUse() && ImagerGetIsTriggered() && !CameraGetIsForReal() )
		Variable interExposureDelay=0.001		// s, could be shift time for FT camera, or readout time for non-FT camera
		Variable exposureWantedInSeconds=0.001*ImagerGetVideoExposureWanted()
		Variable frameInterval=exposureWantedInSeconds+interExposureDelay		// s, Add a millisecond of shift time, for fun
		Variable frameOffset=exposureWantedInSeconds/2
		// Assumes the first exposure starts at t==0, so the middle of it occurs at exposureWantedInSeconds/2.
		// After that, the middle of the next exposure comes frameInterval later, etc.
		//SetScale /P z, 1000*frameOffset, 1000*frameInterval, "ms", bufferFrame		// s -> ms
		//bufferFrame=2^15+(2^12)*gnoise(1)
		//countReadFrameFake=0
		//bufferFrame=p
		
		// If there's a wave with base name "exposure" for this trial, overwrite it with a fake TTL exposure signal
		String exposureWaveNameRel=WaveNameFromBaseAndSweep("exposure",thisSweepIndex)
		String exposureWaveNameAbs=sprintf1s("root:%s",exposureWaveNameRel)
		if ( WaveExistsByName(exposureWaveNameAbs) )
			Wave exposure=$exposureWaveNameAbs
			Variable dt=DimDelta(exposure,0)	// ms
			Variable nScans=DimSize(exposure,0)
			Variable delay=ImagerGetTriggerDelay()	// ms
			Variable duration=1000*(frameInterval*ImagerGetNFramesForVideo())	// s->ms
			Variable pulseRate=1/frameInterval	// Hz
			Variable pulseDuration=1000*exposureWantedInSeconds	// s->ms
			Variable baseLevel=0		// V
			Variable amplitude=5		// V, for a TTL signal
			Make /FREE parameters={delay,duration,pulseRate,pulseDuration,baseLevel,amplitude}
			Make /FREE /T parameterNames={"delay","duration","pulseRate","pulseDuration","baseLevel","amplitude"}
			//fillTrainFromParamsBang(exposure,dt,nScans,parameters,parameterNames)
			//StimulusSetParams(exposure,parameters)
			
			// Have to fil the samples "manually", because want the WAVETYPE to stay "adc"
			String stimulusType="Train"
			String fillFunctionName=stimulusType+"FillFromParams"
			Funcref StimulusFillFromParamsSig fillFunction=$fillFunctionName
			fillFunction(exposure,parameters)
		endif
	endif

	// If doing imaging, and triggered acquistion, extract the ROI signals
	if ( IsImagingModuleInUse() && ImagerGetIsTriggered() )
		 ImagerContExtractROIs(thisSweepIndex)
	endif

	// Notify the sweeper model that a sweep has just been acquired
	SweeperSweepJustAcquired(thisSweepIndex,iSweepWithinTrial)
	//SweeperAddHistoryForSweep(thisSweepIndex,iSweepWithinTrial)
	//SweeperIncrementNextSweepIndex()
	
	// Update the sweep number in the DP Browsers
	Variable nBrowsers=numpnts(browserNumbers)
	Variable i
	for (i=0; i<nBrowsers; i+=1)
		BrowserContSetCurSweepIndex(browserNumbers[i],thisSweepIndex)
	endfor
	
	// Update the windows, so user can see the new sweep
	DoUpdate

	// If called for, run the post-sweep hook function
	if (runHookFunctionsChecked)
		PostSweepHook(thisSweepIndex)
	endif

	//// Restore the original data folder
	//SetDataFolder savedDF
End

Function SweeperControllerAddDACWave(w,waveNameString)
	Wave w
	String waveNameString
	if (IsEmptyString(waveNameString))
		return -1		// have to return something
	endif
	SweeperAddDACWave(w,waveNameString)
	SweeperViewSweeperChanged()
	OutputViewerContSweprWavsChngd()
End

Function SweeperControllerAddTTLWave(w,waveNameString)
	Wave w
	String waveNameString
	if (IsEmptyString(waveNameString))
		return -1		// have to return something
	endif
	SweeperAddTTLWave(w,waveNameString)
	SweeperViewSweeperChanged()
	OutputViewerContSweprWavsChngd()
End

Function SweepControllerDigitizerChanged()
	// Used to notify the SweeperController that the Digitizer model has changed.
	SweeperViewDigitizerChanged()
End

//Function SweeperContIncrNextSweepIndex()
//	SweeperIncrementNextSweepIndex()
//	SweeperViewSweeperChanged()
//End


//
// "Class methods" below here
//

Function annotateADCWaveBang(w,stepAsString,comment,absoluteTime)
	Wave w
	String stepAsString,comment
	Variable absoluteTime

	String dateString=Secs2Date(absoluteTime,-2);	// -2 sets format
	String timeString=Secs2Time(absoluteTime,3);	// 3 sets format

	Note /K w
	ReplaceStringByKeyInWaveNote(w,"COMMENTS",comment)	
	ReplaceStringByKeyInWaveNote(w,"WAVETYPE","adc")
	//ReplaceStringByKeyInWaveNote(w,"TIME",time())
	ReplaceStringByKeyInWaveNote(w,"TIMEABS",sprintf1v("%.17g",absoluteTime))
	ReplaceStringByKeyInWaveNote(w,"DATESTR",dateString)
	ReplaceStringByKeyInWaveNote(w,"TIMESTR",timeString)	
	ReplaceStringByKeyInWaveNote(w,"STEP",stepAsString)	
End

