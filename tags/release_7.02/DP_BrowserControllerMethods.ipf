#pragma rtGlobals=1		// Use modern global access method.

Function RaiseOrCreateDataProBrowser()
	String DPBrowserList=WinList("DataProBrowser*",";","WIN:1")		// 1 means graphs
	Variable nDPBrowsers=ItemsInList(DPBrowserList)
	if (nDPBrowsers==0)
		Execute "CreateDataProBrowser()"
	else
		Variable browserNumber=LargestBrowserNumber()
		String browserName=BrowserNameFromNumber(browserNumber)
		DoWindow /F $browserName
	endif
End

Function CreateDataProBrowser() : Graph
	// Figure out what the index of this DataProBrowser instance should be
	Variable browserNumber
	browserNumber=LargestBrowserNumber()+1

	// Save the current DF
	String savedDFSpec=GetDataFolder(1)	

	// Create a new data folder for this instance to store some state variables in, switch to it
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	NewDataFolder /O/S $browserDFName

	//// References for globals not in our own DF
	//SVAR baseNameANow=root:DP_DigitizerControl:adcname0
	//SVAR baseNameBNow=root:DP_DigitizerControl:adcname1

	// Create the state variables for this instance
	//Variable /G iOldSweep,
	String /G baseNameA="ad0"
	String /G baseNameB="ad1"
	Variable /G iCurrentSweep=1
	Variable /G tCursorA=nan
	Variable /G tCursorB=nan	
	Variable /G baselineA, baselineB
	//Variable /G step1, step2
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
	Variable /G yAMin=-3
	Variable /G yAMax=3
	Variable /G yBMin=-3
	Variable /G yBMax=3
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
	Variable /G lev1=0  // this is a param
	Variable /G baseline=nan, mean1=nan, peak1=nan, rise1=nan  // these are statistics
	Variable /G nCrossings1=nan
	Variable /G mean2=nan, peak2=nan, rise2=nan
	
	// Create the globals related to the fit subpanel
	Variable /G isFitValid=0  	// true iff the current fit coefficients represent the output of a valid fit
							// to waveNameAbsOfFitTrace, with the current fit parameters
	String /G waveNameAbsOfFitTrace=""
	String /G fitType="single exp" 
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
	Variable /G averageAllSweeps=1
	Variable /G iSweepFirstAverage=nan
	Variable /G iSweepLastAvg=nan
	//Variable /G avghold=nan
	//Variable /G holdtolerance=nan
	Variable /G averageAllSteps=1
	Variable /G stepToAverage=1
	Variable /G saveAveragesToDisk=0
	
	// Make waves for colors
	Make /O/N=(8,3) Colors
	Colors[][0]={0,32768,0,65535,3,29524,4369,39321,65535}
	Colors[][1]={0,32768,0,0,52428,1,4369,26208,0}
	Colors[][2]={0,32768,65535,0,1,58982,4369,1,26214}

	// Layout the window widgets
	//PauseUpdate; Silent 1		// building window...
	String browserName=BrowserNameFromNumber(browserNumber)
	String browserTitle=BrowserTitleFromNumber(browserNumber)
	Display /W=(177-30,44,757-30,548) /K=1 /N=$browserName as browserTitle
	SetWindow $browserName, hook(DPHook)=DataProBrowserHook
	ShowInfo
	
	// Draw the right "panel" and associated controls 
	//ControlBar /R /W=$browserName 200  // create right side control bar
	//NewPanel /W=(740,45,1016,337) /N=$measureWindowName /K=1 as measureWindowTitle
	//Variable rightPanelX=957-200
	//Button setbase,pos={rightPanelX+6,6},size={100,20},proc=SetBaseline,title="Set Baseline"
	//Button setwin_1,pos={rightPanelX+5,61},size={100,20},proc=SetWin,title="Set Window 1"
	//Button setwin_2,pos={rightPanelX+8,190},size={100,20},proc=SetWin,title="Set Window 2"

	// Draw the top "panel" and associated controls 
	ControlBar /T /W=$browserName 100
	
	String absVarName=AbsoluteVarName(browserDFName,"yAAutoscaling")
	CheckBox autoscaleYACheckbox,pos={106,80},size={102,14},proc=RescaleCheckProc,title="Autoscale y for trace A"
	CheckBox autoscaleYACheckbox,value= 1, variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"yBAutoscaling")
	CheckBox autoscaleYBCheckbox,pos={246,80},size={102,14},proc=RescaleCheckProc,title="Autoscale y for trace B"
	CheckBox autoscaleYBCheckbox,value= 1, variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"xAutoscaling")
	CheckBox autoscaleXCheckbox,pos={386,80},size={72,14},proc=RescaleCheckProc,title="Autoscale x"
	CheckBox autoscaleXCheckbox,value= 1, variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"iCurrentSweep")
	SetVariable setsweep,pos={11,15},size={100,18},proc=HandleSetSweepIndexControl,title="Sweep"
	SetVariable setsweep,fSize=12
	//SetVariable setsweep,limits={1,100000,1},value= $absVarName
	SetVariable setsweep,limits={1,100000,1},value=_NUM:1
	
	absVarName=AbsoluteVarName(browserDFName,"traceAChecked")
	CheckBox showTraceACheckbox,pos={125,7},size={39,14}
	CheckBox showTraceACheckbox,proc=HandleShowTraceCheckbox,title="tr.A",value= 1
	CheckBox showTraceACheckbox,variable=$absVarName
	absVarName=AbsoluteVarName(browserDFName,"traceBChecked")
	CheckBox showTraceBCheckbox,pos={125,27},size={39,14}
	CheckBox showTraceBCheckbox,proc=HandleShowTraceCheckbox,title="tr.B",value= 0
	CheckBox showTraceBCheckbox,variable=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"baseNameA")
	SetVariable bnameset_1,pos={176,7},size={80,15},proc=HandleBaseNameControl,title="name"
	SetVariable bnameset_1,value=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"baseNameB")
	SetVariable bnameset_2,pos={176,27},size={80,15},proc=HandleBaseNameControl,title="name"
	SetVariable bnameset_2,value=$absVarName
	
