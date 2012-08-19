#pragma rtGlobals=1		// Use modern global access method.

Function SetICurrentSweep(browserNumber,sweepIndexNew)
	// Set the current sweep index to something, which is assumed to be valid.
	Variable browserNumber, sweepIndexNew

	// Change to the right DF
	String savedDFName=ChangeToBrowserDF(browserNumber)
	
	// Set iCurrentSweep, then update the measurements
	NVAR iCurrentSweep
	iCurrentSweep=sweepIndexNew
	UpdateMeasurements(browserNumber)
	
	// Restore the original DF
	SetDataFolder savedDFName	
End

Function /S GetTopTraceWaveNameAbs(browserNumber)
	// Returns the absolute wave name of the "top" trace, or the emprty string if no trace is showing.
	// If trace A is showing, it is the top trace.  Otherwise, if trace B is showing, it is the top trace.
	// Otherwise, there is no top trace.
	Variable browserNumber

	// Find name of top browser, switch the DF to its DF, note the former DF name
	//Variable browserNumber=GetTopBrowserNumber()
	String savedDFName=ChangeToBrowserDF(browserNumber)
	
	NVAR iCurrentSweep=iCurrentSweep
	NVAR traceAChecked=traceAChecked
	NVAR traceBChecked=traceBChecked	
	SVAR baseNameA=baseNameA, baseNameB=baseNameB

	String traceAWaveName=GetTraceAWaveNameAbs(browserNumber)
	String traceBWaveName=GetTraceBWaveNameAbs(browserNumber)
	Variable waveAExists=WaveExists($traceAWaveName)
	Variable waveBExists=WaveExists($traceBWaveName)

	String retval
	if (traceAChecked && waveAExists)
		retval=traceAWaveName
	elseif (traceBChecked && waveBExists)
		retval=traceBWaveName
	else
		retval=""
	endif

	// Restore old data folder
	SetDataFolder savedDFName
	
	return retval
End

Function /S GetTopTraceWaveNameRel(browserNumber)
	// Returns the wave name of the "top" trace, relative to the data folder containing it, or the empty 
	// string if no 
	// trace is showing.
	// If trace A is showing, it is the top trace.  Otherwise, if trace B is showing, it is the top trace.
	// Otherwise, there is no top trace.
	Variable browserNumber

	// Find name of top browser, switch the DF to its DF, note the former DF name
	//Variable browserNumber=GetTopBrowserNumber()
	String savedDFName=ChangeToBrowserDF(browserNumber)
	
	NVAR iCurrentSweep=iCurrentSweep
	NVAR traceAChecked=traceAChecked
	NVAR traceBChecked=traceBChecked	
	SVAR baseNameA=baseNameA, baseNameB=baseNameB

	String traceAWaveNameRel=GetTraceAWaveNameRel(browserNumber)
	String traceBWaveNameRel=GetTraceBWaveNameRel(browserNumber)
	String traceAWaveNameAbs=GetTraceAWaveNameAbs(browserNumber)
	String traceBWaveNameAbs=GetTraceBWaveNameAbs(browserNumber)
	Variable waveAExists=WaveExists($traceAWaveNameAbs)
	Variable waveBExists=WaveExists($traceBWaveNameAbs)

	String retval
	if (traceAChecked && waveAExists)
		retval=traceAWaveNameRel
	elseif (traceBChecked && waveBExists)
		retval=traceBWaveNameRel
	else
		retval=""
	endif

	// Restore old data folder
	SetDataFolder savedDFName
	
	return retval
End

Function /S GetTraceAWaveNameAbs(browserNumber)
	// Construct the absolute wave name of trace A in the given browser number.  Note that this wave may or
	// may not exist.
	Variable browserNumber
	return "root:"+GetTraceAWaveNameRel(browserNumber)
End

Function /S GetTraceBWaveNameAbs(browserNumber)
	// Construct the absolute wave name of trace B in the given browser number.  Note that this wave may 
	// or may not exist.
	Variable browserNumber
	return "root:"+GetTraceBWaveNameRel(browserNumber)
