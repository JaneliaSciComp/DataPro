#pragma rtGlobals=1		// Use modern global access method.

Function SineBuilderViewConstructor() : Graph
	SineBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_SineBuilder
	WAVE theDACWave
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=SineBuilderView theDACWave as "Sine Builder"
	//ModifyGraph /W=SineBuilderView /Z margin(top)=36
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
	//SetVariable sine_post,win=SineBuilderView,pos={350,12},size={140,17},proc=SineBuilderSetVariableTwiddled,title="Delay After (ms)"
	//SetVariable sine_post,win=SineBuilderView,limits={10,1000,10},value= DelayAfter
	SetVariable sine_amp,win=SineBuilderView,pos={128,43},size={120,17},proc=SineBuilderSetVariableTwiddled,title="Amplitude"
	SetVariable sine_amp,win=SineBuilderView,limits={-10000,10000,10},value= amplitude
	SetVariable sine_freq,win=SineBuilderView,pos={286,43},size={130,17},proc=SineBuilderSetVariableTwiddled,title="Frequency (Hz)"
	SetVariable sine_freq,win=SineBuilderView,format="%g",limits={0,10000,10},value= frequency
	//SetVariable sine_sint,pos={466,12},size={120,17},proc=SineBuilderSetVariableTwiddled,title="samp. int."
	//SetVariable sine_sint,limits={0.01,1000,0.01},value= dtSine
	Button train_save,win=SineBuilderView,pos={601,10},size={90,20},proc=SineBuilderSaveAsButtonPressed,title="Save As..."
	//PopupMenu editsine_popup0,pos={578,42},size={100,19},proc=SineBuilderImportPopupTwiddled,title="Import: "
	//PopupMenu editsine_popup0,mode=1,value=#"\"(New);\"+GetDigitizerWaveNamesEndingIn(\"DAC\")"
	Button SineBuilderImportButton,win=SineBuilderView,pos={601,45},size={90,20},proc=SineBuilderImportButtonPressed,title="Import..."
	//SetDrawLayer UserFront
	//SetDrawEnv fstyle= 1
	//DrawText -0.038,-0.06,"When done, save the wave with an extension _DAC"
	//DrawLine -0.085,-0.035,1.04,-0.035
	SineBuilderModelParamsChanged()
	SetDataFolder savedDF
End

//Function SineButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	//LaunchSineBuilder()
//	RaiseOrCreateView("SineBuilderView")
//End

Function SineBuilderModelConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_SineBuilder
	
	//Variable /G dt=DigitizerGetDt()		// sampling interval, ms
	//Variable /G totalDuration=DigitizerGetTotalDuration()		// total stimulus duration, ms
	
	// Parameters of sine wave stimulus
	Variable /G delay
	Variable /G duration
	//Variable /G sineDelayAfter
	Variable /G amplitude
	Variable /G frequency

	// Create the wave
	Make /O theDACWave

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
End

Function SineBuilderSaveAsButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as (should end in _DAC):"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_SineBuilder
	WAVE theDACWave
	DigitizerAddDACWave(theDACWave,waveNameString)
	SetDataFolder savedDF
End

Function SineBuilderImportButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	String popupListString="(Default Settings);"+GetDigitizerWaveNamesEndingIn("DAC")
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	ImportSineWave(waveNameString)
End

Function SineBuilderModelParamsChanged()
	// Updates the theDACWave wave to match the model parameters.
	// This is a _model_ method -- The view updates itself when theDACWave changes.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_SineBuilder"
	NVAR delay, duration, amplitude, frequency
	Variable dt=DigitizerGetDt()		// sampling interval, ms
	Variable totalDuration=DigitizerGetTotalDuration()		// totalDuration, ms
	WAVE theDACWave
	Variable nTotal=round(totalDuration/dt)
	Redimension /N=(nTotal) theDACWave
	Setscale /P x, 0, dt, "ms", theDACWave
	Note /K theDACWave
	ReplaceStringByKeyInWaveNote(theDACWave,"WAVETYPE","sinedac")
	ReplaceStringByKeyInWaveNote(theDACWave,"TIME",time())
	ReplaceStringByKeyInWaveNote(theDACWave,"amplitude",num2str(amplitude))
	ReplaceStringByKeyInWaveNote(theDACWave,"frequency",num2str(frequency))
	ReplaceStringByKeyInWaveNote(theDACWave,"delay",num2str(delay))
	ReplaceStringByKeyInWaveNote(theDACWave,"duration",num2str(duration))
	//ReplaceStringByKeyInWaveNote(theDACWave,"sineDelayAfter",num2str(sineDelayAfter))
	Variable jFirst=0
	Variable jLast=round(delay/dt)-1
	theDACWave[jFirst,jLast]=0
	jFirst=jLast+1
	jLast=jFirst+round(duration/dt)-1
	theDACWave[jFirst,jLast]=amplitude*sin(frequency*2*PI*(x-delay)/1000)
	jFirst=jLast+1
	jLast=nTotal-1
	theDACWave[jFirst,jLast]=0
	SetDataFolder savedDF
End

//Function SineBuilderImportPopupTwiddled(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//	//String showstr
//	//sprintf showstr, "ShowSineWave(\"%s\")", popStr
//	//Execute showstr
//	ImportSineWave(popStr)
//	SineBuilderModelParamsChanged()
//End

Function ImportSineWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the digitizer
	// This is a model method
	String waveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_SineBuilder"

	NVAR delay, duration, amplitude, frequency

	String waveTypeString
	Variable i
	if (AreStringsEqual(waveNameString,"(Default Settings)"))
		delay=10
		duration=50
		//sineDelayAfter=10
		amplitude=10
		frequency=100
	else
		// Get the wave from the digitizer
		Wave exportedWave=DigitizerGetWaveByName(waveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"sinedac"))
			amplitude=NumberByKeyInWaveNote(exportedWave,"amplitude")
			frequency=NumberByKeyInWaveNote(exportedWave,"frequency")
			duration=NumberByKeyInWaveNote(exportedWave,"duration")
			delay=NumberByKeyInWaveNote(exportedWave,"delay")
			//sineDelayAfter=NumberByKeyInWaveNote(exportedWave,"sineDelayAfter")
		else
			Abort("This is not a sine wave; choose another")
		endif
	endif
	SineBuilderModelParamsChanged()
	
	SetDataFolder savedDF	
End
