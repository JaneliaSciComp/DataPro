#pragma rtGlobals=1		// Use modern global access method.

Function BrowserModelConstructor()
	// Figure out what the index of this DataProBrowser instance should be
	Variable browserNumber
	browserNumber=LargestBrowserNumber()+1

	// Save the current DF
	String savedDF=GetDataFolder(1)	

	// Create a new data folder for this instance to store some state variables in, switch to it
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	NewDataFolder /O/S $browserDFName

	//// References for globals not in our own DF
	//SVAR baseNameANow=root:DP_Digitizer:adcname0
	//SVAR baseNameBNow=root:DP_Digitizer:adcname1

	// Create the state variables for this instance
	//Variable /G iOldSweep,
	String /G baseNameA="ad0"
	String /G baseNameB="ad1"
	Variable /G iCurrentSweep=1
	Variable /G tCursorA=nan		// the current time position of cursor A, or nan if that's not set
	Variable /G tCursorB=nan		// the current time position of cursor B, or nan if that's not set
		// Note that Cursor A is not associated with trace A, per se
		// Note that Cursor B is not associated with trace B, per se
	Variable /G showToolsChecked=0  // boolean, "ShowTools" is a built-in, so can't use that
	Variable /G traceAChecked=1, traceBChecked=0
	Variable /G xAutoscaling=1, yAAutoscaling=1, yBAutoscaling=1
	//String /G traceAWaveName, traceBWaveName
	// If both channel 1 and 2 are currently showing, then topTraceWaveName==traceAWaveName.  If only
	// one or the other is showing, topTraceWaveName equals the one showing.  If neither is showing, then
	// topTraceWaveName==""
	//String /G topTraceWaveName  
	//String /G comments
	String /G cursorWaveList=""

	// These store the current y limits for the trace A and trace B axis, if they are showing, or
	// what the values were the last time they were showing, if they are not showing.
	// If they have never been shown, they are set to the defaults below.
	// If auto-scaling of an axis is turned off, then the axis limits get set to these values when it is 
	// shown.
	Variable /G yAMin=-10
	Variable /G yAMax=10
	Variable /G yBMin=-10
	Variable /G yBMax=10
	Variable /G xMin=0
	Variable /G xMax=100

	// Create the globals related to the measure subpanel
	//String /G baselineWaveName=""
	Variable /G tBaselineLeft=nan
	Variable /G tBaselineRight=nan
	//String /G dataWindow1WaveName=""
	Variable /G tWindow1Left=nan
	Variable /G tWindow1Right=nan
	//String /G dataWindow2WaveName=""
	Variable /G tWindow2Left=nan
	Variable /G tWindow2Right=nan
	Variable /G from1=10, to1=90	// these are parameters
	Variable /G from2=90, to2=10
	Variable /G level1=0  // this is a param
	Variable /G baseline=nan, mean1=nan, peak1=nan, rise1=nan  	// these are statistics
	Variable /G nCrossings1=nan
	Variable /G mean2=nan, peak2=nan, rise2=nan
	
	// Create the globals related to the fit subpanel
	// The UI is designed so that if the user has done a fit, changing any of the fit params causes the fit to update.
	// We keep track of what wave the fit applies to.
	// If the user changes the current sweep, the fit does not automatically get done on the new sweep.  The user has to hit
	// the Fit button to make that happen.  All of this is by design.
	Variable /G isFitValid=0  	// true iff the current fit coefficients represent the output of a valid fit
							// to waveNameAbsOfFitTrace, with the current fit parameters
	String /G waveNameAbsOfFitTrace=""
	String /G fitType="Exponential" 
	Variable /G tFitZero=nan
	Variable /G tFitLeft=nan
	Variable /G tFitRight=nan
	Variable /G dtFitExtend=0 // ms, a parameter
	Variable /G holdYOffset=0 // whether or not to fix yOffset when fitting, a parameter
	Variable /G yOffsetHeldValue=nan  // value to fix yOffset at when fitting, if holdYOffset
	// the fit coefficients
	Variable /G amp1=nan  
	Variable /G tau1=nan
	Variable /G amp2=nan
	Variable /G tau2=nan
	Variable /G yOffset=nan
	
	// Create the globals related to the averaging subpanel
	// There are all user-specified parameters
	//Variable nSweeps=BrowserModelGetNSweeps(browserNumber)		// Safe to call even this early
	Variable /G renameAverages=0
	Variable /G averageAllSweeps=1
	Variable /G iSweepFirstAverage=1
	//Variable /G iSweepLastAverage=max(nSweeps,1)
	Variable /G iSweepLastAverage=1
	//Variable /G avghold=nan
	//Variable /G holdtolerance=nan
	Variable /G averageAllSteps=1
	Variable /G stepToAverage=1
	
