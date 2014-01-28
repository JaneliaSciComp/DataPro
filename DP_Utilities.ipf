//	DataPro Utilities

#pragma rtGlobals=3		// Use modern global access method, strict wave access
//#include <Strings as Lists>
//#include <Axis Utilities>

//---------------------- Graph Axis Scaling Procedures -----------------------//

//Function RescaleTopAxes()
//	// Calls BrowserViewRescaleAxes() on the top DPBrowser
//	Variable browserNumber=GetTopBrowserNumber()
//	BrowserViewUpdateAxesLimits(browserNumber)
//End


//Function SyncDFAxesLimitsWithGraph(browserNumber)
//	// Reads the axes limits from the graph of the given DPBrowser, and writes those values to the
//	// xMin, xMax, etc. variables in the DF
//	Variable browserNumber
//
//	// Switch the DF to the browser DF, note the former DF name
//	String savedDFName=ChangeToBrowserDF(browserNumber)
//
//	// Get the window name of the DPBrowser
//	String browserName=BrowserNameFromNumber(browserNumber)
//
//	// Get the graph limits, set the ones stored in the browser DF to those
//	NVAR xMin=xMin, xMax=xMax
//	NVAR yAMin=yAMin, yAMax=yAMax
//	NVAR yBMin=yBMin, yBMax=yBMax
//	GetAxis /W=$browserName /Q bottom
//	xMin=V_min; xMax=V_max
//	GetAxis /W=$browserName /Q left
//	yAMin=V_min; yAMax=V_max
//	GetAxis /W=$browserName /Q right
//	yBMin=V_min; yBMax=V_max
//	
//	// Restore old DF
//	SetDataFolder savedDFName
//End

Function PlaceCursors(where)
	String where
	NVAR acsrx=acsrx, bcsrx=bcsrx
	Cursor /C=(0,0,0) A, $where, acsrx
	Cursor /C=(0,0,0) B, $where, bcsrx
End

//------------------FUNCTIONS AND PROCEDURES FOR WAVE NOTES------------------//

// These are functions for dealing with wave notes that consist of a list of key-value pairs.
// A carriage return (/r) separates pairs, and the character "=" separates the key from the value.

Function ReplaceStringByKeyInWaveNote(theWave, key, value)
	Wave theWave
	String key, value
	
	String kvList=note(theWave)
	String kvListNew=ReplaceStringByKey(key, kvList, value, "=", "\r", 1)  // 1 means match case
	Note /K theWave, kvListNew
End

Function NumberByKeyInWaveNote(theWave, key)
	Wave theWave
	String key
	
	String kvList=note(theWave)
	Variable value=NumberByKey(key, kvList, "=", "\r", 1)  // 1 means match case
	return value
End

Function /S StringByKeyInWaveNote(theWave, key)
	Wave theWave
	String key
	
	String kvList=note(theWave)
	String value=StringByKey(key, kvList, "=", "\r", 1)  // 1 means match case
	return value
End

//------------------END OF FUNCTIONS AND PROCEDURES FOR WAVE NOTES------------//

Function PanelExists(windowName)
	String windowName
	String windowList=WinList(windowName,";","WIN:64")  // 64 is code for panel
	Variable nItems=ItemsInList(windowList)
	return (nItems>0)
End

Function GraphOrPanelExists(windowName)
	// True iff a graph or panel by that name exists
	String windowName
	String windowList=WinList(windowName,";","WIN:65")  // 64 is code for panel, 1 for graph
	Variable nItems=ItemsInList(windowList)
	return (nItems>0)
End

Function IsItemInList(itemStr,listStr)
	String itemStr, listStr
	Variable i=FindListItem(itemStr,listStr)  // returns -1 if item not in list
	return (i>=0)
End

Function ToolsPanelExists(browserNumber)
	Variable browserNumber
	String browserName=BrowserNameFromNumber(browserNumber)
	String windowList=ChildWindowList(browserName)
	return IsItemInList("ToolsPanel",windowList)
End

Function GraphExists(windowName)
	String windowName
	return (ItemsInList(WinList(windowName,";","WIN:1"))>0)  // 1 is code for graph
