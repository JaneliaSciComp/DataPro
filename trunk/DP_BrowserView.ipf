// This contains the "methods" of the DP Browser View.  Of course, this idea is largely conceptual, since
// Igor Pro doesn't have OOP features.

#pragma rtGlobals=1		// Use modern global access method.

Function BrowserViewConstructor(browserNumber) : Graph
	// Figure out what the index of this DataProBrowser instance should be
	Variable browserNumber

	// Find name of top browser, switch the DF to its DF, note the former DF name
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Layout the window widgets
	String browserName=BrowserNameFromNumber(browserNumber)
	String browserTitle=BrowserTitleFromNumber(browserNumber)
	// These are all in pixels
	Variable xOffset=8
	Variable yOffset=54
	Variable width=700
	Variable height=680
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=$browserName as browserTitle
	SetWindow $browserName, hook(DPHook)=BrowserContHook
	ShowInfo
	
	// Draw the top "panel" and associated controls 
	ControlBar /T /W=$browserName 100
	
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	String absVarName=AbsoluteVarName(browserDFName,"yAAutoscaling")
	CheckBox autoscaleYACheckbox,win=$browserName,pos={106,80},size={102,14},proc=BrowserContRescaleCB,title="Autoscale y for trace A"
	CheckBox autoscaleYACheckbox,win=$browserName,value= 1, variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"yBAutoscaling")
	CheckBox autoscaleYBCheckbox,win=$browserName,pos={246,80},size={102,14},proc=BrowserContRescaleCB,title="Autoscale y for trace B"
	CheckBox autoscaleYBCheckbox,win=$browserName,value= 1, variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"xAutoscaling")
	CheckBox autoscaleXCheckbox,win=$browserName,pos={386,80},size={72,14},proc=BrowserContRescaleCB,title="Autoscale x"
	CheckBox autoscaleXCheckbox,win=$browserName,value= 1, variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"iCurrentSweep")
	SetVariable setSweepIndexSV,win=$browserName,pos={11,15},size={100,18},proc=BrowserContNextSweepIndexSV,title="Sweep"
	SetVariable setSweepIndexSV,win=$browserName,fSize=12
	SetVariable setSweepIndexSV,win=$browserName,limits={1,100000,1},value=_NUM:1
	
	Variable yBaselineForTraceA=7
	Variable yBaselineForTraceB=30
	absVarName=AbsoluteVarName(browserDFName,"traceAChecked")
	CheckBox showTraceACheckbox,win=$browserName,pos={125,yBaselineForTraceA},size={39,14}
	CheckBox showTraceACheckbox,win=$browserName,proc=BrowserContShowTraceCB,title="Tr.A",value= 1
	CheckBox showTraceACheckbox,win=$browserName,variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"traceBChecked")
	CheckBox showTraceBCheckbox,win=$browserName,pos={125,yBaselineForTraceB},size={39,14}
	CheckBox showTraceBCheckbox,win=$browserName,proc=BrowserContShowTraceCB,title="Tr.B",value= 0
	CheckBox showTraceBCheckbox,win=$browserName,variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"baseNameA")
	SetVariable bnameset_1,win=$browserName,pos={176,yBaselineForTraceA},size={80,14},proc=BrowserContBaseNameSV,title="Name"
	SetVariable bnameset_1,win=$browserName,value=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"baseNameB")
	SetVariable bnameset_2,win=$browserName,pos={176,yBaselineForTraceB},size={80,14},proc=BrowserContBaseNameSV,title="Name"
	SetVariable bnameset_2,win=$browserName,value=$absVarName
		
	// This kind of color popup doesn't work in a ControlBar, seemingly...
	//PopupMenu traceAColorPopupMenu,pos={262,yBaselineForTraceA},size={96,20},proc=ColorPopMenuProc,title="color:"
	//PopupMenu traceAColorPopupMenu,mode=1,popColor= (0,65535,65535),value= "*COLORPOP*"	
	
	SVAR colorNameList
	String colorNameListFU="\""+colorNameList+"\""
	PopupMenu traceAColorPopupMenu,win=$browserName,pos={265,yBaselineForTraceA-2},size={96,14},bodyWidth=65,proc=BrowserContTraceAColorPopup,title="Color"
	PopupMenu traceAColorPopupMenu,win=$browserName,value=#colorNameListFU
	PopupMenu traceBColorPopupMenu,win=$browserName,pos={265,yBaselineForTraceB-2},size={96,14},bodyWidth=65,proc=BrowserContTraceBColorPopup,title="Color"
	PopupMenu traceBColorPopupMenu,win=$browserName,value=#colorNameListFU
		
	xOffset=370		// pixels
	CheckBox rejectACheckbox,win=$browserName,pos={xOffset,yBaselineForTraceA},size={49,14},proc=BrowserContRejectTraceACB,title="Reject"
	CheckBox rejectACheckbox,win=$browserName,value= 0
	CheckBox rejectBCheckbox,win=$browserName,pos={xOffset,yBaselineForTraceB},size={49,14},proc=BrowserContRejectTraceBCB,title="Reject"
	CheckBox rejectBCheckbox,win=$browserName,value= 0
	
	xOffset=xOffset+65
	ValDisplay stepAValDisplay,win=$browserName,pos={xOffset,yBaselineForTraceA},size={70,14},title="Step:",format="%3.3g"
	ValDisplay stepAValDisplay,win=$browserName,limits={0,0,0},value=_NUM:nan
	
	ValDisplay stepBValDisplay,win=$browserName,pos={xOffset,yBaselineForTraceB},size={70,14},title="Step:",format="%3.3g"
	ValDisplay stepBValDisplay,win=$browserName,limits={0,0,0},value=_NUM:nan
	
	SetVariable commentsSetVariable,win=$browserName,pos={20,55},size={260,15},title="comments"
	SetVariable commentsSetVariable,win=$browserName,proc=BrowserContCommentsSV,value=_STR:""

	absVarName=AbsoluteVarName(browserDFName,"showToolsChecked")
	CheckBox showToolsCheckbox,win=$browserName,pos={610,yBaselineForTraceA+1},size={70,18},proc=BrowserContShowToolsPanelCB, value=0
	CheckBox showToolsCheckbox,win=$browserName,title="Show Tools",variable=$absVarName
	
	// Sync the view with the "model"
	BrowserViewModelChanged(browserNumber)
	
	// Restore old data folder
	SetDataFolder savedDFName	