//	// Make a wave for colors
//	Make /O /N=(8,3) colors
//	colors[][0]={0,32768,0,65535,3,29524,4369,39321,65535}
//	colors[][1]={0,32768,0,0,52428,1,4369,26208,0}
//	colors[][2]={0,32768,65535,0,1,58982,4369,1,26214}

	// Make a 2D wave for the colors
	Make /O /N=(3,7) colors
	colors[][0]={0,0,0}			//black
	colors[][1]={32768,32768,32768}		// gray
	colors[][2]={60000,0,0}	// red
	colors[][3]={0,32768,0}	// green
	colors[][4]={0,0,65535}	// blue
	colors[][5]={65535,22616,0}	// orange
	colors[][6]={26411,0,52428}	// purple

	// More color stuff
	String /G colorNameList="Black;Gray;Red;Green;Blue;Orange;Purple"
	String /G colorNameA="Blue"
	String /G colorNameB="Red"

	// Restore the original DF
	SetDataFolder savedDF	
	
	// Return the browser number
	return browserNumber
End

Function BrowserModelSetCurSweepIndex(browserNumber,newValue)
	// Set the current sweep index to something, which is assumed to be valid.
	Variable browserNumber, newValue

	// Change to the right DF
	String savedDFName=ChangeToBrowserDF(browserNumber)
	
	// Set iCurrentSweep, then update the measurements
	NVAR iCurrentSweep
	iCurrentSweep=newValue
	BrowserModelUpdateMeasurements(browserNumber)
	
	// Restore the original DF
	SetDataFolder savedDFName	
End

Function /S BrowserModelGetTopWaveNameAbs(browserNumber)
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

	String traceAWaveName=BrowserModelGetAWaveNameAbs(browserNumber)
	String traceBWaveName=BrowserModelGetBWaveNameAbs(browserNumber)
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

Function /S BrowserModelGetTopWaveNameRel(browserNumber)
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

	String traceAWaveNameRel=BrowserModelGetAWaveNameRel(browserNumber)
	String traceBWaveNameRel=BrowserModelGetBWaveNameRel(browserNumber)
	String traceAWaveNameAbs=BrowserModelGetAWaveNameAbs(browserNumber)
	String traceBWaveNameAbs=BrowserModelGetBWaveNameAbs(browserNumber)
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

Function /S BrowserModelGetAWaveNameAbs(browserNumber)
	// Construct the absolute wave name of trace A in the given browser number.  Note that this wave may or
	// may not exist.
	Variable browserNumber
	return "root:"+BrowserModelGetAWaveNameRel(browserNumber)
End

Function /S BrowserModelGetBWaveNameAbs(browserNumber)
	// Construct the absolute wave name of trace B in the given browser number.  Note that this wave may 
	// or may not exist.
	Variable browserNumber
	return "root:"+BrowserModelGetBWaveNameRel(browserNumber)
End

Function /S BrowserModelGetAWaveNameRel(browserNumber)
	// Construct the wave name of trace A in the given browser number, relative to the data folder containing it.  
	// Note that this wave may or may not exist.
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iCurrentSweep=iCurrentSweep
	SVAR baseNameA=baseNameA
	String retval=sprintf2sv("%s_%d", baseNameA, iCurrentSweep)
	SetDataFolder savedDFName
	return retval
End

Function /S BrowserModelGetBWaveNameRel(browserNumber)
	// Construct the wave name of trace B in the given browser number, relative to the data folder containing it.  
	// Note that this wave may or may not exist.
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iCurrentSweep=iCurrentSweep
	SVAR baseNameB=baseNameB
	String retval=sprintf2sv("%s_%d", baseNameB, iCurrentSweep)
	SetDataFolder savedDFName
	return retval
End