End

Function KillToolsPanel(browserNumber)
	Variable browserNumber
	String panelName=ToolsPanelNameFromNumber(browserNumber)
	KillWindow $panelName
End

Function /S sprintf1v(templateString,v)
	String templateString
	Variable v
	
	String outputString
	sprintf outputString templateString v
	return outputString
End

Function /S sprintf1s(templateString,str)
	String templateString
	String str
	
	String outputString
	sprintf outputString templateString str
	return outputString
End

Function /S sprintf2ss(templateString,str1,str2)
	String templateString
	String str1, str2
	
	String outputString
	sprintf outputString templateString str1, str2
	return outputString
End

Function /S sprintf2sv(templateString,str,i)
	String templateString
	String str
	Variable i
	
	String outputString
	sprintf outputString templateString str, i
	return outputString
End

Function /S sprintf2vv(templateString,f1,f2)
	String templateString
	Variable f1, f2
	
	String outputString
	sprintf outputString templateString f1, f2
	return outputString
End

Function /S sprintf3vvv(templateString,f1,f2, f3)
	String templateString
	Variable f1, f2, f3
	
	String outputString
	sprintf outputString templateString f1, f2, f3
	return outputString
End

Function /S BrowserNameFromNumber(browserNumber)
	Variable browserNumber
	String browserName
	sprintf browserName "DataProBrowser%d" browserNumber
	return browserName
End

Function /S ToolsPanelNameFromNumber(browserNumber)
	Variable browserNumber
	String panelName
	sprintf panelName "DataProBrowser%d#ToolsPanel" browserNumber
	return panelName
End

Function BrowserNumberFromName(browserName)
	String browserName
	String baseName, browserNumberAsString
	SplitString /E="([a-zA-Z]*)([0-9]+)" browserName, baseName, browserNumberAsString
	// Convert to a number (not a string) and return
	Variable browserNumber=str2num(browserNumberAsString)  // will be nan if a non-number string
	return browserNumber
End

Function /S BrowserTitleFromNumber(browserNumber)
	Variable browserNumber
	String browserTitle
	sprintf browserTitle "Signal Browser %d" browserNumber
	return browserTitle
End

Function /S BrowserDFNameFromNumber(browserNumber)
	Variable browserNumber
	String browserDFName
	sprintf browserDFName "root:DP_Browser_%d" browserNumber
	return browserDFName
End

Function /S AbsoluteVarName(DFName,localVarName)
	String dfName, localVarName
	String absVarName
	sprintf absVarName "%s:%s" DFName, localVarName
	return absVarName
End

//Function GetTopBrowserNumber()
//	//windowName=WinName(0,1)
//	String windowList=WinList("DataProBrowser*",";","WIN:1")
//	 	// I don't think it's stated in the docs, but I've tested this, and they seem to always
//	 	// be returned in top-down order
//	Variable n=ItemsInList(WindowList)
//	if (n==0)
//		return NaN  // signals that there are no DataProBrowser windows
//	endif
//	String windowName=StringFromList(0,windowList)  // We know that element zero exists
//	//if (strlen(windowName)==0)
//	//	return NaN  // signals that there are no DataProBrowser windows
//	//endif
//	Variable browserNumber=BrowserNumberFromName(windowName)
//	return browserNumber
//End

Function/WAVE GetAllBrowserNumbers()
	String windowList=WinList("DataProBrowser*",";","WIN:1")
	 	// I don't think it's stated in the docs, but I've tested this, and they seem to always
	 	// be returned in top-down order
	Variable n=ItemsInList(WindowList)
	Wave browserNumber=NewFreeWave(0x20,n)  // 0x20 means 32-bit integer wave  
	Variable i
	for (i=0; i<n; i+=1)
		String windowName=StringFromList(i,windowList)  // We know that element zero exists
		Variable browserNumberThis=BrowserNumberFromName(windowName)
		browserNumber[i]=browserNumberThis
	endfor
	return browserNumber
End