End

Function BrowserViewDrawToolsPanel(browserNumber) : Panel
	Variable browserNumber // the number of the DataProBrowser we belong to
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)
	
	// From the browser number, derive the measure panel window name and title
	String browserWindowName=BrowserNameFromNumber(browserNumber)
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	String panelName=browserWindowName+"#ToolsPanel"
	
	// Create the panel, draw all the controls
	Variable toolsPanelWidth=250  // pels
	Variable measureAreaHeight=278  // pels
	Variable fitAreaHeight=155+30  // pels
	Variable averageAreaHeight=110-28  // pels
	Variable toolsPanelHeight=measureAreaHeight+fitAreaHeight+averageAreaHeight
	NewPanel /HOST=$browserWindowName /EXT=0 /W=(0,0,toolsPanelWidth,toolsPanelHeight) /N=ToolsPanel /K=1 as "Tools"
	SetWindow $browserWindowName#ToolsPanel, hook(TPHook)=BrowserContToolsPanelHook  // register a callback function for if the panel is closed

	// Measure controls

	// Some dimensions and such
	
	// Baseline controls
	Variable yOffset=6
	SetDrawEnv linethick= 3,linefgc= (65535,0,0)
	DrawRect 6-3,yOffset-3,6+100+3,yOffset+20+3
	Button setbase,pos={6,yOffset},size={100,20},proc=BrowserContSetBaselineButton,title="Set Baseline"
	Button clearBaselineButton,pos={6,yOffset+27},size={100,18},proc=BrowserContClearBaselineButton,title="Clear Baseline"

	String absVarName=AbsoluteVarName(browserDFName,"baseline")
	ValDisplay baselineValDisplay,win=$panelName,pos={138,8},size={82,17},title="Mean:",format="%4.2f"
	ValDisplay baselineValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox baselineMeanUnitsTitleBox, win=$panelName, pos={138+82+3,8+2},frame=0

	// Window 1 controls
	yOffset=70
	SetDrawEnv linethick= 3,linefgc= (3,52428,1)
	DrawRect 3,yOffset-3,109,yOffset+20+3
	Button setwin_1,win=$panelName,pos={6,yOffset},size={100,20},proc=BrowserContSetWindow1Button,title="Set Window 1"
	Button clearWindow1Button,win=$panelName,pos={6,yOffset+27},size={100,18},proc=BrowserContClearWindow1Button,title="Clear Window 1"

	absVarName=AbsoluteVarName(browserDFName,"mean1")
	ValDisplay mean1ValDisplay,win=$panelName,pos={138,yOffset-5},size={82,17},title="Mean:",format="%4.2f"
	ValDisplay mean1ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox window1MeanUnitsTitleBox, win=$panelName, pos={138+82+3,yOffset-5+2},frame=0

	absVarName=AbsoluteVarName(browserDFName,"peak1")
	ValDisplay peak1ValDisplay,win=$panelName,pos={138,yOffset+17},size={82,17},title="Peak:",format="%4.2f"
	ValDisplay peak1ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox window1PeakUnitsTitleBox, win=$panelName, pos={138+82+3,yOffset+17+2},frame=0

	absVarName=AbsoluteVarName(browserDFName,"rise1")
	ValDisplay rise1ValDisplay,win=$panelName,pos={115,yOffset+38},size={105,17},title="Transit Time:"
	ValDisplay rise1ValDisplay,win=$panelName,format="%4.2f",limits={0,0,0},barmisc={0,1000}
	ValDisplay rise1ValDisplay,win=$panelName,value= #absVarName
	TitleBox rise1UnitsTitleBox,win=$panelName,pos={115+105+3,yOffset+38+2},frame=0

	absVarName=AbsoluteVarName(browserDFName,"from1")
	SetVariable from_disp1,win=$panelName,pos={54,yOffset+61},size={80,17},proc=BrowserContMeasurementSV,title="From"
	SetVariable from_disp1,win=$panelName,limits={0,100,10},value=$absVarName
	TitleBox from1UnitsTitleBox,win=$panelName,pos={137,yOffset+61+2},frame=0, title="%"

	absVarName=AbsoluteVarName(browserDFName,"to1")
	SetVariable to_disp1,win=$panelName,pos={154,yOffset+61},size={66,17},proc=BrowserContMeasurementSV,title="To"
	SetVariable to_disp1,win=$panelName,limits={0,100,10},value=$absVarName
	TitleBox to1UnitsTitleBox,win=$panelName,pos={223,yOffset+61+2},frame=0, title="%"
	
	absVarName=AbsoluteVarName(browserDFName,"lev1")
	SetVariable levelSetVariable,win=$panelName,pos={18,yOffset-61+145},size={80,17}
	SetVariable levelSetVariable,win=$panelName,proc=BrowserContMeasurementSV,title="Level"
	SetVariable levelSetVariable,win=$panelName,limits={-100,100,10},format="%4.2f",value=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"nCrossings1")
	ValDisplay cross1ValDisplay,win=$panelName,pos={110,yOffset-61+145},size={110,17},title="No. Crossings:"
	ValDisplay cross1ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},format="%4.0f",value= #absVarName
	
	// Window 2 controls
	yOffset=190
	SetDrawEnv linethick= 3,linefgc= (0,0,65535)
	DrawRect 3,yOffset-3,109,yOffset+20+3
	Button setwin_2,win=$panelName,pos={6,yOffset},size={100,20},proc=BrowserContSetWindow2Button,title="Set Window 2"
	Button clearWindow2Button,win=$panelName,pos={6,yOffset+27},size={100,18},proc=BrowserContClearWindow2Button,title="Clear Window 2"

	absVarName=AbsoluteVarName(browserDFName,"mean2")
	ValDisplay mean2ValDisplay,win=$panelName,pos={138,yOffset-5},size={82,17},title="Mean:",format="%4.2f"
	ValDisplay mean2ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox window2MeanUnitsTitleBox, win=$panelName, pos={138+82+3,yOffset-5+2},frame=0
	
	absVarName=AbsoluteVarName(browserDFName,"peak2")
	ValDisplay peak2ValDisplay,win=$panelName,pos={138,yOffset+17},size={82,17},title="Peak:",format="%4.2f"
	ValDisplay peak2ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox window2PeakUnitsTitleBox, win=$panelName, pos={138+82+3,yOffset+17+2},frame=0

	absVarName=AbsoluteVarName(browserDFName,"rise2")
	ValDisplay rise2ValDisplay,win=$panelName,pos={115,yOffset+38},size={105,17},title="Transit Time:"
	ValDisplay rise2ValDisplay,win=$panelName,format="%4.2f",limits={0,0,0},barmisc={0,1000}
	ValDisplay rise2ValDisplay,win=$panelName,value= #absVarName
	TitleBox rise2UnitsTitleBox,win=$panelName,pos={115+105+3,yOffset+38+2},frame=0
	
	absVarName=AbsoluteVarName(browserDFName,"from2")
	SetVariable from_disp2,win=$panelName,pos={54,yOffset+61},size={80,17},proc=BrowserContMeasurementSV,title="From"
	SetVariable from_disp2,win=$panelName,limits={0,100,10},value=$absVarName
	TitleBox from2UnitsTitleBox,win=$panelName,pos={137,yOffset+61+2},frame=0, title="%"

	absVarName=AbsoluteVarName(browserDFName,"to2")
	SetVariable to_disp2,win=$panelName,pos={154,yOffset+61},size={66,17},proc=BrowserContMeasurementSV,title="To"
	SetVariable to_disp2,win=$panelName,limits={0,100,10},value=$absVarName
	TitleBox to2UnitsTitleBox,win=$panelName,pos={223,yOffset+61+2},frame=0, title="%"

	// Horizontal rule
	DrawLine 8,measureAreaHeight,245,measureAreaHeight

	// Fitting controls
	yOffset=measureAreaHeight
	
	SetDrawEnv linethick= 3,linefgc= (26411,0,52428)	// purple
	DrawRect 16-3,yOffset+36-3+2,16+100+2,yOffset+36+20+2+2
	Button set_tFitZero,win=$panelName,pos={16,yOffset+36+2},size={100,20},proc=BrowserContSetFitZeroButton,title="Set Zero"
	Button clearTFitZero,win=$panelName,pos={16,yOffset+36+28},size={100,18},proc=BrowserContClearFitZeroButton,title="Clear Zero"

	Button fitButton,win=$panelName,pos={140,yOffset+10},size={100,20},proc=BrowserContFitButton,title="Fit"

	SetDrawEnv linethick= 3,linefgc= (0,65535,65535)	// cyan
	DrawRect 140-3,yOffset+36-3+2,140+100+2,yOffset+36+20+2+2
	Button set_fit_range,win=$panelName,pos={140,yOffset+36+2},size={100,20},proc=BrowserContSetFitRangeButton,title="Set Range"

	Button clearTFitRange,win=$panelName,pos={140,yOffset+36+28},size={100,18},proc=BrowserContClearFitRangeButton,title="Clear Range"

	PopupMenu fitTypePopupMenu,win=$panelName,pos={6,yOffset+10},size={120,19},bodyWidth=120
	PopupMenu fitTypePopupMenu,win=$panelName,mode=1,value= #"\"Exponential;Double Exponential\""	
	PopupMenu fitTypePopupMenu,win=$panelName,proc=BrowserContFitTypePopup
	
	absVarName=AbsoluteVarName(browserDFName,"tau1")
	ValDisplay tau1ValDisplay,win=$panelName,pos={6,yOffset+64+28},size={75,17},title="Tau 1:",format="%4.2f"
	ValDisplay tau1ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox tau1UnitsTitleBox,win=$panelName,pos={6+75+3,yOffset+64+28+2},frame=0
		
	absVarName=AbsoluteVarName(browserDFName,"amp1")
	ValDisplay amp1ValDisplay,win=$panelName,pos={6,yOffset+82+28},size={75,17},title="Amp 1:",format="%4.2f"
	ValDisplay amp1ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox amp1UnitsTitleBox, win=$panelName, pos={6+75+3,yOffset+82+28+2},frame=0
	
	absVarName=AbsoluteVarName(browserDFName,"tau2")
	ValDisplay tau2ValDisplay,win=$panelName,pos={119,yOffset+64+28},size={75,17},title="Tau 2:",format="%4.2f"
	ValDisplay tau2ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox tau2UnitsTitleBox,win=$panelName,pos={119+75+3,yOffset+64+28+2},frame=0
	
	absVarName=AbsoluteVarName(browserDFName,"amp2")
	ValDisplay amp2ValDisplay,win=$panelName,pos={119,yOffset+82+28},size={75,17},title="Amp 2:",format="%4.2f"
	ValDisplay amp2ValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox amp2UnitsTitleBox, win=$panelName, pos={119+75+3,yOffset+82+28+2},frame=0
	
	// N.B.: This one doesn't use a binding, so the callback must handle updating the model
	NVAR dtFitExtend
	absVarName=AbsoluteVarName(browserDFName,"dtFitExtend")
	SetVariable dtFitExtendSetVariable,win=$panelName,pos={7,yOffset+125+28},size={98,17},title="Show fit"
	SetVariable dtFitExtendSetVariable,win=$panelName,limits={0,10000,10},value= _NUM:dtFitExtend
	SetVariable dtFitExtendSetVariable,win=$panelName,proc=BrowserContDtFitExtendSV
	TitleBox dtFitExtendUnitsTitleBox,win=$panelName,pos={109,yOffset+125+28+2},frame=0, title="ms beyond range"
	
	absVarName=AbsoluteVarName(browserDFName,"yOffset")
	ValDisplay yOffsetValDisplay,win=$panelName,pos={7,yOffset+102+28},size={90,17},title="Offset:",format="%4.2f"
	ValDisplay yOffsetValDisplay,win=$panelName,limits={0,0,0},barmisc={0,1000},value= #absVarName
	TitleBox yOffsetUnitsTitleBox, win=$panelName, pos={7+90+3,yOffset+102+28+2},frame=0
	
	// N.B.: This one doesn't use a binding, so the callback must handle updating the model
	NVAR holdYOffset
	CheckBox holdYOffsetCheckbox,win=$panelName,pos={128,yOffset+102+28+1},size={50,20},title="Hold",value=holdYOffset
	CheckBox holdYOffsetCheckbox,win=$panelName,proc=BrowserContHoldYOffsetCB
	
	// N.B.: This one doesn't use a binding, so the callback must handle updating the model
	NVAR yOffsetHeldValue
	SetVariable yOffsetHeldValueSetVariable,win=$panelName,pos={128+46,yOffset+102+28},size={70,17},title="at",format="%4.2f"
	SetVariable yOffsetHeldValueSetVariable,win=$panelName,limits={-Inf,Inf,1},value=_NUM:yOffsetHeldValue
	SetVariable yOffsetHeldValueSetVariable,win=$panelName,proc=BrowserContYOffsetHeldValueSV	
	//TitleBox yOffsetHeldValueUnitsTitleBox, win=$panelName, pos={120+46+70+3,yOffset+102+28+2},frame=0

	// Horizontal rule
	DrawLine 8,measureAreaHeight+fitAreaHeight-3,245,measureAreaHeight+fitAreaHeight-3

	// Averaging controls
	yOffset=measureAreaHeight+fitAreaHeight

	Button avgnow,win=$panelName,pos={20,yOffset+5},size={100,20},proc=BrowserContAverageSweepsButton,title="Average Sweeps"

	NVAR renameAverages
	CheckBox renameAveragesCheckBox,win=$panelName,pos={150,yOffset+8},size={100,20},title="Rename",value=renameAverages
	CheckBox renameAveragesCheckBox,win=$panelName,proc=BrowserContRenameAveragesCB

	// Controls for which sweeps to average
	yOffset=yOffset+63-28
	NVAR averageAllSweeps, iSweepFirstAverage, iSweepLastAverage
	TitleBox sweepsTitleBox,win=$panelName,pos={20,yOffset},frame=0,title="Sweeps:"
	CheckBox allSweepsCheckBox,win=$panelName,pos={70,yOffset},size={50,20},title="All",value=averageAllSweeps
	CheckBox allSweepsCheckBox,win=$panelName,proc=BrowserContAllSweepsCB
	
	//absVarName=AbsoluteVarName(browserDFName,"iSweepFirstAverage")
	SetVariable firstSweepSetVariable,win=$panelName,pos={110,yOffset},size={53,17},title=" "
	SetVariable firstSweepSetVariable,win=$panelName,limits={1,2000,1},proc=BrowserContFirstSweepSV
	
	SetVariable lastSweepSetVariable,win=$panelName,pos={170,yOffset},size={66,17},title="to"
	SetVariable lastSweepSetVariable,win=$panelName,limits={1,2000,1},proc=BrowserContLastSweepSV
	
	// Controls for which steps to show:
	yOffset=yOffset+88-63
	NVAR averageAllSteps
	TitleBox stepsTitleBox,win=$panelName,pos={20,yOffset},frame=0,title="Steps:"
	CheckBox allStepsCheckBox,win=$panelName,pos={70,yOffset},size={50,20},title="All",value=averageAllSteps
	CheckBox allStepsCheckBox,win=$panelName,proc=BrowserContAllStepsCB
	SetVariable stepsSetVariable,win=$panelName,pos={110,yOffset-1},size={85,17},title="Only:"
	SetVariable stepsSetVariable,win=$panelName,limits={-1000,1000,10},proc=BrowserContStepsSV

	// set the enablement of the averaging fields appropriately
	BrowserViewUpdateAveraging(browserNumber)

	// Restore original data folder
	SetDataFolder savedDF	