//	CheckBox baseSubCheckboxA,pos={262,7},size={61,14},proc=BaseSub,title="Base Sub"
//	CheckBox baseSubCheckboxA,value= 0
//	CheckBox baseSubCheckboxB,pos={262,27},size={61,14},proc=BaseSub,title="Base Sub"
//	CheckBox baseSubCheckboxB,value= 0
	
	CheckBox rejectACheckbox,pos={335,7},size={49,14},proc=HandleRejectACheckbox,title="Reject"
	CheckBox rejectACheckbox,value= 0
	CheckBox rejectBCheckbox,pos={335,27},size={49,14},proc=HandleRejectBCheckbox,title="Reject"
	CheckBox rejectBCheckbox,value= 0
	
//	absVarName=AbsoluteVarName(browserDFName,"baselineA")
//	SetVariable baseline1SetVariable,pos={400,7},size={90,15},title="Baseline",format="%3.3g"
//	SetVariable baseline1SetVariable,limits={0,0,0},value=$absVarName
//	
//	absVarName=AbsoluteVarName(browserDFName,"baselineB")
//	SetVariable baseline2SetVariable,pos={400,27},size={90,15},title="Baseline",format="%3.3g"
//	SetVariable baseline2SetVariable,limits={0,0,0},value=$absVarName
	
	ValDisplay stepAValDisplay,pos={400,7},size={70,15},title="Step",format="%3.3g"
	ValDisplay stepAValDisplay,limits={0,0,0},value=_NUM:nan
	
	ValDisplay stepBValDisplay,pos={400,27},size={70,15},title="Step",format="%3.3g"
	ValDisplay stepBValDisplay,limits={0,0,0},value=_NUM:nan
	
	SetVariable commentsSetVariable,pos={20,55},size={260,15},title="comments"
	SetVariable commentsSetVariable,proc=HandleCommentsSetVariable,value=_STR:""

	absVarName=AbsoluteVarName(browserDFName,"showToolsChecked")
	CheckBox showToolsCheckbox,pos={680,15},size={70,18},proc=ShowHideToolsPanel, value=0
	CheckBox showToolsCheckbox,title="Show Tools",variable=$absVarName
	
	//Button tools,pos={690,15},size={70,18},proc=SummonToolsPanel,title="Tools"
	
	//Button measure,pos={690,15},size={70,18},proc=SummonMeasurePanel,title="Measure"
	//Button fit,pos={690,40},size={70,18},proc=SummonFitPanel,title="Fit"
	//Button avgswps,pos={690,65},size={70,18},proc=SummonAveragePanel,title="Average"
	
	// Sync the view with the "model"
	SyncBrowserViewToDFState(browserNumber)
End