//Function DetermineBrowserNumberForNew()
//	String topwin, key, doit
//	Variable browserNumber
//	String windowName, windowNameCheck
//	Variable done=0
//	for (browserNumber=0;!done;browserNumber+=1)
//		sprintf windowName, "DataProBrowser%d", browserNumber
//		windowNameCheck=WinList(windowName,"","")
//		if (strlen(windowNameCheck)==0)
//			done=1
//			break  // don't wan't browserNumber incremented at end of this iteration
//		endif
//	endfor
//	// browserNumber is now the number of the next DataProBrowser window
//	return browserNumber
//End

Function LargestBrowserNumber()
	// The number of the largest-numbered DP Browser currently extant.  0 if there are no DP Browsers.
	String browserList=WinList("DataProBrowser*",";","WIN:1")	// 1 means graph windows
	Variable n=ItemsInList(browserList)
	Variable i, browserNumber, browserNumberMax=0
	String browserName
	for (i=0; i<n; i+=1)
		browserName=StringFromList(i,browserList)
		browserNumber=BrowserNumberFromName(browserName)
		browserNumberMax=max(browserNumberMax,browserNumber)
	endfor
	return browserNumberMax
End

Function /S ChangeToBrowserDF(browserNumber)
	Variable browserNumber

	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=GetDataFolder(1)
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	SetDataFolder browserDFName
	return savedDFName
End

Function NTracesFromBaseName(baseName)
	// Determine the number of traces with the given baseName in the root DF.
	String baseName
	
	String savedDFName=GetDataFolder(1)
	SetDataFolder root:
	String theWaveList=WaveList(baseName+"*", ";", "")
	SetDataFolder savedDFName	
	Variable nTraces=ItemsInList(theWaveList)
	SetDataFolder savedDFName
	return nTraces
End

Function maxSweepIndexFromBaseName(baseName)
	// Determine the largest sweep index of a wave with the given baseName in the root DF.
	String baseName
	
	String savedDFName=GetDataFolder(1)
	SetDataFolder root:
	String theWaveList=WaveList(baseName+"*", ";", "")
	SetDataFolder savedDFName
	Variable prefixLength=strlen(baseName)+1
	Variable nTraces=ItemsInList(theWaveList)
	Variable maxSweepIndex= -Inf
	Variable i
	for (i=0; i<nTraces; i+=1)
		String thisWaveName=StringFromList(i,theWaveList)
		String sweepIndexThisString=thisWaveName[prefixLength,strlen(thisWaveName)-1]
		Variable sweepIndexThis=str2num(sweepIndexThisString)
		maxSweepIndex=max(maxSweepIndex,sweepIndexThis)
	endfor
	return maxSweepIndex
End

Function minSweepIndexFromBaseName(baseName)
	// Determine the smallest sweep index of a wave with the given baseName in the root DF.
	String baseName
	
	String savedDFName=GetDataFolder(1)
	SetDataFolder root:
	String theWaveList=WaveList(baseName+"*", ";", "")
	SetDataFolder savedDFName
	Variable prefixLength=strlen(baseName)+1
	Variable nTraces=ItemsInList(theWaveList)
	Variable minSweepIndex= +Inf
	Variable i
	for (i=0; i<nTraces; i+=1)
		String thisWaveName=StringFromList(i,theWaveList)
		String sweepIndexThisString=thisWaveName[prefixLength,strlen(thisWaveName)-1]
		Variable sweepIndexThis=str2num(sweepIndexThisString)
		minSweepIndex=min(minSweepIndex,sweepIndexThis)
	endfor
	return minSweepIndex
End

Function /S WaveNameFromBaseAndSweep(baseName,iSweep)
	String baseName
	Variable iSweep

	String theWaveName
	sprintf theWaveName "%s_%d" baseName, iSweep
	return theWaveName
End

Function /S TraceLetterFromIndex(i)
	// Converts from a trace index (0 or 1) to a trace letter ("A" or "B")
	Variable i

	String letter
	if (i==0)
		letter="A"
	else
		letter="B"
	endif
	return letter
End

Function RemoveAllTracesFromGraph(graphName)
	String graphName
	
	String traceList=TraceNameList(graphName,";",3)  // 3 means all traces
	Variable nTraces=ItemsInList(traceList)
	Variable i
	String thisTraceName
	for (i=0; i<nTraces; i+=1)
		thisTraceName=StringFromList(i,traceList)
		RemoveFromGraph /Z /W=$graphName $thisTraceName
	endfor
