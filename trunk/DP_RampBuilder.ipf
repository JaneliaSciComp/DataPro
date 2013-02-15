#pragma rtGlobals=1		// Use modern global access method.

Function RampBuilderViewConstructor() : Graph
	RampBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_RampBuilder
	WAVE theWave
	// These are all in pixels
	Variable xOffset=105
	Variable yOffset=200
	Variable width=705
	Variable height=400
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=RampBuilderView theWave as "Ramp Builder"
	ModifyGraph /W=RampBuilderView /Z grid(left)=1
	Label /W=RampBuilderView /Z bottom "Time (ms)"
	Label /W=RampBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=RampBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=RampBuilderView /Z tickUnit(left)=1
	ControlBar 80
	
	SetVariable preLevelSV,win=RampBuilderView,pos={25,20},size={140,15},proc=RampBuilderSetVariableTwiddled,title="Pre-Ramp Level"
	SetVariable preLevelSV,win=RampBuilderView,limits={-10000,10000,10},value= preLevel
	
	SetVariable delaySV,win=RampBuilderView,pos={25,50},size={110,15},proc=RampBuilderSetVariableTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=RampBuilderView,limits={0,1000,1},value= delay
	
	SetVariable durationSV,win=RampBuilderView,pos={190,35},size={140,15},proc=RampBuilderSetVariableTwiddled,title="Ramp Duration (ms)"
	SetVariable durationSV,win=RampBuilderView,limits={1,100000,10},value= duration
	
	SetVariable postLevel,win=RampBuilderView,pos={360,35},size={140,15},proc=RampBuilderSetVariableTwiddled,title="Post-Ramp Level"
	SetVariable postLevel,win=RampBuilderView,limits={-10000,10000,10},value= postLevel

	Button saveAsButton,win=RampBuilderView,pos={601,10},size={90,20},proc=RampBuilderSaveAsButtonPressed,title="Save As..."
	Button importButton,win=RampBuilderView,pos={601,45},size={90,20},proc=RampBuilderImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function RampBuilderModelConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_RampBuilder
		
	// Parameters of sine wave stimulus
	Variable /G dt=SweeperGetDt()
	Variable /G totalDuration=SweeperGetTotalDuration()
	Variable /G preLevel
	Variable /G delay
	Variable /G duration
	Variable /G postLevel

	// Create the wave
	Make /O theWave

	// Set to default params
	ImportRampWave("(Default Settings)")
		
	// Restore the original data folder
	SetDataFolder savedDF
End

Function RampBuilderSetVariableTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	RampBuilderModelUpdateWave()
End

Function RampBuilderSaveAsButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as (should end in _DAC):"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_RampBuilder
	WAVE theWave
	SweeperControllerAddDACWave(theWave,waveNameString)
	SetDataFolder savedDF
End

Function RampBuilderImportButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	String popupListString="(Default Settings);"+GetSweeperWaveNamesEndingIn("DAC")
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	ImportRampWave(waveNameString)
End

Function RampBuilderModelUpdateWave()
	// Updates the theWave wave to match the model parameters.
	// This is a _model_ method -- The view updates itself when theWave changes.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_RampBuilder"
	NVAR preLevel, delay, duration, postLevel
	NVAR dt		// sampling interval, ms
	NVAR totalDuration		// totalDuration, ms
	WAVE theWave
	resampleRampFromParamsBang(theWave,dt,totalDuration,preLevel,delay,duration,postLevel)
	Note /K theWave
	ReplaceStringByKeyInWaveNote(theWave,"WAVETYPE","Ramp")
	ReplaceStringByKeyInWaveNote(theWave,"TIME",time())
	ReplaceStringByKeyInWaveNote(theWave,"preLevel",num2str(preLevel))
	ReplaceStringByKeyInWaveNote(theWave,"delay",num2str(delay))
	ReplaceStringByKeyInWaveNote(theWave,"duration",num2str(duration))
	ReplaceStringByKeyInWaveNote(theWave,"postLevel",num2str(postLevel))
	SetDataFolder savedDF
End

Function ImportRampWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the digitizer
	// This is a model method
	String waveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_RampBuilder"

	NVAR preLevel, delay, duration, postLevel

	String waveTypeString
	Variable i
	if (AreStringsEqual(waveNameString,"(Default Settings)"))
		preLevel= -10
		delay=50
		duration=100
		postLevel=10
	else
		// Get the wave from the digitizer
		Wave exportedWave=SweeperGetWaveByName(waveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"Ramp"))
			preLevel=NumberByKeyInWaveNote(exportedWave,"preLevel")
			delay=NumberByKeyInWaveNote(exportedWave,"delay")
			duration=NumberByKeyInWaveNote(exportedWave,"duration")
			postLevel=NumberByKeyInWaveNote(exportedWave,"postLevel")
		else
			Abort("This is not a ramp wave; choose another")
		endif
	endif
	RampBuilderModelUpdateWave()
	
	SetDataFolder savedDF	
End

Function resampleRampBang(w,dt,totalDuration)
	Wave w
	Variable dt, totalDuration
	
	Variable preLevel=NumberByKeyInWaveNote(w,"preLevel")
	Variable delay=NumberByKeyInWaveNote(w,"delay")
	Variable duration=NumberByKeyInWaveNote(w,"duration")
	Variable postLevel=NumberByKeyInWaveNote(w,"postLevel")
	
	resampleRampFromParamsBang(w,dt,totalDuration,preLevel,delay,duration,postLevel)
End

Function resampleRampFromParamsBang(w,dt,totalDuration,preLevel,delay,duration,postLevel)
	// Compute the ramp wave from the parameters
	Wave w
	Variable dt,totalDuration,preLevel,delay,duration,postLevel
	
	Variable nScans=numberOfScans(dt,totalDuration)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	Variable nDelay=round(delay/dt)
	Variable nDuration=round(duration/dt)	
	Variable slope=(postLevel-preLevel)/duration
	w=postLevel
	w[0,nDelay-1]=preLevel
	if (nDelay>=nScans)
		return 0
	endif	
	w[nDelay,nDelay+nDuration-1]=preLevel+slope*(x-delay)
End

Function RampBuilderContSweepDtOrTChngd()
	// Used to notify the Ramp Builder of a change to dt or totalDuration in the Sweeper.
	// This is a controller method
	RampBuilderModelSweepDtOrTChngd()
	RampBuilderViewModelChanged()
End

Function RampBuilderModelSweepDtOrTChngd()
	// Used to notify the Ramp Builder model of a change to dt or totalDuration in the Sweeper.
	
	// If no Ramp Builder currently exists, do nothing
	if (!DataFolderExists("root:DP_RampBuilder"))
		return 0
	endif
	
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_RampBuilder"
	
	NVAR dt, totalDuration
	
	// Get dt, totalDuration from the sweeper
	dt=SweeperGetDt()
	totalDuration=SweeperGetTotalDuration()
	// Update the	wave
	RampBuilderModelUpdateWave()
	
	// Restore the DF
	SetDataFolder savedDF		
End

Function RampBuilderViewModelChanged()
	// Nothing to do here, everything will auto-update.
End

Function RampBuilderModelParamsChanged()
	// Used to notify the model that a parameter has been changed
	// by a old-style SetVariable
	RampBuilderModelUpdateWave()
End