Function BrowserModelRemoveWaves(base)
	// Removes waves with the given base name
	String base
	String savedDF, targetWindow, allwaves, thisWaveName
	Variable i
	savedDF=GetDataFolder(1)
	SetDataFolder root:
	base+="*"
	sprintf targetWindow, "WIN:"
	allwaves=WaveList(base,";", targetWindow)
	if (strlen(allwaves)>0)
		i=0
		do
			thisWaveName=GetStrFromList(allwaves,i,";")
			if (strlen(thisWaveName)==0)
				break
			else
				RemoveFromGraph $thisWaveName
			endif
			i+=1
		while(1)
	endif
	SetDataFolder savedDF
End

//Function BrowserModelDoBaseSub(browserNumber)
//	// Perform baseline subtraction on $traceAWaveName and $traceBWaveName.
//	// Each wave's note says whether it has had the baseline subtracted, and also
//	// contains the baseline value for that wave.
//	Variable browserNumber
//	
//	// Switch the DF, note the former DF name
//	String savedDFName=ChangeToBrowserDF(browserNumber)
//
//	// Get DF vars we need
//	NVAR traceAChecked=traceAChecked
//	
//	String traceAWaveName=BrowserModelGetAWaveNameAbs(browserNumber)
//	WAVE theWave=$traceAWaveName
//	Variable basesubtracted, baseline
//	if ( traceAChecked && WaveExists($traceAWaveName) )
//		baseline=NumberByKeyInWaveNote(theWave,"BASELINE")
//		basesubtracted=NumberByKeyInWaveNote(theWave,"BASESUBTRACTED")
//	endif
//
//	String traceBWaveName=BrowserModelGetBWaveNameAbs(browserNumber)
//	ControlInfo basesub1
//	if ( (V_value>0) && WaveExists(traceBWaveName) )			// if baseline subtract is checked
//		 if (basesubtracted<1)							// but the baseline isn't subtracted
//			theWave -=  baseline							// subtract baseline
//			ReplaceStringByKeyInWaveNote($traceAWaveName,"BASESUBTRACTED","1")	// and note baseline subtracted
//		endif
//	else												// if baseline subtract is not checked
//		 if (basesubtracted>0)							// but the baseline is subtracted
//			theWave +=  baseline							// add back the baseline
//			ReplaceStringByKeyInWaveNote($traceAWaveName,"BASESUBTRACTED","0")	// and note baseline not subtracted
//		endif
//	endif
//
//	NVAR traceBChecked=traceBChecked
//	if ( traceBChecked && WaveExists(traceBWaveName) )
//		WAVE theWave=$traceBWaveName
//		baseline=NumberByKeyInWaveNote(theWave,"BASELINE")
//		basesubtracted=NumberByKeyInWaveNote(theWave,"BASESUBTRACTED")
//	endif
//
//	ControlInfo basesub2
//	if ( (V_value>0) && WaveExists(traceBWaveName) )				// if baseline subtract is checked
//		 if (basesubtracted<1)							// but the baseline isn't subtracted
//			theWave -=  baseline							// subtract baseline
//			ReplaceStringByKeyInWaveNote(theWave,"BASESUBTRACTED","1")	// and note baseline subtracted
//		endif
//	else												// if baseline subtract is not checked
//		 if (basesubtracted>0)							// but the baseline is subtracted
//			theWave +=  baseline							// add back the baseline
//			ReplaceStringByKeyInWaveNote(theWave,"BASESUBTRACTED","0")	// and note baseline not subtracted
//		endif
//	endif
//	
//	// Restore the original DF.
//	SetDataFolder savedDFName
//End