End

Function RemoveAllImagesFromGraph(graphName)
	String graphName
	
	String imageList=ImageNameList(graphName,";")
	Variable nImages=ItemsInList(imageList)
	Variable i
	String thisImageName
	for (i=0; i<nImages; i+=1)
		thisImageName=StringFromList(i,imageList)
		RemoveImage /W=$graphName $thisImageName
	endfor
End

Function /S RootWindowName(subwindowName)
	// Given an absolute subwindow name, returns the name of the root window of the subwindow
 	String subwindowName
 	
	String rootName=StringFromList(0,subwindowName,"#")
	return rootName
End

Function AreCursorsAAndBSet(graphName)
	// Returns 1 if both cursors A and B are set, 0 otherwise
	String graphName
	return ( IsCursorASet(graphName) && IsCursorBSet(graphName) )
End

Function IsCursorASet(graphName)
	String graphName
	String kvList=CsrInfo(A,graphName)
	if (strlen(kvList)==0)
		return 0
	endif
	return 1
End

Function IsCursorBSet(graphName)
	String graphName
	String kvList=CsrInfo(B,graphName)
	if (strlen(kvList)==0)
		return 0
	endif
	return 1
End

Function IsNan(x)
	Variable x
	return (NumType(x)==2)
End

Function IsInf(x)
	Variable x
	return (NumType(x)==1)
End

Function IsFinite(x)
	Variable x
	return (NumType(x)==0)
End

Function AreStringsEqual(str1,str2)
	String str1,str2
	return (cmpstr(str1,str2)==0)
End

Function RiseTime(thisWave,tLeft,tRight,yBase,dyPeak,fracFrom,fracTo)
	Wave thisWave
	Variable tLeft,tRight, yBase, dyPeak, fracFrom, fracTo

	Variable yFrom=yBase+fracFrom*dyPeak
	FindLevel /Q/R=(tLeft,tRight) thisWave, yFrom  // find level crossing
	Variable tFrom= (V_flag==0) ? V_LevelX : NaN
	Variable yTo=yBase+fracTo*dyPeak
	FindLevel /Q/R=(tLeft,tRight) thisWave, yTo  // find level crossing
	Variable tTo= (V_flag==0) ? V_LevelX : NaN
	Variable tRise=tTo-tFrom
	return tRise
End

Function CountThresholdCrossings(theWaveName, tWindowLeft, tWindowRight, threshold)
	String theWaveName
	Variable tWindowLeft, tWindowRight, threshold

	if ( strlen(theWaveName)==0 || IsNan(tWindowLeft) || IsNan(tWindowRight) || IsNan(threshold) )
		return nan
	endif
	FindLevels /Q/R=(tWindowLeft,tWindowRight) $theWaveName, threshold
	return V_LevelsFound
End

Function WhiteOutIffNan(valDisplayName,windowName,value)
	// Sets the foreground text color to white if the named ValDisplay is nan, black otherwise
	String valDisplayName, windowName
	Variable value
	
	// Tried this, but doesn't work reliably because of exactly when IgorPro syncs bindings
	//ControlInfo /W=$windowName $valDisplayName
	//Variable value=V_value
	if ( IsNan(value) )
		ValDisplay $valDisplayName, win=$windowName, valueColor=(65535,65535,65535)
	else
		ValDisplay $valDisplayName, win=$windowName, valueColor=(0,0,0)
	endif	
End

Function /S RepeatString(s,n)
	// Returns a string consisting of n repeats of the string s.
	String s
	Variable n

	String out=""
	Variable i
	for (i=0; i<n; i+=1)
		out+=s
	endfor
	
	return out
End

Function lcmLength(s1,s2)
	// Computes the least common multiple of the length of two strings.
	String s1, s2
	
	Variable n1=strlen(s1)
	Variable n2=strlen(s2)
	return LCM(n1,n2)
End

