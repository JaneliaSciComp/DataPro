#pragma rtGlobals=1		// Use modern global access method.

Function StepBuilderViewConstructor() : Graph
	StepBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_StepBuilder
	WAVE theWave
	// These are all in pixels
	Variable xOffset=105
	Variable yOffset=200
	Variable width=900
	Variable height=400
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=StepBuilderView theWave as "Step Builder"
	ModifyGraph /W=StepBuilderView /Z grid(left)=1
	Label /W=StepBuilderView /Z bottom "Time (ms)"
	Label /W=StepBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=StepBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=StepBuilderView /Z tickUnit(left)=1
	ControlBar 80

	Variable xShift=160
	xOffset=15		// Now this is used as an offset into the window
	SetVariable level1SV,win=StepBuilderView,pos={xOffset,15},size={100,15},proc=StepBuilderSVTwiddled,title="Level 1"
	SetVariable level1SV,win=StepBuilderView,limits={-10000,10000,10}, value= level1
	SetVariable duration1SV,win=StepBuilderView,pos={xOffset,45},size={130,15},proc=StepBuilderSVTwiddled,title="Duration 1 (ms)"
	SetVariable duration1SV,win=StepBuilderView,limits={0,10000,10}, value= duration1 

	xOffset+=xShift
	SetVariable level2SV,win=StepBuilderView,pos={xOffset,15},size={100,15},proc=StepBuilderSVTwiddled,title="Level 2"
	SetVariable level2SV,win=StepBuilderView,limits={-10000,10000,10},value= level2
	SetVariable duration2SV,win=StepBuilderView,pos={xOffset,45},size={130,15},proc=StepBuilderSVTwiddled,title="Duration 2 (ms)"
	SetVariable duration2SV,win=StepBuilderView,limits={0,10000,10},value= duration2

	xOffset+=xShift
	SetVariable level3SV,win=StepBuilderView,pos={xOffset,15},size={100,15},proc=StepBuilderSVTwiddled,title="Level 3"
	SetVariable level3SV,win=StepBuilderView,limits={-10000,10000,10},value= level3
	SetVariable duration3SV,win=StepBuilderView,pos={xOffset,45},size={130,15},proc=StepBuilderSVTwiddled,title="Duration 2 (ms)"
	SetVariable duration3SV,win=StepBuilderView,limits={0,10000,10},value= duration3

	xOffset+=xShift
	SetVariable level4SV,win=StepBuilderView,pos={xOffset,15},size={100,15},proc=StepBuilderSVTwiddled,title="Level 4"
	SetVariable level4SV,win=StepBuilderView,limits={-10000,10000,10},value= level4
	SetVariable duration4SV,win=StepBuilderView,pos={xOffset,45},size={130,15},proc=StepBuilderSVTwiddled,title="Duration 4 (ms)"
	SetVariable duration4SV,win=StepBuilderView,limits={0,10000,10},value= duration4

	xOffset+=xShift
	SetVariable level5SV,win=StepBuilderView,pos={xOffset,15},size={100,15},proc=StepBuilderSVTwiddled,title="Level 5"
	SetVariable level5SV,win=StepBuilderView,limits={-10000,10000,10},value= level5
	
	Button saveAsDACButton,win=StepBuilderView,pos={801,5},size={90,20},proc=StepBuilderSaveAsDACButtonPrsd,title="Save As DAC..."
	Button saveAsTTLButton,win=StepBuilderView,pos={801,30},size={90,20},proc=StepBuilderSaveAsTTLButtonPrsd,title="Save As TTL..."
	Button importButton,win=StepBuilderView,pos={801,55},size={90,20},proc=StepBuilderImportButtonPressed,title="Import..."

	SetDataFolder savedDF
End

Function StepBuilderModelConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_StepBuilder
		
	// Parameters of sine wave stimulus
	Variable /G dt=SweeperGetDt()
	Variable /G totalDuration=SweeperGetTotalDuration()
	Variable /G level1
	Variable /G duration1
	Variable /G level2
	Variable /G duration2
	Variable /G level3
	Variable /G duration3
	Variable /G level4
	Variable /G duration4
	Variable /G level5
	//Variable /G duration5

	// Create the wave
	Make /O theWave

	// Set to default params
	ImportStepWave("(Default Settings)")
		
	// Restore the original data folder
	SetDataFolder savedDF
End

Function StepBuilderSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	StepBuilderModelUpdateWave()
End