Function BrowserModelUpdateMeasurements(browserNumber)
	// This is a private model method.
	// It updates the values displayed in the Measure part of the Tools Panel to reflect the wave 
	// currently displayed in
	// the DP Browser, given the current measurement parameters in the DF.
	// This is essentially syncing the measured values (part of the model) to the rest of the model 
	// (containing the waves and the measurement cursor positions).
	Variable browserNumber  // the index of the DP browser instance
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)
	
	// Get references to all the variables that we need in this data folder
	// inputs to the measurement process
	NVAR tBaselineLeft, tBaselineRight
	NVAR tWindow1Left, tWindow1Right
	NVAR tWindow2Left, tWindow2Right
	NVAR to1, from1
	NVAR to2, from2
	NVAR level1
	// outputs of the measurement process
	NVAR baseline, mean1, peak1, rise1
	NVAR mean2, peak2, rise2
	NVAR nCrossings1
	
	// If there's a top wave, calculate features of it
	String topTraceWaveName=BrowserModelGetTopWaveNameAbs(browserNumber)
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
			nCrossings1=CountThresholdCrossings(topTraceWaveName, tWindow1Left, tWindow1Right, level1)
		else
			mean1=NaN
			peak1=NaN
			rise1=NaN
			nCrossings1=nan		
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
		nCrossings1=nan
		mean2=NaN
		peak2=NaN
		rise2=NaN		
	endif
	
	// Restore the original data folder
	SetDataFolder savedDF
End

//Function InvalidateFit(browserNumber)
//	// This is a model method that marks the fit coefficients as not being valid
//	Variable browserNumber
//	
//	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
//	String savedDFName=ChangeToBrowserDF(browserNumber)
//
//	// the instance vars we''ll need
//	NVAR isFitValid
//	SVAR waveNameAbsOfFitTrace
//	NVAR amp1, tau1, amp2, tau2, yOffset
//
//	// mark the fit as invalid
//	isFitValid=0
//	
//	// set this guy to empty, to keep ourselves out of trouble
//	waveNameAbsOfFitTrace=""
//	
//	// don't really need to nan-out coeffs, but what the hell
//	amp1=nan
//	tau1=nan
//	amp2=nan
//	tau2=nan
//	yOffset=nan
//
//	// there may still be a yFit wave in the current workspace, but if the view does it's job, it
//	// will never be seen
//End

Function BrowserModelUpdateFit(browserNumber)
	// A private model method, changes the yFit wave and the fit coefficient instance variables to reflect 
	// the current fit window, trace, and fit parameters.  If a fit cannot be done, sets isValidFit to false.
	Variable browserNumber
	
	//Printf "In BrowserModelUpdateFit()\r"
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
	String topTraceWaveName=BrowserModelGetTopWaveNameAbs(browserNumber)
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
	Variable singleExp=AreStringsEqual(fitType,"Exponential")

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

Function BrowserModelMarkWaveForAvg(thisWaveName,filterOnHold,holdCenter,holdTol,filterOnStep,stepCenter)
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

Function BrowserModelGetNSweeps(browserNumber)
	Variable browserNumber
		
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	
	// Determine the range of sweeps present
	NVAR traceAChecked
	NVAR traceBChecked	
	SVAR baseNameA
	SVAR baseNameB
	Variable nSweepsA=NTracesFromBaseName(baseNameA)
	Variable nSweepsB=NTracesFromBaseName(baseNameB)
	Variable nSweeps
	if (traceAChecked)
		if (traceBChecked)
			nSweeps=max(nSweepsA,nSweepsB)
		else
			nSweeps=nSweepsA
		endif
	else
		if (traceBChecked)
			nSweeps=nSweepsB
		else
			nSweeps=0
		endif
	endif

	// Restore original DF
	SetDataFolder savedDFName
	
	// Return
	return nSweeps
End

Function BrowserModelAreCursorsAAndBSet(browserNumber)
	Variable browserNumber

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tCursorA
	NVAR tCursorB
	
	// Set the vars that delineate the window region
	Variable result=(!IsNan(tCursorA) && !IsNan(tCursorB))

	// Restore the orignal DF
	SetDataFolder savedDF	

	return result
End

Function BrowserModelIsCursorASet(browserNumber)
	Variable browserNumber

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tCursorA
	
	// Set the vars that delineate the window region
	Variable result=(!IsNan(tCursorA))

	// Restore the orignal DF
	SetDataFolder savedDF	

	return result
End

Function BrowserModelIsCursorBSet(browserNumber)
	Variable browserNumber

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tCursorB
	
	// Set the vars that delineate the window region
	Variable result=(!IsNan(tCursorB))

	// Restore the orignal DF
	SetDataFolder savedDF	

	return result
End