End

Function /S GetTraceAWaveNameRel(browserNumber)
	// Construct the wave name of trace A in the given browser number, relative to the data folder containing it.  
	// Note that this wave may or may not exist.
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iCurrentSweep=iCurrentSweep
	SVAR baseNameA=baseNameA
	String retval=sprintf2sd("%s%d", baseNameA, iCurrentSweep)
	SetDataFolder savedDFName
	return retval
End

Function /S GetTraceBWaveNameRel(browserNumber)
	// Construct the wave name of trace B in the given browser number, relative to the data folder containing it.  
	// Note that this wave may or may not exist.
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iCurrentSweep=iCurrentSweep
	SVAR baseNameB=baseNameB
	String retval=sprintf2sd("%s%d", baseNameB, iCurrentSweep)
	SetDataFolder savedDFName
	return retval
End

Function RemoveBaseNamedWaves(base)
	String base
	String savDF, targetWindow, allwaves, thiswave
	Variable i
	savDF=GetDataFolder(1)
	SetDataFolder root:
	base+="*"
	sprintf targetWindow, "WIN:"
	allwaves=WaveList(base,";", targetWindow)
	if (strlen(allwaves)>0)
		i=0
		do
			thiswave=GetStrFromList(allwaves,i,";")
			if (strlen(thiswave)==0)
				break
			else
				RemoveFromGraph $thiswave
			endif
			i+=1
		while(1)
	endif
	SetDataFolder savDF
End

//Function SyncCommentsToTopTrace(browserNumber)
//	// Read the comments out of the currently-showing wave, and update the comments variable.
//	// (This will update the view b/c of the binding.)
//	Variable browserNumber
//
//	// Find name of top browser, switch the DF to its DF, note the former DF name
//	String savDF=ChangeToBrowserDF(browserNumber)
//
//	SVAR comments
//	String topTraceWaveName=GetTopTraceWaveNameAbs(browserNumber)
//	if (strlen(topTraceWaveName)==0)
//		comments=""
//	else
//		String noteString=note($topTraceWaveName)
//		comments=StringByKey("COMMENTS",noteString,"=","\r",1)
//	endif
//	
//	// Restore the original DF
//	SetDataFolder savDF
//End

Function DoBaseSub(browserNumber)
	// Perform baseline subtraction on $traceAWaveName and $traceBWaveName.
	// Each wave's note says whether it has had the baseline subtracted, and also
	// contains the baseline value for that wave.
	Variable browserNumber
	
	// Switch the DF, note the former DF name
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get DF vars we need
	NVAR traceAChecked=traceAChecked
	
	String traceAWaveName=GetTraceAWaveNameAbs(browserNumber)
	WAVE theWave=$traceAWaveName
	Variable basesubtracted, baseline
	if ( traceAChecked && WaveExists($traceAWaveName) )
		baseline=NumberByKeyInWaveNote(theWave,"BASELINE")
		basesubtracted=NumberByKeyInWaveNote(theWave,"BASESUBTRACTED")
	endif

	String traceBWaveName=GetTraceBWaveNameAbs(browserNumber)
	ControlInfo basesub1
	if ( (V_value>0) && WaveExists(traceBWaveName) )			// if baseline subtract is checked
		 if (basesubtracted<1)							// but the baseline isn't subtracted
			theWave -=  baseline							// subtract baseline
			ReplaceStringByKeyInWaveNote($traceAWaveName,"BASESUBTRACTED","1")	// and note baseline subtracted
		endif
	else												// if baseline subtract is not checked
		 if (basesubtracted>0)							// but the baseline is subtracted
			theWave +=  baseline							// add back the baseline
			ReplaceStringByKeyInWaveNote($traceAWaveName,"BASESUBTRACTED","0")	// and note baseline not subtracted
		endif
	endif

	NVAR traceBChecked=traceBChecked
	if ( traceBChecked && WaveExists(traceBWaveName) )
		WAVE theWave=$traceBWaveName
		baseline=NumberByKeyInWaveNote(theWave,"BASELINE")
		basesubtracted=NumberByKeyInWaveNote(theWave,"BASESUBTRACTED")
	endif

	ControlInfo basesub2
	if ( (V_value>0) && WaveExists(traceBWaveName) )				// if baseline subtract is checked
		 if (basesubtracted<1)							// but the baseline isn't subtracted
			theWave -=  baseline							// subtract baseline
			ReplaceStringByKeyInWaveNote(theWave,"BASESUBTRACTED","1")	// and note baseline subtracted
		endif
	else												// if baseline subtract is not checked
		 if (basesubtracted>0)							// but the baseline is subtracted
			theWave +=  baseline							// add back the baseline
			ReplaceStringByKeyInWaveNote(theWave,"BASESUBTRACTED","0")	// and note baseline not subtracted
		endif
	endif
	
	// Restore the original DF.
	SetDataFolder savedDFName
