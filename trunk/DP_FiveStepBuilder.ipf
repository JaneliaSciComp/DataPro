#pragma rtGlobals=1		// Use modern global access method.

Function FiveStepBuilderViewConstructor() : Graph
	FiveStepBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FiveStepBuilder
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=FiveStepBuilderView theWave as "Five Step Builder"
	ModifyGraph /W=FiveStepBuilderView /Z grid(left)=1
	Label /W=FiveStepBuilderView /Z bottom "Time (ms)"
	Label /W=FiveStepBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=FiveStepBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=FiveStepBuilderView /Z tickUnit(left)=1
	ControlBar 80

	Variable xShift=160
	xOffset=15		// Now this is used as an offset into the window
	SetVariable level1SV,win=FiveStepBuilderView,pos={xOffset,15},size={100,15},proc=FiveStepBuilderSVTwiddled,title="Level 1"
	SetVariable level1SV,win=FiveStepBuilderView,limits={-10000,10000,10}, value= level1
	SetVariable duration1SV,win=FiveStepBuilderView,pos={xOffset,45},size={130,15},proc=FiveStepBuilderSVTwiddled,title="Duration 1 (ms)"
	SetVariable duration1SV,win=FiveStepBuilderView,limits={0,10000,10}, value= duration1 

	xOffset+=xShift
	SetVariable level2SV,win=FiveStepBuilderView,pos={xOffset,15},size={100,15},proc=FiveStepBuilderSVTwiddled,title="Level 2"
	SetVariable level2SV,win=FiveStepBuilderView,limits={-10000,10000,10},value= level2
	SetVariable duration2SV,win=FiveStepBuilderView,pos={xOffset,45},size={130,15},proc=FiveStepBuilderSVTwiddled,title="Duration 2 (ms)"
	SetVariable duration2SV,win=FiveStepBuilderView,limits={0,10000,10},value= duration2

	xOffset+=xShift
	SetVariable level3SV,win=FiveStepBuilderView,pos={xOffset,15},size={100,15},proc=FiveStepBuilderSVTwiddled,title="Level 3"
	SetVariable level3SV,win=FiveStepBuilderView,limits={-10000,10000,10},value= level3
	SetVariable duration3SV,win=FiveStepBuilderView,pos={xOffset,45},size={130,15},proc=FiveStepBuilderSVTwiddled,title="Duration 2 (ms)"
	SetVariable duration3SV,win=FiveStepBuilderView,limits={0,10000,10},value= duration3

	xOffset+=xShift
	SetVariable level4SV,win=FiveStepBuilderView,pos={xOffset,15},size={100,15},proc=FiveStepBuilderSVTwiddled,title="Level 4"
	SetVariable level4SV,win=FiveStepBuilderView,limits={-10000,10000,10},value= level4
	SetVariable duration4SV,win=FiveStepBuilderView,pos={xOffset,45},size={130,15},proc=FiveStepBuilderSVTwiddled,title="Duration 4 (ms)"
	SetVariable duration4SV,win=FiveStepBuilderView,limits={0,10000,10},value= duration4

	xOffset+=xShift
	SetVariable level5SV,win=FiveStepBuilderView,pos={xOffset,15},size={100,15},proc=FiveStepBuilderSVTwiddled,title="Level 5"
	SetVariable level5SV,win=FiveStepBuilderView,limits={-10000,10000,10},value= level5
	//SetVariable duration5SV,win=FiveStepBuilderView,pos={xOffset,45},size={100,15},proc=FiveStepBuilderSVTwiddled,title="Duration 5 (ms)"
	//SetVariable duration5SV,win=FiveStepBuilderView,limits={0,10000,10},value= duration5
	
	Button saveAsButton,win=FiveStepBuilderView,pos={width-100,10},size={90,20},proc=FSBSaveAsButtonPressed,title="Save As..."
	Button importButton,win=FiveStepBuilderView,pos={width-100,45},size={90,20},proc=FSBImportButtonPressed,title="Import..."
	FSBModelParamsChanged()
	SetDataFolder savedDF
End

Function FiveStepBuilderModelConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_FiveStepBuilder
		
	// Parameters of sine wave stimulus
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
	ImportFiveStepWave("(Default Settings)")
		
	// Restore the original data folder
	SetDataFolder savedDF
End

Function FiveStepBuilderSVTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	FSBModelParamsChanged()
End

Function FSBSaveAsButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as (should end in _DAC or _TTL):"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_FiveStepBuilder
	WAVE theWave
	DigitizerAddDACOrTTLWave(theWave,waveNameString)
	SetDataFolder savedDF
End

Function FSBImportButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	String popupListString="(Default Settings);"+GetDigitizerWaveNamesEndingIn("DAC")+GetDigitizerWaveNamesEndingIn("TTL")
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	ImportFiveStepWave(waveNameString)
End

Function FSBModelParamsChanged()
	// Updates the theWave wave to match the model parameters.
	// This is a _model_ method -- The view updates itself when theWave changes.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_FiveStepBuilder"
	
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
	
	Variable dt=DigitizerGetDt()		// sampling interval, ms
	Variable totalDuration=DigitizerGetTotalDuration()		// totalDuration, ms
	WAVE theWave
	Variable nTotal=round(totalDuration/dt)
	Redimension /N=(nTotal) theWave
	Setscale /P x, 0, dt, "ms", theWave
	Note /K theWave
	ReplaceStringByKeyInWaveNote(theWave,"WAVETYPE","fivestepdac")
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
	// Set the elements of theWave
	Variable jStart,nThis
	theWave=level5
	jStart=0
	nThis=round(duration1/dt)
	theWave[jStart,jStart+nThis-1]=level1
	jStart+=nThis
	nThis=round(duration2/dt)
	theWave[jStart,jStart+nThis-1]=level2
	jStart+=nThis
	nThis=round(duration3/dt)
	theWave[jStart,jStart+nThis-1]=level3
	jStart+=nThis
	nThis=round(duration4/dt)
	theWave[jStart,jStart+nThis-1]=level4
	SetDataFolder savedDF
End

Function ImportFiveStepWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the digitizer
	// This is a model method
	String waveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_FiveStepBuilder"

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
		Wave exportedWave=DigitizerGetWaveByName(waveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"fivestepdac"))
			level1=NumberByKeyInWaveNote(exportedWave,"level1")
			duration1=NumberByKeyInWaveNote(exportedWave,"duration1")
			level1=NumberByKeyInWaveNote(exportedWave,"level2")
			duration1=NumberByKeyInWaveNote(exportedWave,"duration2")
			level1=NumberByKeyInWaveNote(exportedWave,"level3")
			duration1=NumberByKeyInWaveNote(exportedWave,"duration3")
			level1=NumberByKeyInWaveNote(exportedWave,"level4")
			duration1=NumberByKeyInWaveNote(exportedWave,"duration4")
			level1=NumberByKeyInWaveNote(exportedWave,"level5")
		else
			Abort("This is not a five-step wave; choose another")
		endif
	endif
	FSBModelParamsChanged()
	
	SetDataFolder savedDF	
End