Function BrowserModelSetBaseline(browserNumber)
	Variable browserNumber
	
	// Return if the cursors are not set
	if ( !BrowserModelAreCursorsAAndBSet(browserNumber) )
		return 0
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare the instance vars we'll need
	NVAR tCursorA
	NVAR tCursorB
	NVAR tBaselineLeft
	NVAR tBaselineRight

	// Set the instance vars
	tBaselineLeft=tCursorA
	tBaselineRight=tCursorB

	// Update the measurements	
	BrowserModelUpdateMeasurements(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelClearBaseline(browserNumber)
	Variable browserNumber
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare the instance vars we'll need
	NVAR tBaselineLeft
	NVAR tBaselineRight

	// Set the instance vars
	tBaselineLeft=nan
	tBaselineRight=nan

	// Update the measurements	
	BrowserModelUpdateMeasurements(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelSetWindow1(browserNumber)
	Variable browserNumber

	// Return if the cursors are not set
	if ( !BrowserModelAreCursorsAAndBSet(browserNumber) )
		return 0
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tCursorA
	NVAR tCursorB
	NVAR tWindow1Left
	NVAR tWindow1Right
	
	// Set the vars that delineate the window region
	tWindow1Left=tCursorA		// times of left and right cursor that delineate the window region
	tWindow1Right=tCursorB

	// Update the meaurements
	BrowserModelUpdateMeasurements(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelClearWindow1(browserNumber)
	Variable browserNumber
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare the instance vars we'll need
	NVAR tWindow1Left
	NVAR tWindow1Right

	// Set the instance vars
	tWindow1Left=nan
	tWindow1Right=nan

	// Update the measurements	
	BrowserModelUpdateMeasurements(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelSetWindow2(browserNumber)
	Variable browserNumber

	// Return if the cursors are not set
	if ( !BrowserModelAreCursorsAAndBSet(browserNumber) )
		return 0
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tCursorA
	NVAR tCursorB
	NVAR tWindow2Left
	NVAR tWindow2Right
	
	// Set the vars that delineate the window region
	tWindow2Left=tCursorA		// times of left and right cursor that delineate the window region
	tWindow2Right=tCursorB

	// Update the meaurements
	BrowserModelUpdateMeasurements(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelClearWindow2(browserNumber)
	Variable browserNumber
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare the instance vars we'll need
	NVAR tWindow2Left
	NVAR tWindow2Right

	// Set the instance vars
	tWindow2Left=nan
	tWindow2Right=nan

	// Update the measurements	
	BrowserModelUpdateMeasurements(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelSetFitZero(browserNumber)
	Variable browserNumber

	// Return if the cursors are not set
	if ( !BrowserModelIsCursorASet(browserNumber) )
		return 0
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tCursorA
	NVAR tFitZero
	
	// Set the vars that delineate the window region
	tFitZero=tCursorA

	// Update the meaurements
	BrowserModelUpdateFit(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelClearFitZero(browserNumber)
	Variable browserNumber

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tFitZero
	
	// Set the vars that delineate the window region
	tFitZero=nan

	// Update the meaurements
	BrowserModelUpdateFit(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelSetFitRange(browserNumber)
	Variable browserNumber

	// Return if the cursors are not set
	if ( !BrowserModelAreCursorsAAndBSet(browserNumber) )
		return 0
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tCursorA
	NVAR tCursorB
	NVAR tFitLeft
	NVAR tFitRight
	
	// Set the vars that delineate the window region
	tFitLeft=tCursorA		// times of left and right cursor that delineate the window region
	tFitRight=tCursorB

	// Update the meaurements
	BrowserModelUpdateFit(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelClearFitRange(browserNumber)
	Variable browserNumber
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare the instance vars we'll need
	NVAR tFitLeft
	NVAR tFitRight

	// Set the instance vars
	tFitLeft=nan
	tFitRight=nan

	// Update the measurements	
	BrowserModelUpdateFit(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function BrowserModelSetColorNameA(browserNumber,newColorName)
	Variable browserNumber
	String newColorName
	String savedDF=ChangeToBrowserDF(browserNumber)
	SVAR colorNameA
	colorNameA=newColorName
	SetDataFolder savedDF	
End

Function BrowserModelSetColorNameB(browserNumber,newColorName)
	Variable browserNumber
	String newColorName
	String savedDF=ChangeToBrowserDF(browserNumber)
	SVAR colorNameB
	colorNameB=newColorName
	SetDataFolder savedDF	
End

Function BrowserModelSetRenameAverages(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDF=ChangeToBrowserDF(browserNumber)
	NVAR renameAverages
	renameAverages=newValue
	SetDataFolder savedDF	
End

Function BrowserModelSetStepToAverage(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDF=ChangeToBrowserDF(browserNumber)
	NVAR stepToAverage
	stepToAverage=newValue
	SetDataFolder savedDF	
End

Function BrowserModelSetAverageAllSteps(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDF=ChangeToBrowserDF(browserNumber)
	NVAR averageAllSteps
	averageAllSteps=newValue
	SetDataFolder savedDF	
End

Function BrowserModelSetAverageAllSweeps(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDF=ChangeToBrowserDF(browserNumber)
	NVAR averageAllSweeps
	averageAllSweeps=newValue
	SetDataFolder savedDF	
End

Function BrowserModelSetISweepFirstAvg(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDF=ChangeToBrowserDF(browserNumber)
	NVAR iSweepFirstAverage
	iSweepFirstAverage=newValue
	SetDataFolder savedDF	
End

Function BrowserModelSetISweepLastAvg(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDF=ChangeToBrowserDF(browserNumber)
	NVAR iSweepLastAverage
	iSweepLastAverage=newValue
	SetDataFolder savedDF	
End

Function BrowserModelSetFitType(browserNumber,newValue)
	Variable browserNumber
	String newValue
	String savedDF=ChangeToBrowserDF(browserNumber)
	SVAR fitType
	fitType=newValue
	BrowserModelUpdateFit(browserNumber)
	SetDataFolder savedDF	
End

Function BrowserModelSetHoldYOffset(browserNumber,newValue)
	Variable browserNumber
	Variable newValue

	// Switch the DF, note the former DF name
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get the old value
	NVAR holdYOffset  	// boolean, whether or not hold the y offset at the given value
	Variable holdYOffsetOld=holdYOffset

	// Update the model variable
	holdYOffset=newValue
	
	// If the value has not changed (however that might have happened), just return
	if ( holdYOffset==holdYOffsetOld )
		// Restore old data folder
		SetDataFolder savedDFName
		return nan;
	endif
	
	// If the checkbox has just been checked, and if the curent hold value is nan, 
	// and the current y offset is _not_ nan, copy the y offset into the hold value
	NVAR yOffsetHeldValue  // the value at which to hold the y offset
	NVAR yOffset  // the current y offset fit coefficient
	NVAR isFitValid
	if ( holdYOffset )
		// holdYOffset just turned true
		if ( IsNan(yOffsetHeldValue) )
			if ( IsNan(yOffset) )
				yOffsetHeldValue=0
			else
				yOffsetHeldValue=yOffset
			endif
		endif
		if ( isFitValid )
			if (yOffsetHeldValue==yOffset)
				// no need to invalidate in this case!
			else
				//Printf "About to call BrowserModelUpdateFit() in BrowserContHoldYOffsetCB() #1\r"
				BrowserModelUpdateFit(browserNumber)
			endif
		else
			// fit is already invalid
			//Printf "About to call BrowserModelUpdateFit() in BrowserContHoldYOffsetCB() #2\r"
			BrowserModelUpdateFit(browserNumber)
		endif			
	else
		// holdYOffset just turned false -- now the yOffset parameter is free, so a previously-valid fit 
		// is now invalid
		//yOffsetHeldValue=nan  // when made visible again, want it to get current yOffset
		//Printf "About to call BrowserModelUpdateFit() in BrowserContHoldYOffsetCB() #3\r"		
		BrowserModelUpdateFit(browserNumber)
	endif

	// Restore old data folder
	SetDataFolder savedDFName
End

Function BrowserModelSetYOffsetHeldValue(browserNumber,newValue)
	Variable browserNumber
	Variable newValue

	// Switch the DF, note the former DF name
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Set the instance variable
	NVAR yOffsetHeldValue
	yOffsetHeldValue=newValue

	// changing this invalidates the fit, since now the fit trace (if there is one) doesn't match the fit parameters
	BrowserModelUpdateFit(browserNumber)  // model method

	// Restore old data folder
	SetDataFolder savedDFName
End

Function BrowserModelGetRenameAverages(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR renameAverages
	Variable result=renameAverages
	SetDataFolder savedDFName
	return result
End

Function BrowserModelGetAverageAllSweeps(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR averageAllSweeps
	Variable result=averageAllSweeps
	SetDataFolder savedDFName
	return result
End

Function BrowserModelGetAverageAllSteps(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR averageAllSteps
	Variable result=averageAllSteps
	SetDataFolder savedDFName
	return result
End

Function BrowserModelGetISweepFirstAvg(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iSweepFirstAverage
	Variable result=iSweepFirstAverage
	SetDataFolder savedDFName
	return result
End

Function BrowserModelGetISweepLastAvg(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR iSweepLastAverage
	Variable result=iSweepLastAverage
	SetDataFolder savedDFName
	return result
End

Function BrowserModelGetTraceAChecked(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR traceAChecked
	Variable result=traceAChecked
	SetDataFolder savedDFName
	return result
End

Function BrowserModelGetTraceBChecked(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR traceBChecked
	Variable result=traceBChecked
	SetDataFolder savedDFName
	return result
End

Function /S BrowserModelGetBaseNameA(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	SVAR baseNameA
	String result=baseNameA
	SetDataFolder savedDFName
	return result
End

Function /S BrowserModelGetBaseNameB(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	SVAR baseNameB
	String result=baseNameB
	SetDataFolder savedDFName
	return result
End

Function BrowserModelGetStepToAverage(browserNumber)
	Variable browserNumber
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR stepToAverage
	Variable result=stepToAverage
	SetDataFolder savedDFName
	return result
End

Function BrowserModelIncludeInAverage(thisWaveName,filterOnHold,holdCenter,holdTol,filterOnStep,stepCenter)
	// Determine whether to include thisWaveName in the average, based on whether if satisfies the 
	// conditions as specified by checkHold, holdCenter, etc.
	// We assume that thisWaveName is in the current DF, or is an absolute wave name.
	// Returns 1 is wave should be included in average, zero otherwise.
	// Note that this is a class method.
	String thisWaveName
	Variable filterOnHold	// boolean
	Variable holdCenter, holdTol
	Variable filterOnStep	// boolean
	Variable stepCenter

	// The default is to include the wave in the average, then we check for a bunch of possible
	// reasons to exclude it
	WAVE thisWave=$thisWaveName
	if ( !WaveExists(thisWave) )
		return 0
	endif
	String waveTypeStr=StringByKeyInWaveNote(thisWave, "WAVETYPE")
	if (AreStringsEqual(waveTypeStr,"average"))
		return 0
	endif
	if ( NumberByKeyInWaveNote(thisWave, "REJECT") )
		return 0
	endif
	if (filterOnHold)
		Variable hold=NumberByKeyInWaveNote(thisWave, "HOLD")
		if ( abs(hold-holdCenter)>holdTol )
			return 0
		endif
	endif
	if (filterOnStep)
		Variable step=NumberByKeyInWaveNote(thisWave, "STEP")
		if (abs(step-stepCenter)>0.1)  // tolerance is hard-coded
			return 0
		endif
	endif
	return 1
End

Function BrowserModelDoFit(browserNumber)
	// A public method that re-does the fit, doing it on the currently-showing sweep.
	Variable browserNumber
	BrowserModelUpdateFit(browserNumber)	// this is a private method
End

Function BrowserModelSetDtFitExtend(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR dtFitExtend
	dtFitExtend=newValue
	BrowserModelUpdateFit(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetBaseNameA(browserNumber,newValue)
	Variable browserNumber
	String newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	SVAR baseNameA
	baseNameA=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetBaseNameB(browserNumber,newValue)
	Variable browserNumber
	String newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	SVAR baseNameB
	baseNameB=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetLevel1(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR level1
	level1=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetTo1(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR to1
	to1=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetFrom1(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR from1
	from1=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetTo2(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR to2
	to2=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetFrom2(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR from2
	from2=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetTraceAChecked(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR traceAChecked
	traceAChecked=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End

Function BrowserModelSetTraceBChecked(browserNumber,newValue)
	Variable browserNumber
	Variable newValue
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR traceBChecked
	traceBChecked=newValue
	BrowserModelUpdateMeasurements(browserNumber)  
	SetDataFolder savedDFName
End