End

Function BrowserViewModelChanged(browserNumber)
	// This syncs the indicated DPBrowser view to the values of the model variables in the browser's DF,
	// which are assumed to be self-consistent.
	Variable browserNumber

	// If the window doesn't exist, nothing to do
	String browserName=BrowserNameFromNumber(browserNumber)	
	if (!GraphExists(browserName))
		return 0		// Have to return something
	endif

	// Find name of top browser, switch the DF to its DF, note the former DF name
	//Variable browserNumber=GetTopBrowserNumber()
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get references to the DF vars we need
	NVAR iCurrentSweep
	NVAR traceAChecked
	NVAR traceBChecked
	SVAR baseNameA
	SVAR baseNameB
	WAVE Colors
	NVAR showToolsChecked
	NVAR tBaselineLeft
	NVAR tBaselineRight
	NVAR tWindow1Left
	NVAR tWindow1Right
	NVAR tWindow2Left
	NVAR tWindow2Right
	NVAR tFitZero
	NVAR tFitLeft
	NVAR tFitRight
	NVAR yAMin
	NVAR yAMax
	NVAR yBMin
	NVAR yBMax
	NVAR xMin
	NVAR xMax
	NVAR tCursorA
	NVAR tCursorB
	SVAR colorNameList
	SVAR colorNameA
	SVAR colorNameB
	
	// Note which axes currently exist
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
	Variable minSweepIndexA=minSweepIndexFromBaseName(baseNameA)
	Variable minSweepIndexB=minSweepIndexFromBaseName(baseNameB)
	Variable minSweepIndexOverall=min(minSweepIndexA,minSweepIndexB)
	Variable maxSweepIndexA=maxSweepIndexFromBaseName(baseNameA)
	Variable maxSweepIndexB=maxSweepIndexFromBaseName(baseNameB)
	Variable maxSweepIndexOverall=max(maxSweepIndexA,maxSweepIndexB)
	if ( maxSweepIndexOverall >=minSweepIndexOverall )
		SetVariable setSweepIndexSV, win=$browserName, limits={minSweepIndexOverall,maxSweepIndexOverall,1}
		SetVariable setSweepIndexSV, win=$browserName, value=_NUM:iCurrentSweep
	else
		SetVariable setSweepIndexSV, win=$browserName, limits={minSweepIndexOverall,maxSweepIndexOverall,0}
		SetVariable setSweepIndexSV, win=$browserName, value=_STR:"(none)"		
	endif	

	// Update the color selector popups
	PopupMenu traceAColorPopupMenu,win=$browserName,popmatch=colorNameA
	PopupMenu traceBColorPopupMenu,win=$browserName,popmatch=colorNameB

	// If either wave exists, do baseline subtraction
	String traceAWaveNameAbs=BrowserModelGetAWaveNameAbs(browserNumber)
	String traceBWaveNameAbs=BrowserModelGetBWaveNameAbs(browserNumber)
	Variable waveAExists=WaveExists($traceAWaveNameAbs)
	Variable waveBExists=WaveExists($traceBWaveNameAbs)
	if (waveAExists || waveBExists)
		BrowserModelDoBaseSub(browserNumber)
	endif

	// topTraceWaveName should be empty if no traces are showing
	// same for comments
	String comments=""

	// If it exists, add $traceBWaveNameAbs to the graph
	Variable iColorB=WhichListItem(colorNameB,colorNameList)
	if (traceBChecked && waveBExists)
		AppendToGraph /W=$browserName /R /C=(colors[0][iColorB],colors[1][iColorB],colors[2][iColorB]) $traceBWaveNameAbs
		comments=StringByKeyInWaveNote($traceBWaveNameAbs,"COMMENTS")
	endif
	
	// If it exists, add $traceAWaveNameAbs to the graph	
	Variable iColorA=WhichListItem(colorNameA,colorNameList)
	if (traceAChecked && waveAExists)
		AppendToGraph /W=$browserName /C=(colors[0][iColorA],colors[1][iColorA],colors[2][iColorA]) $traceAWaveNameAbs
		comments=StringByKeyInWaveNote($traceAWaveNameAbs,"COMMENTS")
	endif
	
	// Write the comments to the view
	SetVariable commentsSetVariable, win=$browserName, value=_STR:comments
	
	// Put the cursors back
	String topTraceWaveNameRel=BrowserModelGetTopWaveNameRel(browserNumber)
	if (strlen(topTraceWaveNameRel)>0 && IsFinite(tCursorA))
		Cursor /W=$browserName A $topTraceWaveNameRel tCursorA
	endif
	if (strlen(topTraceWaveNameRel)>0 && IsFinite(tCursorB))
		Cursor /W=$browserName B $topTraceWaveNameRel tCursorB
	endif
	
	// Draw the vertical lines
	if (showToolsChecked && ( (traceAChecked && waveAExists) || (traceBChecked && waveBExists) ) )
		if (IsFinite(tBaselineLeft))
	 		BrowserViewAddCursorLineToGraph(browserName,"baselineMarkerLeft",tBaselineLeft,65535,0,0)
	 	endif
		if (IsFinite(tBaselineRight))  // true if non-nan
			BrowserViewAddCursorLineToGraph(browserName,"baselineMarkerRight",tBaselineRight,65535,0,0)
		endif
		if (IsFinite(tWindow1Left))  // true if non-nan
			BrowserViewAddCursorLineToGraph(browserName,"window1MarkerLeft",tWindow1Left,3,52428,1)
		endif
		if (IsFinite(tWindow1Right))  // true if non-nan
			BrowserViewAddCursorLineToGraph(browserName,"window1MarkerRight",tWindow1Right,3,52428,1)
		endif
		if (IsFinite(tWindow2Left))  // true if non-nan
			BrowserViewAddCursorLineToGraph(browserName,"window2MarkerLeft",tWindow2Left,0,0,65535)
		endif
		if (IsFinite(tWindow2Right))  // true if non-nan
			BrowserViewAddCursorLineToGraph(browserName,"window2MarkerRight",tWindow2Right,0,0,65535)
		endif
		if (IsFinite(tFitZero))
			BrowserViewAddCursorLineToGraph(browserName,"fitLineZero",tFitZero,26411,1,52428)
		endif
		if (IsFinite(tFitLeft))
			BrowserViewAddCursorLineToGraph(browserName,"fitLineLeft",tFitLeft,0,65535,65535)
		endif
		if (IsFinite(tFitRight))
			BrowserViewAddCursorLineToGraph(browserName,"fitLineRight",tFitRight,0,65535,65535)
		endif
	endif
	
	// Update the rejection box to reflect the reject-status of each wave 
	BrowserViewUpdateRejectCBs(browserNumber)
	
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
	String topTraceWaveNameAbs=BrowserModelGetTopWaveNameAbs(browserNumber)
	if (ItemsInList(TraceNameList(browserName,";",1))>0)
		BrowserViewRescaleAxes(browserNumber)  // Scale the axes properly, based on the model state
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
		String colorStringA=sprintf3vvv("\\K(%d,%d,%d)",colors[0][iColorA],colors[1][iColorA],colors[2][iColorA])
		Label /W=$browserName /Z left "\\F'Helvetica'\\Z12\\f01"+colorStringA+traceADisplayName+" ("+unitsA+")"
	endif
	if (waveBExists)
		String traceBDisplayName=WaveNameFromBaseAndSweep(baseNameB,iCurrentSweep)
		String unitsB=WaveUnits($traceBWaveNameAbs,-1)
		String colorStringB=sprintf3vvv("\\K(%d,%d,%d)",colors[0][iColorB],colors[1][iColorB],colors[2][iColorB])
		Label /W=$browserName /Z right "\\F'Helvetica'\\Z12\\f01"+colorStringB+traceBDisplayName+" ("+unitsB+")"
	endif
	
	// Don't want any units in the tick labels
	ModifyGraph /W=$browserName /Z tickUnit(bottom)=1
	ModifyGraph /W=$browserName /Z tickUnit(left)=1
	ModifyGraph /W=$browserName /Z tickUnit(right)=1

	// Show/hide the tools panel, as appropriate to the state	
	if (showToolsChecked) 
		if (ToolsPanelExists(browserNumber))
			BrowserViewUpdateToolsPanel(browserNumber)
		else
			BrowserViewDrawToolsPanel(browserNumber)
		endif
	else
		if (ToolsPanelExists(browserNumber))
			KillToolsPanel(browserNumber)
		endif
	endif
	
	// Update the view of the measurements
	BrowserViewUpdateMeasurements(browserNumber)
	
	// Update the visibility of the fit
	BrowserViewUpdateFitDisplay(browserNumber)

	// Update the visibility of stuff in the averaging pane
	BrowserViewUpdateAveraging(browserNumber)
	
	// Restore old data folder
	SetDataFolder savedDFName