Function NewToolsPanel(browserNumber) : Panel
	Variable browserNumber // the number of the DataProBrowser we belong to
	
	// Turn off window updates until we're done drawing, turn off echoing to console
	PauseUpdate; Silent 1
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)
	
	// From the browser number, derive the measure panel window name and title
	String browserWindowName=BrowserNameFromNumber(browserNumber)
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	
	// Create the panel, draw all the controls
	Variable toolsPanelWidth=250  // pels
	Variable measureAreaHeight=280  // pels
	Variable fitAreaHeight=155+30  // pels
	Variable averageAreaHeight=110  // pels
	Variable toolsPanelHeight=measureAreaHeight+fitAreaHeight+averageAreaHeight
	NewPanel /HOST=$browserWindowName /EXT=0 /W=(0,0,toolsPanelWidth,toolsPanelHeight) /N=ToolsPanel /K=1 as "Tools"
	SetWindow $browserWindowName#ToolsPanel, hook(TPHook)=ToolsPanelHook  // register a callback function for if the panel is closed
	
	// Measure controls
	
	// Baseline controls
	SetDrawEnv linethick= 3,linefgc= (65535,0,0)
	DrawRect 6-3,6-3,6+100+3,6+20+3
	Button setbase,pos={6,6},size={100,20},proc=HandleSetBaselineButton,title="Set Baseline"
	Button clearBaselineButton,pos={6,6+28-1},size={100,18},proc=ClearBaseline,title="Clear Baseline"

	String absVarName=AbsoluteVarName(browserDFName,"baseline")
	ValDisplay baselineValDisplay,pos={139,8},size={82,17},title="Mean",format="%4.2f"
	ValDisplay baselineValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName

	// Window 1 controls
	Variable yOffset=70
	SetDrawEnv linethick= 3,linefgc= (3,52428,1)
	DrawRect 3,yOffset-3,109,yOffset+20+3
	Button setwin_1,pos={6,yOffset},size={100,20},proc=SetWindow1,title="Set Window 1"
	Button clearWindow1Button,pos={6,yOffset+28-1},size={100,18},proc=ClearWindow1,title="Clear Window 1"

	absVarName=AbsoluteVarName(browserDFName,"mean1")
	ValDisplay mean1ValDisplay,pos={138,yOffset-5},size={82,17},title="Mean",format="%4.2f"
	ValDisplay mean1ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName

	absVarName=AbsoluteVarName(browserDFName,"peak1")
	ValDisplay peak1ValDisplay,pos={140,yOffset+17},size={79,17},title="Peak",format="%4.2f"
	ValDisplay peak1ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName

	absVarName=AbsoluteVarName(browserDFName,"rise1")
	ValDisplay rise1ValDisplay,pos={115,yOffset+38},size={105,17},title="Transit Time"
	ValDisplay rise1ValDisplay,format="%4.2f",limits={0,0,0},barmisc={0,1000}
	ValDisplay rise1ValDisplay,value= #absVarName
	DrawText 224,yOffset-61+113,"ms"

	absVarName=AbsoluteVarName(browserDFName,"from1")
	SetVariable from_disp1,pos={54,yOffset-61+122},size={80,17},proc=HandleMeasurementSetVariable,title="From"
	SetVariable from_disp1,limits={0,100,10},value=$absVarName
	DrawText 140,yOffset-61+138,"%"

	absVarName=AbsoluteVarName(browserDFName,"to1")
	SetVariable to_disp1,pos={154,yOffset+61},size={66,17},proc=HandleMeasurementSetVariable,title="To"
	SetVariable to_disp1,limits={0,100,10},value=$absVarName
	DrawText 227,yOffset-61+136,"%"
	
	absVarName=AbsoluteVarName(browserDFName,"lev1")
	SetVariable levelSetVariable,pos={18,yOffset-61+145},size={80,17}
	SetVariable levelSetVariable,proc=HandleMeasurementSetVariable,title="Level"
	SetVariable levelSetVariable,limits={-100,100,10},format="%4.2f",value=$absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"nCrossings1")
	ValDisplay cross1ValDisplay,pos={110,yOffset-61+145},size={110,17},title="No. Crossings"
	ValDisplay cross1ValDisplay,limits={0,0,0},barmisc={0,1000},format="%4.0f",value= #absVarName
	
	// Window 2 controls
	SetDrawEnv linethick= 3,linefgc= (0,0,65535)
	DrawRect 3,190-3,109,190+20+3
	Button setwin_2,pos={6,190},size={100,20},proc=SetWindow2,title="Set Window 2"
	Button clearWindow2Button,pos={6,190+28-1},size={100,18},proc=ClearWindow2,title="Clear Window 2"

	absVarName=AbsoluteVarName(browserDFName,"mean2")
	ValDisplay mean2ValDisplay,pos={139,189},size={82,17},title="Mean",format="%4.2f"
	ValDisplay mean2ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"peak2")
	ValDisplay peak2ValDisplay,pos={142,211},size={79,17},title="Peak",format="%4.2f"
	ValDisplay peak2ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"rise2")
	ValDisplay rise2ValDisplay,pos={116,233},size={105,17},title="Transit Time"
	ValDisplay rise2ValDisplay,format="%4.2f",limits={0,0,0},barmisc={0,1000}
	ValDisplay rise2ValDisplay,value= #absVarName
	DrawText 227,249,"ms"
	
	absVarName=AbsoluteVarName(browserDFName,"from2")
	SetVariable from_disp2,pos={49,253},size={80,17},proc=HandleMeasurementSetVariable,title="From"
	SetVariable from_disp2,limits={0,100,10},value= $absVarName
	DrawText 228,268,"%"
	
	absVarName=AbsoluteVarName(browserDFName,"to2")
	SetVariable to_disp2,pos={155,254},size={66,17},proc=HandleMeasurementSetVariable,title="To"
	SetVariable to_disp2,limits={0,100,10},value= $absVarName
	DrawText 137,268,"%"

	// Horizontal rule
	DrawLine 8,measureAreaHeight,245,measureAreaHeight

	// Fitting controls
	yOffset=measureAreaHeight
	//SetDrawLayer UserBack
	DrawText 84,yOffset+79,"ms"
	DrawText 199,yOffset+78,"ms"
	Button fitButton,pos={123,yOffset+10},size={100,20},proc=HandleFitButton,title="Fit"

	SetDrawEnv linethick= 3,linefgc= (26411,1,52428)	// purple
	DrawRect 8-3,yOffset+36-3+2,8+100+2,yOffset+36+20+2+2
	Button set_tFitZero,pos={8,yOffset+36+2},size={100,20},proc=SetFitZero,title="Set Zero"

	SetDrawEnv linethick= 3,linefgc= (0,65535,65535)	// cyan
	DrawRect 123-3,yOffset+36-3+2,123+100+2,yOffset+36+20+2+2
	Button set_fit_range,pos={123,yOffset+36+2},size={100,20},proc=SetFitRange,title="Set Range"

	Button clearTFitZero,pos={8,yOffset+36+28},size={100,18},proc=HandleClearFitZeroButton,title="Clear Zero"

	Button clearTFitRange,pos={123,yOffset+36+28},size={100,18},proc=HandleClearFitRangeButton,title="Clear Range"

	PopupMenu fitTypePopupMenu,pos={8,yOffset+10},size={90,19}
	PopupMenu fitTypePopupMenu,mode=1,value= #"\"single exp;double exp\""	
	PopupMenu fitTypePopupMenu,proc=HandleFitTypePopupMenu
	
	absVarName=AbsoluteVarName(browserDFName,"tau1")
	ValDisplay tau1ValDisplay, pos={6,yOffset+64+28},size={75,17},title="tau 1  ",format="%4.2f"
	ValDisplay tau1ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"amp1")
	ValDisplay amp1ValDisplay,pos={5,yOffset+82+28},size={75,17},title="amp 1",format="%4.2f"
	ValDisplay amp1ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"tau2")
	ValDisplay tau2ValDisplay,pos={119,yOffset+64+28},size={75,17},title="tau 2  ",format="%4.2f"
	ValDisplay tau2ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"amp2")
	ValDisplay amp2ValDisplay,pos={119,yOffset+81+28},size={75,17},title="amp 2",format="%4.2f"
	ValDisplay amp2ValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	absVarName=AbsoluteVarName(browserDFName,"dtFitExtend")
	SetVariable dtFitExtendSetVariable,pos={7,yOffset+125+28},size={98,17},title="Show fit"
	SetVariable dtFitExtendSetVariable,limits={0,10000,10},value=$absVarName
	SetVariable dtFitExtendSetVariable,proc=HandleDtFitExtendSetVariable
	DrawText 111,yOffset+140+28,"ms beyond range"
	
	absVarName=AbsoluteVarName(browserDFName,"yOffset")
	ValDisplay yOffsetValDisplay,pos={7,yOffset+102+28},size={90,17},title="offset",format="%4.2f"
	ValDisplay yOffsetValDisplay,limits={0,0,0},barmisc={0,1000},value= #absVarName
	
	// N.B.: This one doesn't use a binding, so the callback must handle updating the model
	NVAR holdYOffset=holdYOffset
	CheckBox holdYOffsetCheckbox,pos={110,yOffset+102+28},size={50,20},title="Hold",value=holdYOffset
	CheckBox holdYOffsetCheckbox,proc=HandleHoldYOffsetCheckbox
	
	// N.B.: This one doesn't use a binding, so the callback must handle updating the model
	NVAR yOffsetHeldValue
	SetVariable yOffsetHeldValueSetVariable,pos={156,yOffset+101+28},size={70,17},title="at",format="%4.2f"
	SetVariable yOffsetHeldValueSetVariable,limits={-Inf,Inf,1},value=_NUM:yOffsetHeldValue
	SetVariable yOffsetHeldValueSetVariable,proc=HandleYOffsetHeldValueSetVar	

	// Horizontal rule
	DrawLine 8,measureAreaHeight+fitAreaHeight-3,245,measureAreaHeight+fitAreaHeight-3

	// Averaging controls
	yOffset=measureAreaHeight+fitAreaHeight

	NVAR saveAveragesToDisk
	Button avgnow,pos={20,yOffset+5},size={100,20},proc=HandleAverageButton,title="Average Sweeps"
	CheckBox saveAveragesCheckBox,pos={150,yOffset+8},size={100,20},title="Save to disk",value=saveAveragesToDisk
	CheckBox saveAveragesCheckBox,proc=HandleSaveAveragesCheckBox

	SetDrawEnv fsize= 10,textrgb= (0,0,65535)
	DrawText 48,yOffset+42,"Selected channels that meet the "
	SetDrawEnv fsize= 10,textrgb= (0,0,65535)
	DrawText 45,yOffset+55,"following criteria will be averaged."

	// Controls for which sweeps to average
	NVAR averageAllSweeps	
	TitleBox sweepsTitleBox,pos={20,yOffset+63},frame=0,title="Sweeps:"
	CheckBox allSweepsCheckBox,pos={70,yOffset+63},size={50,20},title="All",value=averageAllSweeps
	CheckBox allSweepsCheckBox,proc=HandleAllSweepsCheckbox
	
	absVarName=AbsoluteVarName(browserDFName,"iSweepFirstAverage")
	SetVariable firstSweepSetVariable,pos={110,yOffset+63},size={53,17},title=" "
	SetVariable firstSweepSetVariable,limits={1,2000,1},value=$absVarName, disable=0
	
	absVarName=AbsoluteVarName(browserDFName,"iSweepLastAvg")
	SetVariable lastSweepSetVariable,pos={170,yOffset+63},size={66,17},title="to"
	SetVariable lastSweepSetVariable,limits={1,2000,1},value=$absVarName, disable=0

