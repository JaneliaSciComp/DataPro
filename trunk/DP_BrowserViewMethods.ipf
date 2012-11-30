// This contains the "methods" of the DP Browser View.  Of course, this idea is largely conceptual, since
// Igor Pro doesn't have OOP features.

#pragma rtGlobals=1		// Use modern global access method.

Function SyncBrowserViewToDFState(browserNumber)
	// This syncs the indicated DPBrowser view to the values of the model variables in the browser's DF,
	// which are assumed to be self-consistent.
	Variable browserNumber
	
	// Find name of top browser, switch the DF to its DF, note the former DF name
	//Variable browserNumber=GetTopBrowserNumber()
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get references to the DF vars we need
	NVAR iCurrentSweep=iCurrentSweep
	NVAR traceAChecked=traceAChecked
	NVAR traceBChecked=traceBChecked	
	SVAR baseNameA=baseNameA
	SVAR baseNameB=baseNameB
	WAVE Colors=Colors
	NVAR showToolsChecked=showToolsChecked
	NVAR tBaselineLeft=tBaselineLeft
	NVAR tBaselineRight=tBaselineRight
	NVAR tWindow1Left=tWindow1Left
	NVAR tWindow1Right=tWindow1Right
	NVAR tWindow2Left=tWindow2Left
	NVAR tWindow2Right=tWindow2Right
	NVAR tFitZero=tFitZero
	NVAR tFitLeft=tFitLeft
	NVAR tFitRight=tFitRight
	NVAR yAMin=yAMin
	NVAR yAMax=yAMax
	NVAR yBMin=yBMin
	NVAR yBMax=yBMax	
	NVAR xMin=xMin
	NVAR xMax=xMax
	NVAR tCursorA
	NVAR tCursorB
	
	// Turn off output to console
	Silent 1
	
	// Note which axes currently exist
	String browserName=BrowserNameFromNumber(browserNumber)
	Variable leftAxisExists=0, rightAxisExists=0, bottomAxisExists=0		// boolean
	GetAxis /W=$browserName /Q left
	if (V_flag==0)  // V_flag will be zero if the axis actually exists
		leftAxisExists=1;
	endif
	GetAxis /W=$browserName /Q right
	if (V_flag==0)  // V_flag will be zero if the axis actually exists
		rightAxisExists=1;
	endif
	GetAxis /W=$browserName /Q bottom
	if (V_flag==0)  // V_flag will be zero if the axis actually exists
		bottomAxisExists=1;
	endif
	
	// Remove the old waves from the graph
	RemoveFromGraphAll(browserName)
	
	// Update the viable range for the current sweep control, and the current sweep
	Variable nSweeps1=NTracesFromBaseName(baseNameA)
	Variable nSweeps2=NTracesFromBaseName(baseNameB)
	Variable nSweeps=max(nSweeps1,nSweeps2)
	if (nSweeps>0)
		SetVariable setsweep, win=$browserName, limits={1,nSweeps,1}
		SetVariable setsweep, win=$browserName, value=_NUM:iCurrentSweep
	else
		SetVariable setsweep, win=$browserName, limits={1,nSweeps,0}
		SetVariable setsweep, win=$browserName, value=_STR:"(none)"		
	endif	

	// If either wave exists, do baseline subtraction
	String traceAWaveNameAbs=GetTraceAWaveNameAbs(browserNumber)
	String traceBWaveNameAbs=GetTraceBWaveNameAbs(browserNumber)
	Variable waveAExists=WaveExists($traceAWaveNameAbs)
	Variable waveBExists=WaveExists($traceBWaveNameAbs)
	if (waveAExists || waveBExists)
		DoBaseSub(browserNumber)
	endif

	// topTraceWaveName should be empty if no traces are showing
	// same for comments
	String comments=""

	// If it exists, add $traceBWaveNameAbs to the graph	
	if (traceBChecked && waveBExists)
		AppendToGraph /W=$browserName /R /C=(Colors[1][0],Colors[1][1],Colors[1][2]) $traceBWaveNameAbs
		comments=StringByKeyInWaveNote($traceBWaveNameAbs,"COMMENTS")
	endif
	
	// If it exists, add $traceAWaveNameAbs to the graph	
	if (traceAChecked && waveAExists)
		AppendToGraph /W=$browserName /C=(Colors[0][0],Colors[0][1],Colors[0][2]) $traceAWaveNameAbs
		comments=StringByKeyInWaveNote($traceAWaveNameAbs,"COMMENTS")
	endif
	
	// Write the comments to the view
	SetVariable commentsSetVariable, win=$browserName, value=_STR:comments
	
	// Put the cursors back
	String topTraceWaveNameRel=GetTopTraceWaveNameRel(browserNumber)
	if (strlen(topTraceWaveNameRel)>0 && IsFinite(tCursorA))
		Cursor /W=$browserName A $topTraceWaveNameRel tCursorA
	endif
	if (strlen(topTraceWaveNameRel)>0 && IsFinite(tCursorB))
		Cursor /W=$browserName B $topTraceWaveNameRel tCursorB
	endif
	
	// Draw the vertical lines
	if (showToolsChecked && ( (traceAChecked && waveAExists) || (traceBChecked && waveBExists) ) )
		if (IsFinite(tBaselineLeft))
	 		AddCursorLineToGraph(browserName,"baselineMarkerLeft",tBaselineLeft,65535,0,0)
	 	endif
		if (IsFinite(tBaselineRight))  // true if non-nan
			AddCursorLineToGraph(browserName,"baselineMarkerRight",tBaselineRight,65535,0,0)
		endif
		if (IsFinite(tWindow1Left))  // true if non-nan
			AddCursorLineToGraph(browserName,"window1MarkerLeft",tWindow1Left,3,52428,1)
		endif
		if (IsFinite(tWindow1Right))  // true if non-nan
			AddCursorLineToGraph(browserName,"window1MarkerRight",tWindow1Right,3,52428,1)
		endif
		if (IsFinite(tWindow2Left))  // true if non-nan
			AddCursorLineToGraph(browserName,"window2MarkerLeft",tWindow2Left,0,0,65535)
		endif
		if (IsFinite(tWindow2Right))  // true if non-nan
			AddCursorLineToGraph(browserName,"window2MarkerRight",tWindow2Right,0,0,65535)
		endif
		if (IsFinite(tFitZero))
			AddCursorLineToGraph(browserName,"fitLineZero",tFitZero,26411,1,52428)
		endif
		if (IsFinite(tFitLeft))
			AddCursorLineToGraph(browserName,"fitLineLeft",tFitLeft,0,65535,65535)
		endif
		if (IsFinite(tFitRight))
			AddCursorLineToGraph(browserName,"fitLineRight",tFitRight,0,65535,65535)
		endif
	endif
	
	// Update the rejection box to reflect the reject-status of each wave 
	UpdateRejectCheckboxes(browserNumber)
	