End

Function UpdateMeasurements(browserNumber)
	// Updates the values displayed in the Measure part of the Tools Panel to reflect the wave 
	// currently displayed in
	// the DP Browser, given the current measurement parameters in the DF.
	// This is essentially syncing the measured values (part of the model) to the rest of the model 
	// (containing the waves and the measurement cursor positions).  The bindings between the 
	// measured values and the various controls in the Measure panel view take care of updating the
	// view to reflect the altered model.
	Variable browserNumber  // the index of the DP browser instance
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)
	
	// Get references to all the variables that we need in this data folder
	//NVAR baselineA, step1, baselineB, step2
	// inputs to the measurement process
	NVAR tBaselineLeft, tBaselineRight
	NVAR tWindow1Left, tWindow1Right
	NVAR tWindow2Left, tWindow2Right
	NVAR to1, from1
	NVAR to2, from2
	NVAR lev1
	// outputs of the measurement process
	NVAR baseline, mean1, peak1, rise1
	NVAR mean2, peak2, rise2
	NVAR cross1
	
	// If there's a top wave, calculate features of it
	String topTraceWaveName=GetTopTraceWaveNameAbs(browserNumber)
	if (strlen(topTraceWaveName)>0)
		// Calculate the baseline
		WAVE thisWave=$topTraceWaveName
		if ( IsFinite(tBaselineLeft) && IsFinite(tBaselineRight) )
			baseline=mean($topTraceWaveName,tBaselineLeft,tBaselineRight)
		else
			baseline=NaN
		endif
		
		// Calculate features of window 1
		if ( IsFinite(tWindow1Left) && IsFinite(tWindow1Right) )
			WaveStats /Q/R=(tWindow1Left,tWindow1Right) thisWave
			mean1=V_avg-baseline
			if (abs(V_min-baseline)>abs(V_max-baseline))
				peak1=V_min-baseline
			else
				peak1=V_max-baseline	
			endif
			rise1=RiseTime(thisWave,tWindow1Left,tWindow1Right,baseline,peak1,from1/100,to1/100)
			cross1=CountThresholdCrossings(topTraceWaveName, tWindow1Left, tWindow1Right, lev1)
		else
			mean1=NaN
			peak1=NaN
			rise1=NaN
		endif
		
		// Calculate features of window 2
		if ( IsFinite(tWindow2Left) && IsFinite(tWindow2Right) )
			WaveStats /Q/R=(tWindow2Left,tWindow2Right) thisWave
			mean2=V_avg-baseline
			if (abs(V_min-baseline)>abs(V_max-baseline))
				peak2=V_min-baseline
			else
				peak2=V_max-baseline		
			endif
			rise2=RiseTime(thisWave,tWindow2Left,tWindow2Right,baseline,peak2,from2/100,to2/100)
		else
			mean2=NaN
			peak2=NaN
			rise2=NaN
		endif
	else
		// If no traces are showing
		baseline=NaN
		mean1=NaN
		peak1=NaN
		rise1=NaN
		mean2=NaN
		peak2=NaN
		rise2=NaN		
	endif
	
	// Restore the original data folder
	SetDataFolder savedDF