//	absVarName=AbsoluteVarName(browserDFName,"avghold")
//	SetVariable avghold_disp,pos={47,yOffset+89},size={75,17},title="Hold"
//	SetVariable avghold_disp,limits={-120,120,1},value=$absVarName
//
//	absVarName=AbsoluteVarName(browserDFName,"holdtolerance")
//	SetVariable holdtol_disp,pos={135,yOffset+88},size={60,17},title="�"
//	SetVariable holdtol_disp,limits={-120,120,1},value=$absVarName
//	CheckBox hold_all,pos={212,yOffset+88},size={50,20},title="All",value=1

	// Controls for which steps to show:
	NVAR averageAllSteps
	TitleBox stepsTitleBox,pos={20,yOffset+88},frame=0,title="Steps:"
	CheckBox allStepsCheckBox,pos={70,yOffset+88},size={50,20},title="All",value=averageAllSteps
	CheckBox allStepsCheckBox,proc=HandleAllStepsCheckbox
	absVarName=AbsoluteVarName(browserDFName,"stepToAverage")
	SetVariable stepsSetVariable,pos={110,yOffset+88-1},size={85,17},title="Only:"
	SetVariable stepsSetVariable,limits={-1000,1000,10},value=$absVarName, disable=0

	// Sync the view with the "model"
	//SyncFitPanelViewToDFState(browserNumber)
	
	// Restore original data folder
	SetDataFolder savedDF	