//	// Get the metadata associated with each wave, put relevant values in DF variables
//	NVAR baselineA
//	if (waveAExists && traceAChecked)
//		baselineA=NumberByKeyInWaveNote($traceAWaveNameAbs,"BASELINE")
//	else
//		baselineA=NaN;
//	endif
//	NVAR baselineB
//	if (waveBExists && traceBChecked)
//		baselineB=NumberByKeyInWaveNote($traceBWaveNameAbs,"BASELINE")
//	else
//		baselineB=NaN;
//	endif
	
	// Update the "Step" ValDisplays
	Variable step
	if (waveAExists && traceAChecked)
		step=NumberByKeyInWaveNote($traceAWaveNameAbs,"STEP")
	else
		step=NaN;
	endif
	ValDisplay stepAValDisplay,win=$browserName,value=_NUM:step
	WhiteOutIffNan("stepAValDisplay",browserName,step)
	if (waveBExists && traceBChecked)
		step=NumberByKeyInWaveNote($traceBWaveNameAbs,"STEP")
	else
		step=NaN;
	endif
	ValDisplay stepBValDisplay,win=$browserName,value=_NUM:step
	WhiteOutIffNan("stepBValDisplay",browserName,step)
	
	// If there is one or more trace in the graph, make sure the axes of the graph are
	// consistent with the autoscaling checkboxes, and turn on horizontal grid lines.
	String topTraceWaveNameAbs=GetTopTraceWaveNameAbs(browserNumber)
	if (ItemsInList(TraceNameList(browserName,";",1))>0)
		RescaleAxes(browserNumber)  // Scale the axes properly, based on the model state
		if (cmpstr(topTraceWaveNameAbs,traceAWaveNameAbs)==0)
			ModifyGraph /W=$browserName /Z grid(left)=1
			ModifyGraph /W=$browserName /Z gridRGB(left)=(0,0,0)
		elseif (cmpstr(topTraceWaveNameAbs,traceBWaveNameAbs)==0)
			ModifyGraph /W=$browserName /Z grid(right)=1
			ModifyGraph /W=$browserName /Z gridRGB(right)=(0,0,0)
		endif
	endif

	// Set axis labels on the graph
	Label /W=$browserName /Z bottom "\\F'Helvetica'\\Z12\\f01Time (ms)"
	if (waveAExists)
		String traceADisplayName=WaveNameFromBaseAndSweep(baseNameA,iCurrentSweep)
		String unitsA=WaveUnits($traceAWaveNameAbs,-1)  // -1 means data units
		Label /W=$browserName /Z left "\\F'Helvetica'\\Z12\\f01\K(0,0,0)"+traceADisplayName+" ("+unitsA+")"
	endif
	if (waveBExists)
		String traceBDisplayName=WaveNameFromBaseAndSweep(baseNameB,iCurrentSweep)
		String unitsB=WaveUnits($traceBWaveNameAbs,-1)
		Label /W=$browserName /Z right "\\F'Helvetica'\\Z12\\f01\K(32768,32768,32768)"+traceBDisplayName+" ("+unitsB+")"
	endif
	
	// Don't want any units in the tick labels
	ModifyGraph /W=$browserName /Z tickUnit(bottom)=1
	ModifyGraph /W=$browserName /Z tickUnit(left)=1
	ModifyGraph /W=$browserName /Z tickUnit(right)=1

	// Show/hide the tools panel, as appropriate to the state	
	if (showToolsChecked) 
		if (ToolsPanelExists(browserNumber))
			//DoWindow /F $toolsPanelName
		else
			String createPanel
			sprintf createPanel "NewToolsPanel(%d)" browserNumber
			Execute createPanel
		endif
	else
		if (ToolsPanelExists(browserNumber))
			String toDo
			sprintf toDo "KillToolsPanel(%d)" browserNumber
			Execute toDo
		endif
	endif
	
	// Update the view of the measurements
	UpdateMeasurementsView(browserNumber)
	
	// Update the visibility of the fit
	UpdateFitDisplay(browserNumber)

	// Update the visibility of stuff in the averaging pane
	UpdateAveragingDisplay(browserNumber)
	
	// Restore old data folder
	SetDataFolder savedDFName