End

Function BrowserViewUpdateRejectCBs(browserNumber)
	// Look at the wave notes for $traceAWaveName and $traceBWaveName, and update the
	// Reject checkboxes to reflect their rejection-status 
	Variable browserNumber

	// Find name of top browser, switch the DF to its DF, note the former DF name
	String savedDF=ChangeToBrowserDF(browserNumber)
	String browserName=BrowserNameFromNumber(browserNumber)
	
	// Update the traceAWaveName reject checkbox
	String traceAWaveName=BrowserModelGetAWaveNameAbs(browserNumber)
	Variable reject
	if ( WaveExists($traceAWaveName) )
		reject=NumberByKeyInWaveNote($traceAWaveName,"REJECT")
		reject = IsNan(reject)?0:reject;  // default to not reject if REJECT key missing
		CheckBox rejectACheckbox, win=$browserName, value=reject
	endif
	
	// Update the traceBWaveName reject checkbox
	String traceBWaveName=BrowserModelGetBWaveNameAbs(browserNumber)
	if ( WaveExists($traceBWaveName) )
		reject=NumberByKeyInWaveNote($traceBWaveName,"REJECT")
		reject = IsNan(reject)?0:reject;
		CheckBox rejectBCheckbox, win=$browserName, value=reject
	endif
	
	// Restore the original DF
	SetDataFolder savedDF