// copy a list of variable names (with common base) into a wave
Function Wave2Vars(wbase,vbase,n)
	String wbase, vbase
	Variable n
	Wave thewave=$wbase
	String var, thevalue
	do
		sprintf var, "%s%d", vbase, n-1
		NVAR thestring=$var
		thestring=thewave[n-1]
	//	print var, thestring, thewave[n-1]
		n-=1
	while(n>0)
End

// copy a list of variable names (with common base) into a wave
Function Wave2StringVars(wbase,vbase,n)
	String wbase, vbase
	Variable n
	Wave /T thewave=$wbase
	String var, thevalue
	do
		sprintf var, "%s%d", vbase, n-1
		SVAR thestring=$var
		thestring=thewave[n-1]
	//	print var, thestring, thewave[n-1]
		n-=1
	while(n>0)
End

// copy a wave into a list of variable names (with common base)
Function Vars2Wave(vbase,wbase,n)
	String vbase, wbase
	Variable n
	String var
	do
		sprintf var, "%s%d", vbase, n-1
		Wave varwave=$wbase
		NVAR value=$var
		varwave[n-1]=value
		n-=1
	while(n>0)
End

// returns 1 if option-cmd-dot pressed
//Function HaltProcedures()
//	String s
//	s = KeyboardState("")
//	if (cmpstr(s[9], " ")==0)		// is spacebar pressed?
//		return 1
//	endif
//	return 0
//End

Function EscapeKeyWasPressed()
	Variable state=GetKeyState(0)		// the zero means nothing
	return (state&32)		// bit 5 is true iff escape key was pressed
End

// Compute Least Common Multiple
Function LCM(a,b)
	Variable	a,b
	Return((a*b)/GCD(a,b))
End

Function IsEmptyString(s)
	String s
	return (strlen(s)==0)
End

//Function /WAVE SimplePulseBoolean(dt,totalDuration,preDuration,pulseDuration)
//	// Returns a three-segment pulse wave, suitable for pushing to a TTL channel.
//	Variable dt	// time step, ms
//	Variable totalDuration		// total duration, ms
//	Variable preDuration		// prestep duration, ms
//	Variable pulseDuration	// pulse duration, ms
//
//	Variable nSegments=3
//	Make /FREE /N=(nSegments) amplitude, duration
//	amplitude[0]=0
//	amplitude[1]=1
//	amplitude[2]=0
//	duration[0]=preDuration		// duration of first segment (ms)
//	duration[1]=pulseDuration		// duration of second segment (ms)
//	duration[2]=0					// not used
//	Variable nScans=numberOfScans(dt,totalDuration)
//	Make /FREE /N=(nScans) signal
//	Setscale /P x, 0, dt, "ms", signal
//	Variable first=0, last
//	Variable i
//	for (i=0; i<nSegments; i+=1)
//		if (i<nSegments-1)
//			last=first+round(duration[i]/dt)-1
//		else
//			last=nScans-1
//		endif
//		signal[first,last]=amplitude[i]
//		first=last+1
//	endfor
//	return signal
//End

//Function /WAVE SimplePulse(dt,totalDuration,preDuration,pulseDuration,pulseAmplitude)
//	// Returns a three-segment pulse wave, suitable for pushing to a TTL channel.
//	Variable dt	// time step, ms
//	Variable totalDuration		// total duration, ms
//	Variable preDuration		// prestep duration, ms
//	Variable pulseDuration	// pulse duration, ms
//	Variable pulseAmplitude	// pulse amplitude, whatever units
//
//	Wave signal=SimplePulseBoolean(dt,totalDuration,preDuration,pulseDuration)
//	signal=pulseAmplitude*signal
//	return signal
//End

Function detectITCVersion()
	// Determine what model of Instrutech ITC is currently in use.  Returns 16, 18, or 0 if no ITC found.
	Variable itc16Present=(exists("ITC16StopAcq")==4)
	Variable itc18Present=(exists("ITC18StopAcq")==4)
	Variable itc
	if (itc18Present)
		itc=18
	elseif (itc16Present)
		itc=16
	else
		itc=0	// Demo mode
	endif
	//Printf "itc16Present: %d\r", itc16Present
	//Printf "itc18Present: %d\r", itc18Present
	//Printf "itc: %d\r", itc
	Return itc