End

Function UpdateRejectCheckboxes(browserNumber)
	// Look at the wave notes for $traceAWaveName and $traceBWaveName, and update the
	// Reject checkboxes to reflect their rejection-status 
	Variable browserNumber

	// Find name of top browser, switch the DF to its DF, note the former DF name
	String savedDF=ChangeToBrowserDF(browserNumber)
	String browserName=BrowserNameFromNumber(browserNumber)
	
	// Update the traceAWaveName reject checkbox
	String traceAWaveName=GetTraceAWaveNameAbs(browserNumber)
	Variable reject
	if ( WaveExists($traceAWaveName) )
		reject=NumberByKeyInWaveNote($traceAWaveName,"REJECT")
		reject = IsNan(reject)?0:reject;  // default to not reject if REJECT key missing
		CheckBox rejectACheckbox, win=$browserName, value=reject
	endif
	
	// Update the traceBWaveName reject checkbox
	String traceBWaveName=GetTraceBWaveNameAbs(browserNumber)
	if ( WaveExists($traceBWaveName) )
		reject=NumberByKeyInWaveNote($traceBWaveName,"REJECT")
		reject = IsNan(reject)?0:reject;
		CheckBox rejectBCheckbox, win=$browserName, value=reject
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function AddCursorLineToGraph(graphName,cursorWaveName,tCursor,r,g,b)
	// Adds a wave to the named graph that represents a cursor position.
	String graphName  // the name of the graph to add the cursor line to
	String cursorWaveName  // what to name the wave that is the cursor
	Variable tCursor // the time at which to place the cursor
	Variable r,g,b  // the color
	
	// Go through a lot of trouble to find the y span of the cursor	
	SVAR baseNameA=baseNameA
	SVAR baseNameB=baseNameB
	NVAR iCurrentSweep=iCurrentSweep
		
	// Get the max and min of wave A trace
	String traceAWaveName=sprintf2sd("root:%s%d", baseNameA, iCurrentSweep)
	Variable waveAExists=WaveExists($traceAWaveName)
	Variable yAMin, yAMax
	if (waveAExists)
		WaveStats /Q $traceAWaveName
		yAMax=V_max
		yAMin=V_min
	else
		yAMin=+inf
		yAMax=-inf
	endif

	// Get the max and min of wave B trace
	String traceBWaveName=sprintf2sd("root:%s%d", baseNameB, iCurrentSweep)
	Variable waveBExists=WaveExists($traceBWaveName)		
	Variable yBMin, yBMax
	if (waveBExists)
		WaveStats /Q $traceBWaveName
		yBMax=V_max
		yBMin=V_min
	else
		yBMin=+inf
		yBMax=-inf
	endif
			
	// Get the overall yMin, yMax
	Variable yMin=min(yAMin,yBMin)
	Variable yMax=max(yAMax,yBMax)
	
	if (NumType(yMin)!=0)  // is yMin a normal number (non-inf)?
		yMin=-1
	endif
	if (NumType(yMax)!=0)  // is yMax a normal number (non-inf)?
		yMax=+1
	endif
	
	// Now that yMin and yMax are determined, draw the cursors
	Make /O /N=2 $cursorWaveName ={yMin,yMax}
	Setscale /I x, tCursor, tCursor+1e-6, "ms", $cursorWaveName
	String windowSpec=sprintf1s("WIN:%s",graphName)
	SVAR cursorWaveList=cursorWaveList
	if (ItemsInList(WaveList(cursorWaveName,";",windowSpec))>0)
		RemoveFromGraph /W=$graphName $cursorWaveName  // remove if already present
		cursorWaveList=RemoveFromList(cursorWaveName,cursorWaveList)
	endif
	AppendToGraph /W=$graphName /C=(r,g,b) $cursorWaveName
	cursorWaveList=AddListItem(cursorWaveName,cursorWaveList)