End

Function BrowserViewAddCursorLineToGraph(graphName,cursorWaveName,tCursor,r,g,b)
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
	String traceAWaveName=sprintf2sv("root:%s_%d", baseNameA, iCurrentSweep)
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
	String traceBWaveName=sprintf2sv("root:%s_%d", baseNameB, iCurrentSweep)
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

Function BrowserViewSetFitCoeffVis(browserNumber,visible)
	// Set the visibility of the fit coefficients
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
		if ( AreStringsEqual(fitType,"Exponential") )
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

Function BrowserViewRescaleAxes(browserNumber)
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

Function BrowserViewUpdateToolsPanel(browserNumber)
	Variable browserNumber

	String savedDFName=ChangeToBrowserDF(browserNumber)
	String toolsPanelName=ToolsPanelNameFromNumber(browserNumber)
	NVAR showToolsChecked
	if (showToolsChecked)
		BrowserViewUpdateMeasurements(browserNumber)
		BrowserViewUpdateFitDisplay(browserNumber)
		BrowserViewUpdateAveraging(browserNumber)
	endif
	SetDataFolder savedDFName
End

Function BrowserViewUpdateMeasurements(browserNumber)
	Variable browserNumber
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	String browserName=BrowserNameFromNumber(browserNumber)
	
	// Get instance vars we'll need
	NVAR showToolsChecked
	NVAR baseline, mean1, peak1, rise1
	NVAR mean2, peak2, rise2
	NVAR nCrossings1

	// Set the units strings appropriately	
	String windowName=browserName+"#ToolsPanel"
	String topWaveNameAbs=BrowserModelGetTopWaveNameAbs(browserNumber)
	String yUnitsString
	String xUnitsString
	if ( IsEmptyString(topWaveNameAbs) )
		yUnitsString=""
		xUnitsString=""
	else
		String dict=WaveInfo($topWaveNameAbs,0)		// zero required for some reason
		yUnitsString=StringByKey("DUNITS",dict)
		xUnitsString="ms"
	endif

	// white them out if they're nan
	if (showToolsChecked)
		TitleBox baselineMeanUnitsTitleBox, win=$windowName, title=yUnitsString
		TitleBox window1MeanUnitsTitleBox, win=$windowName, title=yUnitsString 
		TitleBox window1PeakUnitsTitleBox, win=$windowName, title=yUnitsString 
		TitleBox window2MeanUnitsTitleBox, win=$windowName, title=yUnitsString 
		TitleBox window2PeakUnitsTitleBox, win=$windowName, title=yUnitsString 
		TitleBox amp1UnitsTitleBox, win=$windowName, title=yUnitsString  
		TitleBox amp2UnitsTitleBox, win=$windowName, title=yUnitsString  
		TitleBox yOffsetUnitsTitleBox, win=$windowName, title=yUnitsString  
		//TitleBox yOffsetHeldValueUnitsTitleBox, win=$windowName, title=yUnitsString  
		TitleBox rise1UnitsTitleBox,win=$windowName, title=xUnitsString
		TitleBox rise2UnitsTitleBox,win=$windowName, title=xUnitsString
		TitleBox tau1UnitsTitleBox,win=$windowName, title=xUnitsString
		TitleBox tau2UnitsTitleBox,win=$windowName, title=xUnitsString
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