End

Function IsStandardName(s)
	// Returns true iff the string s contains a valid Igor Pro standard name
	String s
	// Check length
	if (strlen(s)<1 || strlen(s)>31)
		return 0
	endif
	// Check first character
	if ( !GrepString(s[0],"[a-zA-Z]") )
		return 0
	endif
	// Check rest of characters
	String sRest=s[1,strlen(s)-1]
	//Print sRest
	if ( !GrepString(sRest,"^[a-zA-Z0-9_]*$") )
		return 0
	endif
	// All tests passes
	return 1
End

Function RaiseOrCreateView(viewName)
	String viewName
	
	// All Datapro views are either graphs or panels
	if (GraphOrPanelExists(viewName))
		DoWindow /F $viewName
	else
		Execute viewName+"Constructor()"
	endif
End

//Function /WAVE limitTo16Bits(w)
//	Wave w
//	Duplicate /FREE w result
//	result=min(max(-32768,result),32767)
//End

Function IsListEmpty(list)
	String list
	return (ItemsInList(list)==0)
End

Function IsListNonEmpty(list)
	String list
	return (ItemsInList(list)>0)
End

Function /S CatLists(a,b)
	// Concatenates the two string-lists a and b, assuming semicolon is the list separator
	String a, b
	String result=b
	Variable i
	String thisItem
	// add the items from a to the start of result, starting with the last item in a
	for (i=ItemsInList(a)-1; i>=0; i-=1)
		thisItem=StringFromList(i,a)
		result=AddListItem(thisItem,result)	 // prepend thisItem to result
	endfor
	return result
End

Function numberOfScans(dt,totalDuration)
	// Get the number of time points ("scans") for the given sampling interval and duration settings.
	Variable dt,totalDuration
	return round(totalDuration/dt)+1
End

Function cursorXPosition(cursorName,graphName)
	// This is like xcsr, but doesn't throw errors as much.
	// It returns nan if the cursor X position is not well-defined, for whatever reason.
	String cursorName
	String graphName

	Variable x		// return value	
	String info=CsrInfo($cursorName,graphName)
	if (IsEmptyString(info))
		x=nan
	else
		String traceName=StringByKey("TNAME",info)
		if (IsEmptyString(traceName))
			x=nan
		else
			Variable isFree=NumberByKey("ISFREE",info)
			if (isFree)
				x=nan
			else
				Variable index=NumberByKey("POINT",info)
				Wave w=CsrWaveRef($cursorName,graphName)
				x=pnt2x(w,index)
			endif
		endif
	endif
	return x		
End

Function squareWave(x,dutyCycle)
	Variable x, dutyCycle
	Variable f=x-floor(x)	// fractional part of x
	return (f<dutyCycle)
End

Function unitStep(x)
	Variable x
	return (x>=0)
End

Function unitPulse(x,duration)
	Variable x, duration
	return ( (x>=0)&&(x<duration) )
End

Function /S stringFif(test,trueString,falseString)
	// Like the ternary operator ? :, but for strings
	// stringFif is for "string functional if"
	Variable test
	String trueString, falseString
	
	String result
	if (test)
		result=trueString
	else
		result=falseString
	endif
	return result
End

Function IsInteger(x)
	Variable x
	return (abs(x-round(x))<0.001)

End