Function StepBuilderSaveAsDACButtonPrsd(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as (should end in _DAC):"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_StepBuilder
	WAVE theWave
	SweeperControllerAddDACWave(theWave,waveNameString)
	SetDataFolder savedDF
End

Function StepBuilderSaveAsTTLButtonPrsd(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as (should end in _TTL):"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_StepBuilder
	WAVE theWave
	SweeperControllerAddTTLWave(theWave,waveNameString)
	SetDataFolder savedDF
End

Function StepBuilderImportButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	String popupListString="(Default Settings);"+GetSweeperWaveNamesEndingIn("DAC")+GetSweeperWaveNamesEndingIn("TTL")
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	ImportStepWave(waveNameString)
End

Function StepBuilderModelUpdateWave()
	// Updates the theWave wave to match the model parameters.
	// This is a _model_ method -- The view updates itself when theWave changes.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_StepBuilder"
	
	NVAR level1
	NVAR duration1
	NVAR level2
	NVAR duration2
	NVAR level3
	NVAR duration3
	NVAR level4
	NVAR duration4
	NVAR level5
	
	NVAR dt		// sampling interval, ms
	NVAR totalDuration		// totalDuration, ms
	WAVE theWave
	resampleStepFromParamsBang(theWave,dt,totalDuration,level1,duration1,level2,duration2,level3,duration3,level4,duration4,level5)	
	Note /K theWave
	ReplaceStringByKeyInWaveNote(theWave,"WAVETYPE","Step")
	ReplaceStringByKeyInWaveNote(theWave,"TIME",time())
	ReplaceStringByKeyInWaveNote(theWave,"level1",num2str(level1))
	ReplaceStringByKeyInWaveNote(theWave,"duration1",num2str(duration1))
	ReplaceStringByKeyInWaveNote(theWave,"level2",num2str(level2))
	ReplaceStringByKeyInWaveNote(theWave,"duration2",num2str(duration2))
	ReplaceStringByKeyInWaveNote(theWave,"level3",num2str(level3))
	ReplaceStringByKeyInWaveNote(theWave,"duration3",num2str(duration3))
	ReplaceStringByKeyInWaveNote(theWave,"level4",num2str(level4))
	ReplaceStringByKeyInWaveNote(theWave,"duration4",num2str(duration4))
	ReplaceStringByKeyInWaveNote(theWave,"level5",num2str(level5))
	SetDataFolder savedDF
End

Function ImportStepWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the digitizer
	// This is a model method
	String waveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_StepBuilder"

	NVAR level1
	NVAR duration1
	NVAR level2
	NVAR duration2
	NVAR level3
	NVAR duration3
	NVAR level4
	NVAR duration4
	NVAR level5
	//NVAR duration5

	String waveTypeString
	Variable i
	if (AreStringsEqual(waveNameString,"(Default Settings)"))
		level1=0
		duration1=40
		level2=1
		duration2=40
		level3=2
		duration3=40
		level4=3
		duration4=40
		level5=0
	else
		// Get the wave from the digitizer
		Wave exportedWave=SweeperGetWaveByName(waveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"Step"))
			level1=NumberByKeyInWaveNote(exportedWave,"level1")
			duration1=NumberByKeyInWaveNote(exportedWave,"duration1")
			level2=NumberByKeyInWaveNote(exportedWave,"level2")
			duration2=NumberByKeyInWaveNote(exportedWave,"duration2")
			level3=NumberByKeyInWaveNote(exportedWave,"level3")
			duration3=NumberByKeyInWaveNote(exportedWave,"duration3")
			level4=NumberByKeyInWaveNote(exportedWave,"level4")
			duration4=NumberByKeyInWaveNote(exportedWave,"duration4")
			level5=NumberByKeyInWaveNote(exportedWave,"level5")
		else
			Abort("This is not a step wave; choose another")
		endif
	endif
	StepBuilderModelUpdateWave()
	
	SetDataFolder savedDF	
End

Function resampleStepBang(w,dt,totalDuration)
	Wave w
	Variable dt, totalDuration
	
	Variable level1=NumberByKeyInWaveNote(w,"level1")
	Variable duration1=NumberByKeyInWaveNote(w,"duration1")
	Variable level2=NumberByKeyInWaveNote(w,"level2")
	Variable duration2=NumberByKeyInWaveNote(w,"duration2")
	Variable level3=NumberByKeyInWaveNote(w,"level3")
	Variable duration3=NumberByKeyInWaveNote(w,"duration3")
	Variable level4=NumberByKeyInWaveNote(w,"level4")
	Variable duration4=NumberByKeyInWaveNote(w,"duration4")
	Variable level5=NumberByKeyInWaveNote(w,"level5")
	
	resampleStepFromParamsBang(w,dt,totalDuration,level1,duration1,level2,duration2,level3,duration3,level4,duration4,level5)
End

Function resampleStepFromParamsBang(w,dt,totalDuration,level1,duration1,level2,duration2,level3,duration3,level4,duration4,level5)
	// Compute the train wave from the parameters
	Wave w
	Variable dt,totalDuration,level1,duration1,level2,duration2,level3,duration3,level4,duration4,level5
	
	Variable nScans=numberOfScans(dt,totalDuration)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	Variable jStart,nThis
	w=level5
	jStart=0
	nThis=round(duration1/dt)
	if (jStart>=nScans)
		return 0
	endif
	w[jStart,jStart+nThis-1]=level1
	jStart+=nThis
	nThis=round(duration2/dt)
	if (jStart>=nScans)
		return 0
	endif
	w[jStart,jStart+nThis-1]=level2
	jStart+=nThis
	nThis=round(duration3/dt)
	if (jStart>=nScans)
		return 0
	endif
	w[jStart,jStart+nThis-1]=level3
	jStart+=nThis
	nThis=round(duration4/dt)
	if (jStart>=nScans)
		return 0
	endif
	w[jStart,jStart+nThis-1]=level4
End

Function StepBuilderContSweepDtOrTChngd()
	// Used to notify the Step Builder of a change to dt or totalDuration in the Sweeper.
	// This is a controller method
	StepBuilderModelSweepDtOrTChngd()
	StepBuilderViewModelChanged()
End

Function StepBuilderModelSweepDtOrTChngd()
	// Used to notify the Step Builder model of a change to dt or totalDuration in the Sweeper.
	
	// If no Step Builder currently exists, do nothing
	if (!DataFolderExists("root:DP_StepBuilder"))
		return 0
	endif
	
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_StepBuilder"
	
	NVAR dt, totalDuration
	
	// Get dt, totalDuration from the sweeper
	dt=SweeperGetDt()
	totalDuration=SweeperGetTotalDuration()
	// Update the	wave
	StepBuilderModelUpdateWave()
	
	// Restore the DF
	SetDataFolder savedDF		
End

Function StepBuilderViewModelChanged()
	// Nothing to do here, everything will auto-update.
End

Function StepBuilderModelParamsChanged()
	// Used to notify the model that a parameter has been changed
	// by a old-style SetVariable
	StepBuilderModelUpdateWave()
End
