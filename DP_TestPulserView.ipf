//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserViewConstructor() : Graph
	// If the view already exists, just bring it forward
	if (GraphExists("TestPulserView"))
		DoWindow /F TestPulserView
		return 0
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// Set the data folder
	SetDataFolder root:DP_TestPulser
	
	// Declare instance variables
	NVAR ttlOutput
	NVAR doBaselineSubtraction	
	NVAR RSeal
	NVAR updateRate
	
	// Kill any pre-existing window	
	if (GraphExists("TestPulserView"))
		DoWindow /K TestPulserView
	endif
	
	// Create the graph window
	// These are all in pixels
	Variable xOffset=1060
	Variable yOffset=54
	Variable width=300*ScreenResolution/72
	Variable height=300*ScreenResolution/72
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /N=TestPulserView /K=1 as "Test Pulser"
	//ModifyPanel /W=TestPulserView fixedSize=1	// Apparently there's no way to fix the size of a graph window
	
	// Draw the top "panel"
	ControlBar /T /W=TestPulserView 80

	// Control widgets for the test pulse	
	Button startButton,win=TestPulserView,pos={18,10},size={80,20},proc=TestPulserContStartButton,title="Start"
	TitleBox proTipTitleBox,win=TestPulserView,pos={10,30+4},frame=0,title="(hit ESC key to stop)",disable=1

	SetVariable adcIndexSV,win=TestPulserView,pos={110+30,10},size={60,1},title="ADC:"
	SetVariable adcIndexSV,win=TestPulserView,limits={0,7,1},value= root:DP_TestPulser:adcIndex
	SetVariable dacIndexSV,win=TestPulserView,pos={110+30,30},size={60,1},title="DAC:",proc=TestPulserContDacIndexTwiddled
	SetVariable dacIndexSV,win=TestPulserView,limits={0,3,1},value= root:DP_TestPulser:dacIndex

	SetVariable testPulseAmplitudeSetVariable,win=TestPulserView,pos={200+30,10},size={100,1},title="Amplitude:"
	SetVariable testPulseAmplitudeSetVariable,win=TestPulserView,limits={-1000,1000,1},value= root:DP_TestPulser:amplitude
	TitleBox amplitudeTitleBox,win=TestPulserView,pos={330+4,10+2},frame=0
	SetVariable durationSV,win=TestPulserView,pos={200+30,30},size={100,1},title="Duration: "
	SetVariable durationSV,win=TestPulserView,limits={1,1000,1},value= root:DP_TestPulser:duration
	TitleBox msTitleBox,win=TestPulserView,pos={300+30+4,30+2},frame=0,title="ms"
	
	CheckBox testPulseBaseSubCheckbox,win=TestPulserView,pos={110+30,56},size={58,14},title="Base Sub"
	Checkbox testPulseBaseSubCheckbox,win=TestPulserView
	Checkbox testPulseBaseSubCheckbox,win=TestPulserView,proc=TestPulserBaseSubCheckboxUsed

	CheckBox ttlOutputCheckbox,win=TestPulserView,pos={200+30+20+6,56},size={58,14},title="TTL Output:"
	CheckBox ttlOutputCheckbox,win=TestPulserView,proc=TestPulserContTTLOutputCheckBox
	SetVariable ttlOutChannelSetVariable,win=TestPulserView,pos={280+30+20+6,56-1},size={36,1},title=" "
	SetVariable ttlOutChannelSetVariable,win=TestPulserView,limits={0,3,1},value= root:DP_TestPulser:ttlOutIndex
	SetVariable ttlOutChannelSetVariable,win=TestPulserView,disable=2-2*ttlOutput

	// Draw the bottom "panel"
	ControlBar /B /W=TestPulserView 30

	// Widgets for showing the seal resistance
	ValDisplay RSealValDisplay,win=TestPulserView,pos={236,380},size={120,17},fSize=12,format="%10.3f"
	ValDisplay RSealValDisplay,win=TestPulserView,limits={0,0,0},barmisc={0,1000}
	ValDisplay RSealValDisplay,win=TestPulserView,title="Resistance:"
	TitleBox GOhmTitleBox,win=TestPulserView,pos={236+126,380+1},frame=0,title="GOhm"
	WhiteOutIffNan("RSealValDisplay","TestPulserView",RSeal)
	
	// ValDisplay for showing the update rate
	ValDisplay updateRateValDisplay,win=TestPulserView,pos={10,380},size={120,17},fSize=12,format="%6.1f"
	ValDisplay updateRateValDisplay,win=TestPulserView,limits={0,0,0},barmisc={0,1000}
	ValDisplay updateRateValDisplay,win=TestPulserView,title="Update rate:"
	TitleBox hzTitleBox,win=TestPulserView,pos={10+126,380+1},frame=0,title="Hz"
	WhiteOutIffNan("updateRateValDisplay","TestPulserView",updateRate)
	
	// Prompt a view update
	TestPulserViewUpdate()
	
	// Restore the original DF
	SetDataFolder savedDF
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserViewUpdate()
	// If the view does no exist, nothing to do
	if (!GraphExists("TestPulserView"))
		return 0
	endif

	// Save the current DF, set it
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	NVAR doBaselineSubtraction
	NVAR ttlOutput
	NVAR ttlOutIndex
	NVAR RSeal
	NVAR updateRate
	NVAR dacIndex

	// Make sure TestPulse_ADC is plotted if it exists, but nothing is plotted if it doesn't exist
	String traceList=TraceNameList("TestPulserView",";",3)  // 3 means all traces
	Variable nTraces=ItemsInList(traceList)
	Variable waveInGraph=(nTraces>0)		// assume that if there's a wave in there, it's TestPulse_ADC	
	if (WaveExists(TestPulse_ADC))
		if (!waveInGraph)
			AppendToGraph /W=TestPulserView TestPulse_ADC
		endif
		ModifyGraph /W=TestPulserView grid(left)=1
		ModifyGraph /W=TestPulserView tickUnit(bottom)=1
		TestPulserContYLimitsToTrace()
		TestPulserViewUpdateAxisLabels()
	else
		RemoveFromGraph /Z /W=TestPulserView $"#0"
	endif

	// Controls that don't update themselves	
	String amplitudeUnits=DigitizerModelGetDACUnitsString(dacIndex)		// Get units from the Digitizer model
	TitleBox amplitudeTitleBox,win=TestPulserView,title=amplitudeUnits
	CheckBox testPulseBaseSubCheckbox,win=TestPulserView,value=doBaselineSubtraction

	Variable inUseForEpi= ( IsImagingModuleInUse() && (ttlOutIndex==EpiLightGetTTLOutputIndex() )
	CheckBox ttlOutputCheckbox,win=TestPulserView,value=ttlOutput, disable=(inUseForEpi?2:0)

	// Widgets for showing the seal resistance
	ValDisplay RSealValDisplay,win=TestPulserView,value= _NUM:RSeal
	WhiteOutIffNan("RSealValDisplay","TestPulserView",RSeal)
	
	// ValDisplay for showing the update rate
	ValDisplay updateRateValDisplay,win=TestPulserView,value= _NUM:updateRate
	WhiteOutIffNan("updateRateValDisplay","TestPulserView",updateRate)
	
	// Restore the original DF
	SetDataFolder savedDF	
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserViewEpiLightChanged()
	// Used to notify the Test Pulser view that the EpiLight has changed.
	// Currently, prompts an update of the TestPulser view.
	TestPulserViewUpdate()	
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserViewDigitizerChanged()
	// Used to notify the Test Pulser view that the Digitzer has changed.
	// Currently, prompts an update of the TestPulser view.
	TestPulserViewUpdate()	
		// This updates the amplitude units, among other things, which is all that
		// depends on the digitizer model
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserViewUpdateAxisLabels()
	// Sets the axis labels to match what's in the model.
	// private method
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	NVAR adcIndex
	
	if (WaveExists(TestPulse_ADC))	
		Label /W=TestPulserView /Z bottom "\\F'Helvetica'\\Z12\\f01Time (ms)"
		String adcModeString=DigitizerModelGetADCModeName(adcIndex)
		String adcUnitsString=DigitizerModelGetADCUnitsString(adcIndex)	
		Label /W=TestPulserView /Z left sprintf2ss("\\F'Helvetica'\\Z12\\f01%s (%s)",adcModeString,adcUnitsString)
	endif

	SetDataFolder savedDF
End

