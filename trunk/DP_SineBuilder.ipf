#pragma rtGlobals=1		// Use modern global access method.

//Function LaunchSineBuilder()
//	if (wintype("SineBuilder")<1)
//		SineVarChange()
//		SineBuilder()
//	else
//		DoWindow /F SineBuilder
//	endif
//End

Function SineBuilderViewConstructor() : Graph
	SineBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_SineBuilder
	WAVE theDACWave	
	Display /W=(80,150,780,450) /K=1 /N=SineBuilderView theDACWave as "Sine Wave Builder"
	//ModifyGraph /W=SineBuilderView /Z margin(top)=36
	ModifyGraph /W=SineBuilderView /Z grid(left)=1
	Label /W=SineBuilderView /Z bottom "Time (ms)"
	Label /W=SineBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=SineBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=SineBuilderView /Z tickUnit(left)=1
	ControlBar 90
	SetVariable sine_pre,win=SineBuilderView,pos={40,12},size={140,17},proc=SineBuilderSetVariableTwiddled,title="Delay Before (ms)"
	SetVariable sine_pre,win=SineBuilderView,limits={0,1000,1},value= sineDelayBefore
	SetVariable sine_dur,win=SineBuilderView,pos={205,12},size={120,17},proc=SineBuilderSetVariableTwiddled,title="Duration (ms)"
	SetVariable sine_dur,win=SineBuilderView,format="%g",limits={0,10000,10},value= sineDuration
	SetVariable sine_post,win=SineBuilderView,pos={350,12},size={140,17},proc=SineBuilderSetVariableTwiddled,title="Delay After (ms)"
	SetVariable sine_post,win=SineBuilderView,limits={10,1000,10},value= sineDelayAfter
	SetVariable sine_amp,win=SineBuilderView,pos={128,43},size={120,17},proc=SineBuilderSetVariableTwiddled,title="Amplitude"
	SetVariable sine_amp,win=SineBuilderView,limits={-10000,10000,10},value= sineAmplitude
	SetVariable sine_freq,win=SineBuilderView,pos={286,43},size={130,17},proc=SineBuilderSetVariableTwiddled,title="Frequency (Hz)"
	SetVariable sine_freq,win=SineBuilderView,format="%g",limits={0,10000,10},value= sineFrequency
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
	
	Variable /G dt=DigitizerGetDt()		// sampling interval, ms
	
	// Parameters of sine wave stimulus
	Variable /G sineDelayBefore
	Variable /G sineDuration
	Variable /G sineDelayAfter
	Variable /G sineAmplitude
	Variable /G sineFrequency

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
	//Duplicate /O NewDAC $waveNameString
	//String filestr
	//filestr=waveNameString+".bwav"
	//Save /C $waveNameString as filestr
	//DigitizerModelChanged()
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
	//SineBuilderModelParamsChanged()
End

Function SineBuilderModelParamsChanged()
	// Updates the theDACWave wave to match the model parameters.
	// This is a _model_ method -- The view updates itself when theDACWave changes.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_SineBuilder"
	NVAR sineDelayBefore, sineDuration, sineDelayAfter, sineAmplitude, sineFrequency
	Variable totalDuration=sineDelayBefore+sineDuration+sineDelayAfter
	NVAR dt
	WAVE theDACWave
	Variable nTotal=round(totalDuration/dt)
	Redimension /N=(nTotal) theDACWave
	Setscale /P x, 0, dt, "ms", theDACWave
	Note /K theDACWave
	ReplaceStringByKeyInWaveNote(theDACWave,"WAVETYPE","sinedac")
	ReplaceStringByKeyInWaveNote(theDACWave,"TIME",time())
	ReplaceStringByKeyInWaveNote(theDACWave,"sineAmplitude",num2str(sineAmplitude))
	ReplaceStringByKeyInWaveNote(theDACWave,"sineFrequency",num2str(sineFrequency))
	ReplaceStringByKeyInWaveNote(theDACWave,"sineDelayBefore",num2str(sineDelayBefore))
	ReplaceStringByKeyInWaveNote(theDACWave,"sineDuration",num2str(sineDuration))
	ReplaceStringByKeyInWaveNote(theDACWave,"sineDelayAfter",num2str(sineDelayAfter))
	Variable jFirst=0
	Variable jLast=round(sineDelayBefore/dt)-1
	theDACWave[jFirst,jLast]=0
	jFirst=jLast+1
	jLast=jFirst+round(sineDuration/dt)-1
	theDACWave[jFirst,jLast]=sineAmplitude*sin(sineFrequency*2*PI*(x-sineDelayBefore)/1000)
	jFirst=jLast+1
	jLast=nTotal-1
	theDACWave[jFirst,jLast]=0
	//WAVE NewDAC
	//Duplicate /O theDACWave NewDAC
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

	NVAR sineDelayBefore, sineDuration, sineDelayAfter, sineAmplitude, sineFrequency

	String waveTypeString
	Variable i
	if (AreStringsEqual(waveNameString,"(Default Settings)"))
		sineDelayBefore=10
		sineDuration=50
		sineDelayAfter=10
		sineAmplitude=10
		sineFrequency=100
	else
		// Get the wave from the digitizer
		Wave exportedWave=DigitizerGetWaveByName(waveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"sinedac"))
			sineAmplitude=NumberByKeyInWaveNote(exportedWave,"sineAmplitude")
			sineFrequency=NumberByKeyInWaveNote(exportedWave,"sineFrequency")
			sineDuration=NumberByKeyInWaveNote(exportedWave,"sineDuration")
			sineDelayBefore=NumberByKeyInWaveNote(exportedWave,"sineDelayBefore")
			sineDelayAfter=NumberByKeyInWaveNote(exportedWave,"sineDelayAfter")
		else
			Abort("This is not a sine wave; choose another")
		endif
	endif
	SineBuilderModelParamsChanged()
	
	SetDataFolder savedDF	
End