End

Function UpdateFitDisplay(browserNumber)
	Variable browserNumber
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get instance vars we'll need
	NVAR showToolsChecked
	NVAR isFitValid  // boolean
	SVAR waveNameAbsOfFitTrace
	NVAR yOffsetHeldValue

	// Add or remove yFit to the browserWindow, as needed
	// Also show/hide the fit coefficients, depending on many factors
	String topTraceWaveNameAbs=GetTopTraceWaveNameAbs(browserNumber)
	String browserName=BrowserNameFromNumber(browserNumber)
	String windowSpec=sprintf1s("WIN:%s",browserName)
	if (showToolsChecked)
		// the fit sub-panel is showing
		SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,value=_NUM:yOffsetHeldValue

		if ( strlen(topTraceWaveNameAbs)>0 )
			// there is a trace showing
			if ( isFitValid )
				// the fit sub-panel is showing, there is a trace showing in the browser, and 
				// the current fit coefficients are valid
				if ( AreStringsEqual(topTraceWaveNameAbs,waveNameAbsOfFitTrace) )
					// the fit sub-panel is showing, there is a trace showing, and 
					// the displayed trace is the one the fit applies to
					// Ensure that yFit is displayed
					if (ItemsInList(WaveList("yFit",";",windowSpec))==0)
						AppendToGraph /W=$browserName yFit
					endif
					// show the fit parameters
					SetFitCoefficientVisibility(browserNumber,1)					
				else
					// the fit sub-panel is showing, there is a trace showing, the current fit
					// coefficients are valid, but
					// the displayed trace is _not_ the one the fit applies to
					if ( ItemsInList(WaveList("yFit",";",windowSpec))>0 )
						RemoveFromGraph /W=$browserName yFit  // remove yFit if already present
					endif
					// blank the fit parameters
					SetFitCoefficientVisibility(browserNumber,0)
				endif
			else
				// the fit sub-panel is showing, there is a trace showing in the browser, but 
				// the current fit coefficients are not valid
				if ( ItemsInList(WaveList("yFit",";",windowSpec))>0 )
					RemoveFromGraph /W=$browserName yFit  // remove yFit if already present
				endif
				// blank the fit parameters
				SetFitCoefficientVisibility(browserNumber,0)
			endif
		else
			// the tools panel is showing, but no trace is showing in the browser
			if ( ItemsInList(WaveList("yFit",";",windowSpec))>0 )
				RemoveFromGraph /W=$browserName yFit  // remove if already present
			endif
			// blank the fit parameters
			SetFitCoefficientVisibility(browserNumber,0)		
		endif
		// make sure the hold y offset SetVariable is enabled
		NVAR holdYOffset, yOffsetHeldValue
		if ( holdYOffset )
			SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,disable=0  // normal
		else
			//SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,disable=1  // invisible
			SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,disable=2  // grayed
		endif
	else
		// the fit sub-panel is not showing
		if ( ItemsInList(WaveList("yFit",";",windowSpec))>0 )
			RemoveFromGraph /W=$browserName yFit  // remove if already present
		endif
		// no need to update anything else
	endif