End

Function InvalidateFit(browserNumber)
	// This is a model method that marks the fit coefficients as not being valid
	Variable browserNumber
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// the instance vars we''ll need
	NVAR isFitValid
	SVAR waveNameAbsOfFitTrace
	NVAR amp1, tau1, amp2, tau2, yOffset

	// mark the fit as invalid
	isFitValid=0
	
	// set this guy to empty, to keep ourselves out of trouble
	waveNameAbsOfFitTrace=""
	
	// don't really need to nan-out coeffs, but what the hell
	amp1=nan
	tau1=nan
	amp2=nan
	tau2=nan
	yOffset=nan

	// there may still be a yFit wave in the current workspace, but if the view does it's job, it
	// will never be seen
End

Function UpdateFit(browserNumber)
	// A model method (in spirit), changes the yFit wave and the fit coefficient instance variables to reflect 
	// the current fit window, trace, and fit parameters.
	Variable browserNumber
	
	//Printf "In UpdateFit()\r"
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get the DF vars we'll need
	//SVAR traceAWaveName=traceAWaveName
	NVAR tFitZero
	NVAR tFitLeft
	NVAR tFitRight
	// If the offset to be held fixed?  To what value?
	NVAR holdYOffset  // boolean
	NVAR yOffsetHeldValue
	// The fit parameters
	NVAR isFitValid
	SVAR waveNameAbsOfFitTrace
	NVAR yOffset, amp1, tau1, amp2, tau2

	// See if everything is set up to do a fit.  If not, return.
	String topTraceWaveName=GetTopTraceWaveNameAbs(browserNumber)
	if ( strlen(topTraceWaveName)==0 || IsNan(tFitZero) || IsNan(tFitLeft) || IsNan(tFitRight) )
		isFitValid=0
		return nan
	endif
	
	// Store the name of the wave that the fit is going to be done on
	waveNameAbsOfFitTrace=topTraceWaveName
	
	// Make a new wave, fitWave, that's a copy of $topTraceWaveName with the time base shifted 
	// to put tFitZero at t==0
	Duplicate /O $topTraceWaveName fitWave
	Variable tLeftShifted=leftx($topTraceWaveName)-tFitZero
	Variable tRightShifted=rightx($topTraceWaveName)-tFitZero
	Setscale x, tLeftShifted,tRightShifted, "ms", fitWave

	// Are we doing single or double exponential fit?
	SVAR fitType
	Variable singleExp=AreStringsEqual(fitType,"single exp")

	// Build up the command to do the fit, keeping it in the string commandString
	String commandString="CurveFit /N "
	// Specify coefficients to be held fixed
	if (singleExp)
		if (holdYOffset)
			commandString+="/H=\"100\" "
		endif
	else
		if (holdYOffset)
			commandString+="/H=\"10000\" "
		endif
	endif
	// Specify single- or double-exponential fit
	if (singleExp)
		commandString += "exp, "
	else	
		commandString += "dblexp, "
	endif
	// specify an explicit wave of coeffs, used both for reading values to be held fixed, and
	// for outputing the final fit coeffs
	if (singleExp)
 		Make /O/N=3 coeffs
 	else
 		Make /O/N=5 coeffs
 	endif
	if (holdYOffset)
		coeffs[0]=yOffsetHeldValue
	endif
	commandString+="kwCWave=coeffs "	
	commandString+="fitWave(tFitLeft-tFitZero,tFitRight-tFitZero)"
	
	// Execute the command to do the fit, unpack the coefficients into DP Browser vars
	Execute commandString
	yOffset=coeffs[0]
	amp1=coeffs[1]
	tau1=1/coeffs[2]
	if (singleExp)
		amp2=nan
		tau2=nan
	else
		amp2=coeffs[3]
		tau2=1/coeffs[4]
	endif
	
	// Make a wave, yFit, containing the fit curve
	Make /O /N=500 yFit
	NVAR dtFitExtend
	Setscale /I x, tFitZero, tFitRight+dtFitExtend, "ms", yFit
	if (singleExp)
		yFit= yOffset+amp1*exp(-(x-tFitZero)/tau1)
	else
		yFit= yOffset+amp1*exp(-(x-tFitZero)/tau1)+amp2*exp(-(x-tFitZero)/tau2)
	endif

	// Mark the fit as valid
	isFitValid=1
	
	//// Add the fit wave to the DP Browser window
	//String browserName=BrowserNameFromNumber(browserNumber)
	//String windowSpec=sprintf1s("WIN:%s",browserName)
	//f (ItemsInList(WaveList("yFit",";",windowSpec))>0)
	//	RemoveFromGraph yFit  // remove if already present
	//endif
	//AppendToGraph yFit

	// Restore original DF
	SetDataFolder savedDFName