Function BrowserViewUpdateFitDisplay(browserNumber)
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
	String topTraceWaveNameAbs=BrowserModelGetTopWaveNameAbs(browserNumber)
	String browserName=BrowserNameFromNumber(browserNumber)
	String windowSpec=sprintf1s("WIN:%s",browserName)
	if (showToolsChecked)
		// the fit sub-panel is showing
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
					BrowserViewSetFitCoeffVis(browserNumber,1)					
				else
					// the fit sub-panel is showing, there is a trace showing, the current fit
					// coefficients are valid, but
					// the displayed trace is _not_ the one the fit applies to
					if ( ItemsInList(WaveList("yFit",";",windowSpec))>0 )
						RemoveFromGraph /W=$browserName yFit  // remove yFit if already present
					endif
					// blank the fit parameters
					BrowserViewSetFitCoeffVis(browserNumber,0)
				endif
			else
				// the fit sub-panel is showing, there is a trace showing in the browser, but 
				// the current fit coefficients are not valid
				if ( ItemsInList(WaveList("yFit",";",windowSpec))>0 )
					RemoveFromGraph /W=$browserName yFit  // remove yFit if already present
				endif
				// blank the fit parameters
				BrowserViewSetFitCoeffVis(browserNumber,0)
			endif
		else
			// the tools panel is showing, but no trace is showing in the browser
			if ( ItemsInList(WaveList("yFit",";",windowSpec))>0 )
				RemoveFromGraph /W=$browserName yFit  // remove if already present
			endif
			// blank the fit parameters
			BrowserViewSetFitCoeffVis(browserNumber,0)		
		endif
		// make sure the hold y offset SetVariable is enabled
		NVAR holdYOffset, yOffsetHeldValue
		if ( holdYOffset )
			SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,value=_NUM:yOffsetHeldValue
			SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,disable=0  // normal
		else
			//SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,disable=1  // invisible
			SetVariable yOffsetHeldValueSetVariable,win=$browserName#ToolsPanel,value=_STR:""
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