End

Function DataProBrowserHook(s)
	// Hook function on the browser window that allows us to detect certain events and 
	// update the model and/or view appropriately
	STRUCT WMWinHookStruct &s
	
	String browserName=s.winName
	Variable browserNumber=BrowserNumberFromName(browserName)
	String browserDFName=BrowserDFNameFromNumber(browserNumber)
	
	String satelliteWindowName
	if (s.eventCode==2)					// window being killed
		//Print "Arghhh..."
		// Kill the data folder
		KillDataFolder /Z $browserDFName
	elseif (s.eventCode==7)			// cursor moved (or placed)
		String cursorName=s.cursorName
		NVAR tCursorA
		NVAR tCursorB
		if ( AreStringsEqual(cursorName,"A") )
			tCursorA=xcsr(A,browserName)
		elseif ( AreStringsEqual(cursorName,"B") )
			tCursorB=xcsr(B,browserName)		
		endif
	elseif (s.eventCode==8)			// graph modified
		// We catch this b/c we need to know if the y axis limits change
		String savedDF=ChangeToBrowserDF(browserNumber)
		NVAR yAMin
		NVAR yAMax
		NVAR yBMin
		NVAR yBMax
		NVAR xMin
		NVAR xMax
		GetAxis /W=$browserName /Q left
		if (V_flag==0)  // V_flag will be zero if the axis actually exists
			yAMin=V_min
			yAMax=V_max
		endif
		GetAxis /W=$browserName /Q right
		if (V_flag==0)  // V_flag will be zero if the axis actually exists
			yBMin=V_min
			yBMax=V_max
		endif
		GetAxis /W=$browserName /Q bottom
		if (V_flag==0)  // V_flag will be zero if the axis actually exists
			xMin=V_min
			xMax=V_max
		endif
		SetDataFolder savedDF
	endif

	return 0		// If non-zero, we handled event and Igor will ignore it.
End

Function ToolsPanelHook(s)
	// Hook function on the tool panel, allows us to catch certain events
	// and maintain UI consistency when they happen.
	STRUCT WMWinHookStruct &s
	
	String panelName=s.winName
	String browserName=RootWindowName(panelName)
	Variable browserNumber=BrowserNumberFromName(browserName)
	if (s.eventCode==2)					// window being killed
		//Print "The Tools Panel says: Arghhh..."
		// Need to uncheck the "Show Tools" checkbox
		CheckBox showToolsCheckbox, win=$browserName, value=0
	endif	
	
	return 0		// If non-zero, we handled event and Igor will ignore it.
End

Function SetICurrentSweepAndSyncView(browserNumber,iSweep)
	// Just what it says on the tin.  Called by the data acquisition loop when a sweep is acquired.
	// Set the sweep in the model
	Variable browserNumber, iSweep
	
	SetICurrentSweep(browserNumber,iSweep)
	// Sync the view
	SyncBrowserViewToDFState(browserNumber)
End

Function HandleSetSweepIndexControl(svStruct) : SetVariableControl
	// Called when the user changes the sweep number in the DPBrowser, 
	// which first changes iCurrentSweep.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	ControlInfo /W=$browserName setsweep
	Variable iSweepInView=V_Value
	Variable browserNumber=BrowserNumberFromName(browserName)
	// Set the sweep in the model
	SetICurrentSweep(browserNumber,iSweepInView)
	// Sync the view
	SyncBrowserViewToDFState(browserNumber)
End

Function HandleCommentsSetVariable(svStruct) : SetVariableControl
	// Called when the user changes the comment in the DPBrowser
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	String commentsInControl=svStruct.sval
	// Set the wave comment for the top wave to commentInControl
	String topTraceWaveNameAbs=GetTopTraceWaveNameAbs(browserNumber)
	if ( strlen(topTraceWaveNameAbs)>0 )
		ReplaceStringByKeyInWaveNote($topTraceWaveNameAbs,"COMMENTS",commentsInControl)
	endif
	// Sync the view -- necessary when no trace is selected, to clear the comment
	SyncBrowserViewToDFState(browserNumber)
End