End

Function MarkWaveForAveraging(thisWaveName,filterOnHold,holdCenter,holdTol,filterOnStep,stepCenter)
	// Set the DONTAVG wave note on the named wave, based on whether if satisfies the conditions
	// as specified by checkHold, holdCenter, etc.
	// We assume that thisWaveName is in the current DF, or is an absolute wave name.
	String thisWaveName
	Variable filterOnHold	// boolean
	Variable holdCenter, holdTol
	Variable filterOnStep	// boolean
	Variable stepCenter

	// The default is to include the wave in the average, then we check for a bunch of possible
	// reasons to exclude it
	WAVE thisWave=$thisWaveName
	Variable dontavg=0  // boolean
	String waveTypeStr=StringByKeyInWaveNote(thisWave, "WAVETYPE")
	if (cmpstr(waveTypeStr,"average")==0)
		dontavg = 1
	endif
	if (!dontavg && NumberByKeyInWaveNote(thisWave, "REJECT"))
		dontavg = 1
	endif
	if (!dontavg && filterOnHold)
		Variable hold=NumberByKeyInWaveNote(thisWave, "BASELINE")
		if ( abs(hold-holdCenter)>holdTol )
			dontavg = 1
		endif
	endif
	if (!dontavg && filterOnStep)
		Variable step=NumberByKeyInWaveNote(thisWave, "STEP")
		if (abs(step-stepCenter)>0.1)  // tolerance is hard-coded
			dontavg = 1
		endif
	endif
	ReplaceStringByKeyInWaveNote(thisWave,"DONTAVG",num2str(dontavg))
End

Function IncludeInAverage(thisWaveName,filterOnHold,holdCenter,holdTol,filterOnStep,stepCenter)
	// Determine whether to include thisWaveName in the average, based on whether if satisfies the 
	// conditions as specified by checkHold, holdCenter, etc.
	// We assume that thisWaveName is in the current DF, or is an absolute wave name.
	// Returns 1 is wave should be included in average, zero otherwise.
	String thisWaveName
	Variable filterOnHold	// boolean
	Variable holdCenter, holdTol
	Variable filterOnStep	// boolean
	Variable stepCenter

	// The default is to include the wave in the average, then we check for a bunch of possible
	// reasons to exclude it
	WAVE thisWave=$thisWaveName
	Variable include=1  // boolean
	String waveTypeStr=StringByKeyInWaveNote(thisWave, "WAVETYPE")
	if (AreStringsEqual(waveTypeStr,"average"))
		include=0
	endif
	if (include && NumberByKeyInWaveNote(thisWave, "REJECT"))
		include=0
	endif
	if (include && filterOnHold)
		Variable hold=NumberByKeyInWaveNote(thisWave, "HOLD")
		if ( abs(hold-holdCenter)>holdTol )
			include=0
		endif
	endif
	if (include && filterOnStep)
		Variable step=NumberByKeyInWaveNote(thisWave, "STEP")
		if (abs(step-stepCenter)>0.1)  // tolerance is hard-coded
			include=0
		endif
	endif
	return include
End