Function BrowserViewUpdateAveraging(browserNumber)
	Variable browserNumber
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)
	String toolsPanelName=ToolsPanelNameFromNumber(browserNumber)
	NVAR showToolsChecked
	if (showToolsChecked)
		// the tools panel is showing
		// Show/hide the sweeps SetVariables
		NVAR averageAllSweeps, iSweepFirstAverage, iSweepLastAverage
		if (averageAllSweeps)
			SetVariable  firstSweepSetVariable,win=$toolsPanelName,value=_STR:""
			SetVariable  lastSweepSetVariable,win=$toolsPanelName,value=_STR:""
		else
			SetVariable  firstSweepSetVariable,win=$toolsPanelName,value=_NUM:iSweepFirstAverage
			SetVariable  lastSweepSetVariable,win=$toolsPanelName,value=_NUM:iSweepLastAverage
		endif
		SetVariable  firstSweepSetVariable,win=$toolsPanelName,disable=2*averageAllSweeps
		SetVariable  lastSweepSetVariable,win=$toolsPanelName,disable=2*averageAllSweeps
		NVAR averageAllSteps, stepToAverage
		if (averageAllSteps)
			SetVariable  stepsSetVariable,win=$toolsPanelName,value=_STR:""
		else
			SetVariable  stepsSetVariable,win=$toolsPanelName,value=_NUM:stepToAverage
		endif
		
		SetVariable stepsSetVariable,win=$toolsPanelName,disable=2*averageAllSteps
	endif
	SetDataFolder savedDFName
End