End

Function SetFitCoefficientVisibility(browserNumber,visible)
	Variable browserNumber
	Variable visible  // boolean
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	String browserName=BrowserNameFromNumber(browserNumber)
	
	// Get instance vars we'll need
	SVAR fitType
	if (visible)
		// show the fit parameters, at least those relevant to the current fit type
		ValDisplay yOffsetValDisplay, win=$browserName#ToolsPanel, valueColor=(0,0,0)
		ValDisplay tau1ValDisplay, win=$browserName#ToolsPanel, valueColor=(0,0,0)
		ValDisplay amp1ValDisplay, win=$browserName#ToolsPanel, valueColor=(0,0,0)
		if ( AreStringsEqual(fitType,"single exp") )
			ValDisplay tau2ValDisplay, win=$browserName#ToolsPanel, valueColor=(65535,65535,65535)
			ValDisplay amp2ValDisplay, win=$browserName#ToolsPanel, valueColor=(65535,65535,65535)
		else
			ValDisplay tau2ValDisplay, win=$browserName#ToolsPanel, valueColor=(0,0,0)
			ValDisplay amp2ValDisplay, win=$browserName#ToolsPanel, valueColor=(0,0,0)
		endif
	else
		// blank the fit parameters
		ValDisplay yOffsetValDisplay, win=$browserName#ToolsPanel, valueColor=(65535,65535,65535)
		ValDisplay tau1ValDisplay, win=$browserName#ToolsPanel, valueColor=(65535,65535,65535)
		ValDisplay amp1ValDisplay, win=$browserName#ToolsPanel, valueColor=(65535,65535,65535)
		ValDisplay tau2ValDisplay, win=$browserName#ToolsPanel, valueColor=(65535,65535,65535)
		ValDisplay amp2ValDisplay, win=$browserName#ToolsPanel, valueColor=(65535,65535,65535)
	endif
End

Function UpdateMeasurementsView(browserNumber)
	Variable browserNumber
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	String browserName=BrowserNameFromNumber(browserNumber)
	
	// Get instance vars we'll need
	NVAR showToolsChecked
	NVAR baseline, mean1, peak1, rise1
	NVAR mean2, peak2, rise2
	NVAR nCrossings1

	// white them out if they're nan
	String windowName=browserName+"#ToolsPanel"
	if (showToolsChecked)
		WhiteOutIffNan("baselineValDisplay",windowName,baseline)
		WhiteOutIffNan("mean1ValDisplay",windowName,mean1)
		WhiteOutIffNan("peak1ValDisplay",windowName,peak1)
		WhiteOutIffNan("rise1ValDisplay",windowName,rise1)
		WhiteOutIffNan("mean2ValDisplay",windowName,mean2)
		WhiteOutIffNan("peak2ValDisplay",windowName,peak2)
		WhiteOutIffNan("rise2ValDisplay",windowName,rise2)
		WhiteOutIffNan("cross1ValDisplay",windowName,nCrossings1)
	endif
	