Function AddROIWavesToRoot(imageWave,roisWave,iSweep,calculationName,isBackgroundROI)
	Wave imageWave
	Wave roisWave
	Variable iSweep
	String calculationName
	Wave isBackgroundROI
	
	// Get image dimensions --- these will be useful later
	Variable nFrames=DimSize(imageWave,2)
	
	// Process the calculationName
	Variable doMean=AreStringsEqual(calculationName,"Mean")
	Variable doDff=AreStringsEqual(calculationName,"DF/F")
	// If both these are false, we end up with the sum across pixels.

	// Find the background ROI, if there is one
	FindValue /I=1 isBackgroundROI
	Variable iBackgroundROI=V_value
	Variable isAnyBackgroundROI=(iBackgroundROI>=0)
	
	// Loop over ROIs, making one new wave per ROI
	Variable nROIs=DimSize(roisWave,1)	
	Variable iROI
	for (iROI=0; iROI<nROIs; iROI+=1)
		// Make the signal wave for this ROI
		String signalWaveNameRel=sprintf2vv("roi%d_%d", iROI, iSweep)
		String signalWaveNameAbs="root:"+signalWaveNameRel
		Make /O /N=(nFrames) $signalWaveNameAbs
		Wave signalWave=$signalWaveNameAbs
		// Compute the ROI signal
		computeROISignalBang(signalWave,imageWave,roisWave,iROI,doMean)
	endfor
	
	// If there's a background signal, divide that out of each signal
	if (isAnyBackgroundROI)
		// Get a ref to the background signal
		String bgWaveNameAbs=sprintf2vv("root:roi%d_%d", iBackgroundROI, iSweep)
		Wave bgWaveRef=$bgWaveNameAbs
		Duplicate /FREE $bgWaveNameAbs bgWave
		// For each signal, divide out the background signal
		for (iROI=0; iROI<nROIs; iROI+=1)
			// Get a ref to the signal wave for this ROI
			signalWaveNameRel=sprintf2vv("roi%d_%d", iROI, iSweep)
			signalWaveNameAbs="root:"+signalWaveNameRel
			Wave signalWave2=$signalWaveNameAbs
			// Divide out the background signal
			signalWave2 = signalWave2[p]/bgWave[p]
			SetScale d 0, 0, "pure", signalWave2
		endfor
	endif
	
	// If wanted, convert to DF/F
	if (doDff)
		for (iROI=0; iROI<nROIs; iROI+=1)
			// Get a ref to the signal wave for this ROI
			signalWaveNameRel=sprintf2vv("roi%d_%d", iROI, iSweep)
			signalWaveNameAbs="root:"+signalWaveNameRel
			Wave signalWave3=$signalWaveNameAbs
			// Divide out the mean signal, subtract one
			Variable xbar=mean(signalWave3)
			signalWave3 = signalWave3/xbar-1
			SetScale d 0, 0, "pure", signalWave3
		endfor
	endif
End

Function computeROISignalBang(signalWave,imageWave,roisWave,iROI,doMean)
	// Fill in the elements of signalWave with the ROI signals.  We assume signalWave is already the correct size.
	Wave signalWave
	Wave imageWave
	Wave roisWave
	Variable iROI
	Variable doMean
	Variable doDff

	// Image parameters
	Variable x0=DimOffset(imageWave,0)
	Variable dx=DimDelta(imageWave,0)
	Variable y0=DimOffset(imageWave,1)
	Variable dy=DimDelta(imageWave,1)
	Variable t0=DimOffset(imageWave,2)
	Variable dt=DimDelta(imageWave,2)	
	Variable nFrames=DimSize(imageWave,2)

	// Set the scales
	SetScale /P x, t0, dt, "ms", signalWave
	SetScale d 0, 0, "counts", signalWave

	// Determine the pixel bounds
	Variable xMin=roisWave[0][iROI]
	Variable yMin=roisWave[1][iROI]
	Variable xMax=roisWave[2][iROI]
	Variable yMax=roisWave[3][iROI]
	Variable i0=ceil((xMin-x0)/dx)
	Variable iff=floor((xMax-x0)/dx)
	Variable j0=ceil((yMin-x0)/dx)
	Variable jf=floor((yMax-x0)/dx)
	// Do the triple-loop that sums up all the pixel values for each time point
	Variable i, j, k
	for (k=0; k<nFrames; k+=1)
		Variable s=0		// Will hold sum of pel values in ROI
		for (i=i0; i<=iff; i+=1)
			for (j=j0; j<=jf; j+=1)
				s+=imageWave[i][j][k]
			endfor
		endfor
		signalWave[k]=s
	endfor
	// Convert sum to average
	if (doMean)
		Variable nPixels=(iff-i0+1)*(jf-j0+1)
		signalWave=signalWave/nPixels
	endif
End



