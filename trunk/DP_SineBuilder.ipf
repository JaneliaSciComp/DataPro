#pragma rtGlobals=1		// Use modern global access method.

Function SineBuilderViewConstructor() : Graph
	SineBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_SineBuilder
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=SineBuilderView theWave as "Sine Builder"
	ModifyGraph /W=SineBuilderView /Z grid(left)=1
	Label /W=SineBuilderView /Z bottom "Time (ms)"
	Label /W=SineBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=SineBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=SineBuilderView /Z tickUnit(left)=1
	ControlBar 80
	SetVariable sine_pre,win=SineBuilderView,pos={40,12},size={140,17},proc=SineBuilderSetVariableTwiddled,title="Delay (ms)"
	SetVariable sine_pre,win=SineBuilderView,limits={0,1000,1},value= delay
	SetVariable sine_dur,win=SineBuilderView,pos={205,12},size={120,17},proc=SineBuilderSetVariableTwiddled,title="Duration (ms)"
	SetVariable sine_dur,win=SineBuilderView,format="%g",limits={0,10000,10},value= duration
	SetVariable sine_amp,win=SineBuilderView,pos={128,43},size={120,17},proc=SineBuilderSetVariableTwiddled,title="Amplitude"
	SetVariable sine_amp,win=SineBuilderView,limits={-10000,10000,10},value= amplitude
	SetVariable sine_freq,win=SineBuilderView,pos={286,43},size={130,17},proc=SineBuilderSetVariableTwiddled,title="Frequency (Hz)"
	SetVariable sine_freq,win=SineBuilderView,format="%g",limits={0,10000,10},value= frequency
	Button train_save,win=SineBuilderView,pos={601,10},size={90,20},proc=SineBuilderSaveAsButtonPressed,title="Save As..."
	Button SineBuilderImportButton,win=SineBuilderView,pos={601,45},size={90,20},proc=SineBuilderImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function SineBuilderModelConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_SineBuilder
		
	// Parameters of sine wave stimulus
	Variable /G dt=SweeperGetDt()
	Variable /G totalDuration=SweeperGetTotalDuration()
	Variable /G delay
	Variable /G duration
	Variable /G amplitude
	Variable /G frequency

	// Create the wave
	Make /O theWave

	// Set to default params
	ImportSineWave("(Default Settings)")
		
	// Restore the original data folder
	SetDataFolder savedDF
End

Function SineBuilderSetVariableTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SineBuilderModelParamsChanged()
	SineBuilderViewModelChanged()
End

Function SineBuilderSaveAsButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as:"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_SineBuilder
	WAVE theWave
	SweeperControllerAddDACWave(theWave,waveNameString)
	SetDataFolder savedDF
End

Function SineBuilderImportButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	String popupListString="(Default Settings);"+SweeperGetFancyWaveListOfType("Sine")
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	ImportSineWave(waveNameString)
End

Function SineBuilderModelUpdateWave()
	// Updates the theWave wave to match the model parameters.
	// This is a private _model_ method -- The view updates itself when theWave changes.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_SineBuilder"
	NVAR dt, totalDuration, delay, duration, amplitude, frequency
	WAVE theWave
	resampleSineFromParamsBang(theWave,dt,totalDuration,delay,duration,amplitude,frequency)
	Note /K theWave
	ReplaceStringByKeyInWaveNote(theWave,"WAVETYPE","Sine")
	ReplaceStringByKeyInWaveNote(theWave,"TIME",time())
	ReplaceStringByKeyInWaveNote(theWave,"amplitude",num2str(amplitude))
	ReplaceStringByKeyInWaveNote(theWave,"frequency",num2str(frequency))
	ReplaceStringByKeyInWaveNote(theWave,"delay",num2str(delay))
	ReplaceStringByKeyInWaveNote(theWave,"duration",num2str(duration))
	SetDataFolder savedDF
End

Function ImportSineWave(fancyWaveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the digitizer
	// This is a model method
	String fancyWaveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_SineBuilder"

	NVAR delay, duration, amplitude, frequency

	String waveTypeString
	Variable i
	if (AreStringsEqual(fancyWaveNameString,"(Default Settings)"))
		delay=10
		duration=50
		amplitude=10
		frequency=100
	else
		// Get the wave from the digitizer
		Wave exportedWave=SweeperGetWaveByFancyName(fancyWaveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"Sine"))
			amplitude=NumberByKeyInWaveNote(exportedWave,"amplitude")
			frequency=NumberByKeyInWaveNote(exportedWave,"frequency")
			duration=NumberByKeyInWaveNote(exportedWave,"duration")
			delay=NumberByKeyInWaveNote(exportedWave,"delay")
			//sineDelayAfter=NumberByKeyInWaveNote(exportedWave,"sineDelayAfter")
		else
			Abort("This is not a sine wave; choose another")
		endif
	endif
	SineBuilderModelUpdateWave()
	
	SetDataFolder savedDF	
End

Function resampleSineBang(w,dt,totalDuration)
	Wave w
	Variable dt, totalDuration
	
	Variable delay=NumberByKeyInWaveNote(w,"delay")
	Variable duration=NumberByKeyInWaveNote(w,"duration")
	Variable amplitude=NumberByKeyInWaveNote(w,"amplitude")
	Variable frequency=NumberByKeyInWaveNote(w,"frequency")
	
	resampleSineFromParamsBang(w,dt,totalDuration,delay,duration,amplitude,frequency)
End

Function resampleSineFromParamsBang(w,dt,totalDuration,delay,duration,amplitude,frequency)
	// Compute the sine wave from the parameters
	Wave w
	Variable dt,totalDuration,delay,duration,amplitude,frequency
	
	Variable nScans=numberOfScans(dt,totalDuration)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	Variable jFirst=0
	Variable jLast=round(delay/dt)-1
	if (jFirst>=nScans)
		return 0
	endif
	w[jFirst,jLast]=0
	jFirst=jLast+1
	jLast=jFirst+round(duration/dt)-1
	if (jFirst>=nScans)
		return 0
	endif
	w[jFirst,jLast]=amplitude*sin(frequency*2*PI*(x-delay)/1000)
	jFirst=jLast+1
	jLast=nScans-1
	if (jFirst>=nScans)
		return 0
	endif
	w[jFirst,jLast]=0
End

Function SineBuilderContSweepDtOrTChngd()
	// Used to notify the Sine Builder of a change to dt or totalDuration in the Sweeper.
	SineBuilderModelSweepDtOrTChngd()
	SineBuilderViewModelChanged()
End

Function SineBuilderModelSweepDtOrTChngd()
	// Used to notify the Sine Builder model of a change to dt or totalDuration in the Sweeper.
	
	// If no Sine Builder currently exists, do nothing
	if (!DataFolderExists("root:DP_SineBuilder"))
		return 0
	endif
	
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_SineBuilder"
	
	NVAR dt, totalDuration
	
	// Get dt, totalDuration from the sweeper
	dt=SweeperGetDt()
	totalDuration=SweeperGetTotalDuration()
	// Update the	wave
	SineBuilderModelUpdateWave()
	
	// Restore the DF
	SetDataFolder savedDF		
End

Function SineBuilderViewModelChanged()
	// Nothing to do here, everything will auto-update.
End

Function SineBuilderModelParamsChanged()
	// Used to notify the model that a parameter has been changed
	// by a old-style SetVariable
	SineBuilderModelUpdateWave()
End