End

Function RescaleAxes(browserNumber)
	// In the indicated DPBrowser, configures the scaling of the graph axes based on 
	// the autoscale settings (as reflected in the model), and the axis limits
	Variable browserNumber

	// Set up access to the DF vars we need
	NVAR traceAChecked=traceAChecked
	NVAR traceBChecked=traceBChecked	
	NVAR yAMin=yAMin
	NVAR yAMax=yAMax
	NVAR yBMin=yBMin
	NVAR yBMax=yBMax	
	NVAR xMin=xMin
	NVAR xMax=xMax
	NVAR xAutoscaling=xAutoscaling
	NVAR yAAutoscaling=yAAutoscaling
	NVAR yBAutoscaling=yBAutoscaling
	
	// Change to the DF of the indicated DPBrowser
	String savedDF=ChangeToBrowserDF(browserNumber)
	
	// Get the window name of the DPBrowser
	String browserName=BrowserNameFromNumber(browserNumber)
	
	// Scale the y axis for trace A
	if (traceAChecked)
		if (yAAutoscaling)
			Setaxis /W=$browserName /Z /A left  // autoscale the left y axis
		else
			Setaxis /W=$browserName /Z left yAMin, yAMax  // set the y axis to have the limits it currently has
		endif
	endif
	
	// Scale the y axis for trace B
	if (traceBChecked)
		if (yBAutoscaling)
			Setaxis /W=$browserName /Z /A right  // autoscale the right y axis
		else
			Setaxis /W=$browserName /Z right yBMin, yBMax  // set the y axis to have the limits it currently has
		endif
	endif
	
	// Scale the x axis
	if ( traceAChecked || traceBChecked )
		if (xAutoscaling)
			Setaxis /W=$browserName /Z /A bottom    // autoscale the bottom (x) axis
		else
			Setaxis /W=$browserName /Z bottom xMin, xMax  // set the x axis to have the limits it currently has
		endif
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End

//Function SyncFitPanelViewToDFState(browserNumber)
//	// This syncs the indicated FitPanel view to the values of the state variables in the browser's DF,
//	// which are assumed to be self-consistent.
//	Variable browserNumber
//
//	// Turn off window updates, and output to console
//	PauseUpdate; Silent 1
//	
//	// Find name of top browser, switch the DF to its DF, note the former DF name
//	//Variable browserNumber=GetTopBrowserNumber()
//	String savedDFName=ChangeToBrowserDF(browserNumber)
//
//	// Enable/disable the yOffset hold thing
//	NVAR holdYOffset=holdYOffset
//	String fitPanelName=FitPanelNameFromNumber(browserNumber)
//	if (holdYOffset)
//		SetVariable yOffsetHeldValueSetVariable,win=$fitPanelName,disable=0
//	else
//		SetVariable yOffsetHeldValueSetVariable,win=$fitPanelName,disable=2
//	endif
//	
//	// Restore old data folder
//	SetDataFolder savedDFName
//End

Function UpdateAveragingDisplay(browserNumber)
	Variable browserNumber
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	String toolsPanelName=ToolsPanelNameFromNumber(browserNumber)
	NVAR showToolsChecked
	if (showToolsChecked)
		// the tools panel is showing
		// Show/hide the sweeps SetVariables
		NVAR averageAllSweeps
		SetVariable  firstSweepSetVariable,win=$toolsPanelName,disable=2*averageAllSweeps
		SetVariable  lastSweepSetVariable,win=$toolsPanelName,disable=2*averageAllSweeps
		NVAR averageAllSteps
		SetVariable stepsSetVariable,win=$toolsPanelName,disable=2*averageAllSteps
	endif
	SetDataFolder savedDFName
End