Function /WAVE offsetAndIntervalFromExposure(exposure)
	// In most cases, this returns a 4-element wave like so:
	// 	result[0]=frameOffset
	// 	result[1]=frameInterval
	// 	result[2]=frameIntervalMin
	// 	result[3]=frameIntervalMax
	// If there are <2 pulses in exposure, some of the above will be set to funny values like nan, -inf, +inf
	// If there is a more serious problem, this function returns a zero-length wave
	Wave exposure	// a TTL or CMOS signal, high when CCD is absorbing light for a frame
	
	// Convert the analog exposure wave to a boolean representation
	Variable threshold=(WaveMax(exposure)-WaveMin(exposure))/2
	
	// Determine times of rising edges
	Variable edgeDelayMin=1		// ms, could cause problems if someone does kHz imaging at some point
	Make /FREE risingEdgeTimes
	FindLevels /DEST=risingEdgeTimes /EDGE=1 /M=1 /Q exposure, threshold
		
	// Determine times of falling edges
	Make /FREE fallingEdgeTimes		// ms
	FindLevels /DEST=fallingEdgeTimes /EDGE=2 /M=1 /Q exposure, threshold
	
	// Check that there are the same number of rising edges as falling edges
	Variable nRisingEdges=numpnts(risingEdgeTimes)
	Variable nFallingEdges=numpnts(fallingEdgeTimes)
	if (nRisingEdges!=nFallingEdges)
		// if not, signal an error condition (a length-zero return wave)
		Make /FREE /N=0 result		
		return result
	endif
	
	// Compute the time at the center of each frame
	Duplicate /FREE risingEdgeTimes, frameCenterTimes
	frameCenterTimes+=fallingEdgeTimes
	frameCenterTimes/=2

	// Things we'll return
	Variable frameOffset
	Variable frameIntervalMin
	Variable frameIntervalMax
	Variable frameInterval
	
	// Check for zero edges
	if (nRisingEdges==0)
		frameOffset=nan
		frameIntervalMin=+inf
		frameIntervalMax=-inf
		frameInterval=nan
	else	
		// At least one rising edge
		frameOffset=frameCenterTimes[0]
		
		// Compute the n-1 frame intervals
		Variable n=numpnts(exposure)
		Make /FREE /N=(nRisingEdges-1) frameIntervals
		frameIntervals=frameCenterTimes[p+1]-frameCenterTimes[p]
	
		// Compute min, max, and mean of the frame intervals
		// We'll return the mean as our overall frame interval
		if ( numpnts(frameIntervals)==0 )
			frameIntervalMin=+inf
			frameIntervalMax=-inf
			frameInterval=nan
		else	
			frameIntervalMin=WaveMin(frameIntervals)
			frameIntervalMax=WaveMax(frameIntervals)
			frameInterval=mean(frameIntervals)
		endif
	endif

	// Package results in a wave
	Make /FREE /N=4 result
	result[0]=frameOffset
	result[1]=frameInterval
	result[2]=frameIntervalMin
	result[3]=frameIntervalMax
	
	// Return
	return result
End		



Function /S stringFromIntegerWave(valueWave)
	Wave valueWave
	
	String valueAsString="{ "
	Variable n=numpnts(valueWave)
	Variable i
	for (i=0; i<n; i+=1)
		if (i<n-1)
			valueAsString+=sprintf1v("%d, ",valueWave[i])
		else
			valueAsString+=sprintf1v("%d ",valueWave[i])
		endif
	endfor
	valueAsString+="}"
	
	return valueAsString
End



Function WaveExistsByName(name)
	// Returns true iff a wave by the given name exists in the current DF context.
	String name
	
	//Wave w=$"no such wave"
	//Variable test=WaveExists(w)
	
	return WaveExists($name)		
		// It doesn't seem like this should work, since if the wave doesn't exist, evaluating $name should error, 
		// as the commented-out snippet above does.  But it does work...
		
	//String list=WaveList(name,";","")
	//return !IsEmptyString(list)		
End



Function fromEnable(isEnabled)
	// Computes the number to set a controls "disable" field to, given
	// A boolean that says whether is should be enabled or not
	Variable isEnabled
	
	return (isEnabled?0:2)
End