Function HandleDtFitExtendSetVariable(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	// changing this invalidates the fit, since now the fit trace doesn't match the fit parameters
	//Printf "About to call UpdateFit() in HandleDtFitExtendSetVariable()\r"
	UpdateFit(browserNumber)  // model method
	SyncBrowserViewToDFState(browserNumber)	
End

Function HandleBaseNameControl(svStruct) : SetVariableControl
	// Called when the user changes the trace name in the control.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode!=2 && svStruct.eventCode!=3 && svStruct.eventCode!=6 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	UpdateMeasurements(browserNumber)
	//InvalidateFit(browserNumber)  // model method
	SyncBrowserViewToDFState(browserNumber)
End

Function HandleShowTraceCheckbox(cbStruct) : CheckBoxControl
	// This is called when the user checks/unchecks the "tr.A" or "tr.B" checkboxes in a
	// DPBrowser window.  Currently, this automatically changes the DF state variables.
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	UpdateMeasurements(browserNumber)
	// Shouldn't need to mess with the fit: The view should realize that the fit is for a wave
	// other than the one showing, and act accordingly.
	//String topTraceWaveNameAbs=GetTopTraceWaveNameAbs()
	//if (~AreStringsEqual(waveNameAbsOfFitTrace,topTraceWaveNameAbs)
	//	InvalidateFit(browserNumber)  // model method
	//end
	SyncBrowserViewToDFState(browserNumber)
End

Function SetTraceAChecked(browserNumber,checked)
	// Called to check/uncheck the trace A checkbox programmatically
	Variable browserNumber, checked

	String savDF=ChangeToBrowserDF(browserNumber)
	NVAR traceAChecked
	traceAChecked=checked	
	UpdateMeasurements(browserNumber)
	SyncBrowserViewToDFState(browserNumber)
	SetDataFolder savDF
End

Function SetTraceBChecked(browserNumber,checked)
	// Called to check/uncheck the trace B checkbox programmatically
	Variable browserNumber, checked

	String savDF=ChangeToBrowserDF(browserNumber)
	NVAR traceBChecked
	traceBChecked=checked	
	UpdateMeasurements(browserNumber)
	SyncBrowserViewToDFState(browserNumber)
	SetDataFolder savDF
End

Function HandleRejectACheckbox(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	String traceAWaveNameAbs=GetTraceAWaveNameAbs(browserNumber)
	ReplaceStringByKeyInWaveNote($traceAWaveNameAbs,"REJECT",num2str(cbStruct.checked))
End

Function HandleRejectBCheckbox(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	String traceBWaveNameAbs=GetTraceBWaveNameAbs(browserNumber)
	ReplaceStringByKeyInWaveNote($traceBWaveNameAbs,"REJECT",num2str(cbStruct.checked))
End

Function BaseSub(cbStruct) : CheckBoxControl
	// This is called when the user checks/unchecks one of the "Base Sub" checkboxes in a
	// DPBrowser window.
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)	
	UpdateMeasurements(browserNumber)
	//Printf "About to call UpdateFit() in BaseSub()\r"
	UpdateFit(browserNumber)  // model method
	SyncBrowserViewToDFState(browserNumber)
End

Function ShowHideToolsPanel(cbStruct) : CheckboxControl
	// This is called when the user checks/unchecks the "Show tools" checkbox in a
	// DPBrowser window.
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	SyncBrowserViewToDFState(browserNumber)
End

Function HandleSetBaselineButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);

	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Set limits of the baseline window
	NVAR tBaselineLeft=tBaselineLeft	
	tBaselineLeft=xcsr(A,browserName)  // times of left and right cursor that delineate the baseline region
	NVAR tBaselineRight=tBaselineRight
	tBaselineRight=xcsr(B,browserName)

	// Update the measurements	
	UpdateMeasurements(browserNumber)

	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function ClearBaseline(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Clear limits of the baseline window
	NVAR tBaselineLeft
	NVAR tBaselineRight
	tBaselineLeft=nan
	tBaselineRight=nan

	// Update the measurements	
	UpdateMeasurements(browserNumber)
	
	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function SetWindow1(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Get the browser number
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName)

	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Declare DF vars we need	
	NVAR tWindow1Left, tWindow1Right
	
	// Draw vertical lines to indicate the margins of the window time range
	tWindow1Left=xcsr(A,browserName)  // times of left and right cursor that delineate the window region
	tWindow1Right=xcsr(B,browserName)

	// Update the meaurements
	UpdateMeasurements(browserNumber)

	// Update the view
	SyncBrowserViewToDFState(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function ClearWindow1(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Clear limits of the window
	NVAR tWindow1Left
	NVAR tWindow1Right
	tWindow1Left=nan
	tWindow1Right=nan
	
	// Update the measurements
	UpdateMeasurements(browserNumber)
	
	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function HandleMeasurementSetVariable(svStruct) : SetVariableControl
	// This is a generic handler for several of the measurement sub-panel
	// SetVariables.  It simply updates the measurements in the model and
	// syncs the view.
	STRUCT WMSetVariableAction &svStruct	
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	Variable browserNumber=BrowserNumberFromName(svStruct.win)
	UpdateMeasurements(browserNumber)
	SyncBrowserViewToDFState(browserNumber)
End

Function SetWindow2(bStruct)
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Get the browser number
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName)

	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif

	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Set up aliases depending on nDataWindow	
	NVAR tWindow2Left, tWindow2Right
	
	// Draw vertical lines to indicate the margins of the window time range
	tWindow2Left=xcsr(A,browserName)  // times of left and right cursor that delineate the window region
	tWindow2Right=xcsr(B,browserName)

	// Update the measurements
	UpdateMeasurements(browserNumber)

	// Update the view
	SyncBrowserViewToDFState(browserNumber)

	// Restore the orignal DF
	SetDataFolder savedDF	
End


Function ClearWindow2(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	String measurePanelName=bStruct.win;
	Variable browserNumber=BrowserNumberFromName(measurePanelName);
	
	// Save the current data folder, change to this browser's DF
	String savedDF=ChangeToBrowserDF(browserNumber)

	// Clear limits of the window
	NVAR tWindow2Left
	NVAR tWindow2Right
	tWindow2Left=nan
	tWindow2Right=nan
	
	// Update the measurements
	UpdateMeasurements(browserNumber)
	
	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore the orignal DF
	SetDataFolder savedDF	
End

Function SetFitZero(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!IsCursorASet(browserName))
		return nan
	endif
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Set the model state variable
	NVAR tFitZero=tFitZero
	tFitZero=xcsr(A,browserName)
	//SVAR traceAWaveName=traceAWaveName  // actually the name of a wave, not the wave itself
	//AddCursorLineToGraph(browserName,"fitLineZero",tFitZero)
	//ModifyGraph rgb(fitLineZero)=(26411,1,52428)

	// Update the fit
	//Printf "About to call UpdateFit() in SetFitZero()\r"
	UpdateFit(browserNumber)
	
	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function HandleClearFitZeroButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Clear the model state variable
	NVAR tFitZero
	tFitZero=nan

	// Update the fit
	UpdateFit(browserNumber)
	
	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function SetFitRange(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Check that the cursors are actually set, otherwise return
	String browserName=BrowserNameFromNumber(browserNumber)
	if (!AreCursorsAAndBSet(browserName))
		return nan
	endif
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Set internal "cursors"
	NVAR tFitLeft=tFitLeft
	tFitLeft=xcsr(A,browserName)
	NVAR tFitRight=tFitRight
	tFitRight=xcsr(B,browserName)

	// Update the fit
	//Printf "About to call UpdateFit() in SetFitRange()\r"
	UpdateFit(browserNumber)

	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function HandleClearFitRangeButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Set internal "cursors"
	NVAR tFitLeft
	NVAR tFitRight
	tFitLeft=nan
	tFitRight=nan

	// Update the fit
	UpdateFit(browserNumber)

	// Update the view
	SyncBrowserViewToDFState(browserNumber)
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function HandleFitButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);
	
	// Update the fit trace and fit parameters in the model
	//Printf "About to call UpdateFit() in HandleFitButton()\r"
	UpdateFit(browserNumber)
	
	// Sync the view to the model
	SyncBrowserViewToDFState(browserNumber)
End

Function HandleFitTypePopupMenu(pStruct) : PopupMenuControl
	STRUCT WMPopupAction &pStruct
	
	// Check that this is really a button-up on the menu
	if (pStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(pStruct.win);
	
	// Update the fit trace and fit parameters in the model
	SVAR fitType
	if (pStruct.popNum==1)
		fitType="single exp";
	else
		fitType="double exp";
	endif

	// Update the fit coeffs
	//Printf "About to call UpdateFit() in HandleFitTypePopupMenu()\r"
	UpdateFit(browserNumber)
	
	// Sync the view to the model
	SyncBrowserViewToDFState(browserNumber)
End

Function HandleHoldYOffsetCheckbox(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct	

	// If event is other than mouse up within control, do nothing
	if (cbStruct.eventCode!=2)
		return 0
	endif

	// Find name of browser, switch the DF to its DF, note the former DF name
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Get the old value
	NVAR holdYOffset  // boolean, whether or not hold the y offset at the given value
	Variable holdYOffsetOld=holdYOffset

	// Update the model variable
	holdYOffset=cbStruct.checked
	
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
				//Printf "About to call UpdateFit() in HandleHoldYOffsetCheckbox() #1\r"
				UpdateFit(browserNumber)
			endif
		else
			// fit is already invalid
			//Printf "About to call UpdateFit() in HandleHoldYOffsetCheckbox() #2\r"
			UpdateFit(browserNumber)
		endif			
	else
		// holdYOffset just turned false -- now the yOffset parameter is free, so a previously-valid fit 
		// is now invalid
		yOffsetHeldValue=nan  // when made visible again, want it to get current yOffset
		//Printf "About to call UpdateFit() in HandleHoldYOffsetCheckbox() #3\r"		
		UpdateFit(browserNumber)
	endif

	// Sync the the view with the current state
	SyncBrowserViewToDFState(browserNumber)

	// Restore old data folder
	SetDataFolder savedDFName
End

Function HandleYOffsetHeldValueSetVar(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct	
	//Printf "eventcode: %d\r", svStruct.eventCode
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif	
	String browserName=svStruct.win
	Variable browserNumber=BrowserNumberFromName(browserName)
	String savedDFName=ChangeToBrowserDF(browserNumber)
	NVAR yOffsetHeldValue
	yOffsetHeldValue=svStruct.dval  // set the model variable to the value set in the view
	// changing this invalidates the fit, since now the fit trace (if there is one) doesn't match the fit parameters
	//Printf "About to call UpdateFit() in HandleYOffsetHeldValueSetVar()\r"		
	UpdateFit(browserNumber)  // model method
	SyncBrowserViewToDFState(browserNumber)	
	SetDataFolder savedDFName
End

//Function SweepIndexChangedInView(browserNumber,sweepIndexInView)
//	// Tell the controller that the sweep index has been changed in the view.
//	Variable browserNumber, sweepIndexInView
//
//	// Change to the right DF
//	String savedDFName=ChangeToBrowserDF(browserNumber)
//	
//	// Set the sweep in the "model"
//	SetICurrentSweep(browserNumber,sweepIndexInView)
//	
//	// Restore the original DF
//	SetDataFolder savedDFName	
//End

Function RescaleCheckProc(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	SyncBrowserViewToDFState(browserNumber)
	//SyncDFAxesLimitsWithGraph(browserNumber)
	//RescaleAxes(browserNumber)
End

Function HandleAllSweepsCheckbox(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)	
	NVAR averageAllSweeps
	averageAllSweeps=cbStruct.checked
	NVAR iSweepFirstAverage,iSweepLastAvg
	if ( averageAllSweeps )
		iSweepFirstAverage=nan
		iSweepLastAvg=nan
	else
		SVAR baseNameA, baseNameB
		Variable nSweeps1=NTracesFromBaseName(baseNameA)
		Variable nSweeps2=NTracesFromBaseName(baseNameB)
		Variable nSweeps=max(nSweeps1,nSweeps2)
		iSweepFirstAverage=1
		iSweepLastAvg=nSweeps
	endif
	SyncBrowserViewToDFState(browserNumber)
	SetDataFolder savedDFName
End

Function HandleAllStepsCheckbox(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)	
	NVAR averageAllSteps
	averageAllSteps=cbStruct.checked
	SyncBrowserViewToDFState(browserNumber)
	SetDataFolder savedDFName
End

Function HandleSaveAveragesCheckBox(cbStruct) : CheckBoxControl
	STRUCT WMCheckboxAction &cbStruct
	if (cbStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif	
	Variable browserNumber=BrowserNumberFromName(cbStruct.win)
	String savedDFName=ChangeToBrowserDF(browserNumber)	
	NVAR saveAveragesToDisk
	saveAveragesToDisk=cbStruct.checked
	SyncBrowserViewToDFState(browserNumber)
	SetDataFolder savedDFName
End


Function HandleAverageButton(bStruct) : ButtonControl
	STRUCT WMButtonAction &bStruct
	
	// Check that this is really a button-up on the button
	if (bStruct.eventCode!=2)
		return 0							// we only handle mouse up in control
	endif

	// Don't echo to transcript	
	Silent 1
	
	// Get the browser number from the bStruct
	Variable browserNumber=BrowserNumberFromName(bStruct.win);		
	//String browserName=BrowserNameFromNumber(browserNumber)
	
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
			nSweeps=nan  // doesn't matter b/c no averaging will happen
		endif
	endif
	
	// determine which sweeps we're going to average, of those present
	NVAR averageAllSweeps
	NVAR iSweepLastAvg
	NVAR iSweepFirstAverage
	Variable iFrom, iTo
	if (averageAllSweeps)
		iFrom=1
		iTo=nSweeps
	else
		iFrom=iSweepFirstAverage
		iTo=iSweepLastAvg
	endif
	
	// Figure the dest wave name
	NVAR acqNextSweepIndex=root:DP_DigitizerControl:iSweep
	Variable destSweepIndex=acqNextSweepIndex
	
	// Do the average(s)
	NVAR averageAllSteps
	Variable filterOnHold=0	// there used to by UI to filter on the holding level
	Variable holdCenter=nan
	Variable holdTol=nan
	Variable filterOnStep=!averageAllSteps
	NVAR stepToAverage
	if (traceAChecked)
		ComputeAverageWaves(browserNumber,destSweepIndex,baseNameA,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
	endif
	if (traceBChecked)
		ComputeAverageWaves(browserNumber,destSweepIndex,baseNameB,iFrom,iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
	endif			

	// increment the next sweep index for acquisition	
	if (traceAChecked || traceBChecked)
		acqNextSweepIndex=destSweepIndex+1	
	endif
	
	// Restore original DF
	SetDataFolder savedDFName
End

Function ComputeAverageWaves(browserNumber,destSweepIndex,waveBaseName,iFrom, iTo,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
	Variable browserNumber
	Variable destSweepIndex
	String waveBaseName
	Variable iFrom, iTo
	Variable filterOnHold	// boolean
	Variable holdCenter, holdTol
	Variable filterOnStep	// boolean
	Variable stepToAverage

	// Save the current DF, set the data folder to the appropriate one for this DataProBrowser instance
	String savedDFName=ChangeToBrowserDF(browserNumber)

	// Figure the destination wave name
	String destWaveName = sprintf2sd("root:%s%d", waveBaseName, destSweepIndex)
	
	// Loop over waves to be averaged, forming the sum and counting the number of waves
	Variable i, nWavesSummedSoFar=0
	Variable include
	for (i=iFrom; i<=iTo; i+=1)
		String thisWaveName=sprintf2sd("root:%s%d", waveBaseName, i)
		WAVE thisWave=$thisWaveName
		include=IncludeInAverage(thisWaveName,filterOnHold,holdCenter,holdTol,filterOnStep,stepToAverage)
		if (include)
			if (nWavesSummedSoFar==0)
				Duplicate /O thisWave $destWaveName
				WAVE outWave=$destWaveName
				Note /K outWave
				ReplaceStringByKeyInWaveNote(outWave,"WAVETYPE","average")
				ReplaceStringByKeyInWaveNote(outWave,"TIME",time())
				//ReplaceStringByKeyInWaveNote(outWave,"DONTAVG","1")  // redundant b/c already marked as an average
				ReplaceStringByKeyInWaveNote(outWave,"STEP",num2str(stepToAverage))
				outwave = 0
			endif
			outWave += thisWave
			nWavesSummedSoFar += 1
		endif
	endfor
	Variable nWavesToAvg=nWavesSummedSoFar
	
	// Actually compute the average from the sum
	String waveBaseNameShort=RemoveEnding(waveBaseName,"_")
	if (nWavesToAvg>0)
		outWave /= nWavesToAvg
	else
		String message=sprintf1s("%s: No waves met your criteria to be averaged.", waveBaseNameShort)
		Abort message
	endif
	Printf "%s: %d waves were averaged and stored in %s\r", waveBaseNameShort, nWavesToAvg, destWaveName
	
	// Save the average wave to disk, if called for
	NVAR saveAveragesToDisk
	if (saveAveragesToDisk)
		String outFileName=sprintf1s("%s.avg", destWaveName)
		Save /C/I outWave as outFileName
		Printf "%s: Average saved to disk as %s\r", waveBaseNameShort, outFileName
	else
		//Printf "%s: Average not saved to disk\r", waveBaseNameShort
	endif
	
	// Restore original DF
	SetDataFolder savedDFName	
End