#pragma rtGlobals=1		// Use modern global access method.

Function TrainBuilderViewConstructor() : Graph
	TrainBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TrainBuilder
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=TrainBuilderView theWave as "Train Builder"
	ModifyGraph /W=TrainBuilderView /Z grid(left)=1
	Label /W=TrainBuilderView /Z bottom "Time (ms)"
	Label /W=TrainBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=TrainBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=TrainBuilderView /Z tickUnit(left)=1
	ControlBar 80

	SetVariable baseLevelSV,win=TrainBuilderView,pos={15,15},size={110,15},proc=TrainBuilderSetVariableTwiddled,title="Base Level"
	SetVariable baseLevelSV,win=TrainBuilderView,limits={-10000,10000,1},value= baseLevel

	SetVariable delaySV,win=TrainBuilderView,pos={15,45},size={110,15},proc=TrainBuilderSetVariableTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=TrainBuilderView,limits={0,1000,1},value= delay

	SetVariable pulseAmplitudeSV,win=TrainBuilderView,pos={155,15},size={130,15},proc=TrainBuilderSetVariableTwiddled,title="Pulse Amplitude"
	SetVariable pulseAmplitudeSV,win=TrainBuilderView,limits={-10000,10000,10},value= pulseAmplitude

	SetVariable pulseDurationSV,win=TrainBuilderView,pos={155,45},size={140,15},proc=TrainBuilderSetVariableTwiddled,title="Pulse Duration (ms)"
	SetVariable pulseDurationSV,win=TrainBuilderView,limits={0.001,1000,1},value= pulseDuration

	SetVariable nPulsesSV,win=TrainBuilderView,pos={330,15},size={105,15},proc=TrainBuilderSetVariableTwiddled,title="# of Pulses"
	SetVariable nPulsesSV,win=TrainBuilderView,limits={1,10000,1},value= nPulses

	SetVariable pulseFrequencySV,win=TrainBuilderView,pos={330,45},size={150,15},proc=TrainBuilderSetVariableTwiddled,title="Pulse Frequency (Hz)"
	SetVariable pulseFrequencySV,win=TrainBuilderView,limits={0.001,10000,10},value= pulseFrequency
	
	Button saveAsButton,win=TrainBuilderView,pos={601,10},size={90,20},proc=TrainBuilderSaveAsButtonPressed,title="Save As..."
	Button importButton,win=TrainBuilderView,pos={601,45},size={90,20},proc=TrainBuilderImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function TrainBuilderModelConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_TrainBuilder
		
	// Parameters of sine wave stimulus
	Variable /G dt=SweeperGetDt()
	Variable /G totalDuration=SweeperGetTotalDuration()
	Variable /G nPulses
	Variable /G pulseDuration
	Variable /G baseLevel
	Variable /G pulseAmplitude
	Variable /G delay
	Variable /G pulseFrequency

	// Create the wave
	Make /O theWave

	// Set to default params
	ImportTrainWave("(Default Settings)")
		
	// Restore the original data folder
	SetDataFolder savedDF
End

Function TrainBuilderSetVariableTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	TrainBuilderModelUpdateWave()
End

Function TrainBuilderSaveAsButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as (should end in _DAC or _TTL):"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TrainBuilder
	WAVE theWave
	SweepContAddDACOrTTLWave(theWave,waveNameString)
	SetDataFolder savedDF
End

Function TrainBuilderImportButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	String popupListString="(Default Settings);"+GetSweeperWaveNamesEndingIn("DAC")+GetSweeperWaveNamesEndingIn("TTL")
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	ImportTrainWave(waveNameString)
End

Function TrainBuilderModelUpdateWave()
	// Updates the theWave wave to match the model parameters.
	// This is a private _model_ method.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_TrainBuilder"
	NVAR nPulses, pulseDuration, baseLevel, pulseAmplitude, delay, pulseFrequency
	NVAR dt		// sampling interval, ms
	NVAR totalDuration		// totalDuration, ms
	WAVE theWave
	resampleTrainFromParamsBang(theWave,dt,totalDuration,baseLevel,delay,nPulses,pulseDuration,pulseAmplitude,pulseFrequency)
	Note /K theWave
	ReplaceStringByKeyInWaveNote(theWave,"WAVETYPE","Train")
	ReplaceStringByKeyInWaveNote(theWave,"TIME",time())
	ReplaceStringByKeyInWaveNote(theWave,"nPulses",num2str(nPulses))
	ReplaceStringByKeyInWaveNote(theWave,"pulseDuration",num2str(pulseDuration))
	ReplaceStringByKeyInWaveNote(theWave,"baseLevel",num2str(baseLevel))
	ReplaceStringByKeyInWaveNote(theWave,"pulseAmplitude",num2str(pulseAmplitude))
	ReplaceStringByKeyInWaveNote(theWave,"delay",num2str(delay))
	ReplaceStringByKeyInWaveNote(theWave,"pulseFrequency",num2str(pulseFrequency))
	SetDataFolder savedDF
End

Function ImportTrainWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the digitizer
	// This is a model method
	String waveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_TrainBuilder"

	NVAR nPulses, pulseDuration, baseLevel, pulseAmplitude, delay, pulseFrequency

	String waveTypeString
	Variable i
	if (AreStringsEqual(waveNameString,"(Default Settings)"))
		nPulses=10
		pulseDuration=2		// ms
		baseLevel=0
		pulseAmplitude=10	
		delay=20			// ms
		pulseFrequency=100	// Hz
	else
		// Get the wave from the digitizer
		Wave exportedWave=SweeperGetWaveByName(waveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"Train"))
			nPulses=NumberByKeyInWaveNote(exportedWave,"nPulses")
			pulseDuration=NumberByKeyInWaveNote(exportedWave,"pulseDuration")
			baseLevel=NumberByKeyInWaveNote(exportedWave,"baseLevel")
			pulseAmplitude=NumberByKeyInWaveNote(exportedWave,"pulseAmplitude")
			delay=NumberByKeyInWaveNote(exportedWave,"delay")
			pulseFrequency=NumberByKeyInWaveNote(exportedWave,"pulseFrequency")
		else
			Abort("This is not a train wave; choose another")
		endif
	endif
	TrainBuilderModelUpdateWave()
	
	SetDataFolder savedDF	
End

Function resampleTrainBang(w,dt,totalDuration)
	Wave w
	Variable dt, totalDuration
	
	Variable baseLevel=NumberByKeyInWaveNote(w,"baseLevel")
	Variable delay=NumberByKeyInWaveNote(w,"delay")
	Variable nPulses=NumberByKeyInWaveNote(w,"nPulses")
	Variable pulseDuration=NumberByKeyInWaveNote(w,"pulseDuration")
	Variable pulseAmplitude=NumberByKeyInWaveNote(w,"pulseAmplitude")
	Variable pulseFrequency=NumberByKeyInWaveNote(w,"pulseFrequency")
	
	resampleTrainFromParamsBang(w,dt,totalDuration,baseLevel,delay,nPulses,pulseDuration,pulseAmplitude,pulseFrequency)
End

Function resampleTrainFromParamsBang(w,dt,totalDuration,baseLevel,delay,nPulses,pulseDuration,pulseAmplitude,pulseFrequency)
	// Compute the train wave from the parameters
	Wave w
	Variable dt,totalDuration,baseLevel,delay,nPulses,pulseDuration,pulseAmplitude,pulseFrequency
	
	Variable nScans=numberOfScans(dt,totalDuration)
	Redimension /N=(nScans) w
	Setscale /P x, 0, dt, "ms", w
	Variable nDelay=round(delay/dt)
	w=baseLevel		// set everything to baseLevel
	Variable nPulse=round(pulseDuration/dt)
	Variable pulsePeriod=1000/pulseFrequency		// ms
	Variable nPeriod=round(pulsePeriod/dt)
	Variable nInterPulse=nPeriod-nPulse
	Variable jOffset=nDelay
	Variable i
	for (i=0; i<nPulses; i+=1)
		if (jOffset>=nScans)
			break
		endif
		w[jOffset,jOffset+nPulse-1]=baseLevel+pulseAmplitude
		jOffset+=nPeriod;
	endfor
End

Function TrainBuilderContSweepDtOrTChngd()
	// Used to notify the Train Builder of a change to dt or totalDuration in the Sweeper.
	// This is a controller method
	TrainBuilderModlSweepDtOrTChngd()
	TrainBuilderViewModelChanged()
End

Function TrainBuilderModlSweepDtOrTChngd()
	// Used to notify the Train Builder model of a change to dt or totalDuration in the Sweeper.
	
	// If no Train Builder currently exists, do nothing
	if (!DataFolderExists("root:DP_TrainBuilder"))
		return 0
	endif
	
	// Save, set the DF
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_TrainBuilder"
	
	NVAR dt, totalDuration
	
	// Get dt, totalDuration from the sweeper
	dt=SweeperGetDt()
	totalDuration=SweeperGetTotalDuration()
	// Update the	wave
	TrainBuilderModelUpdateWave()
	
	// Restore the DF
	SetDataFolder savedDF		
End

Function TrainBuilderViewModelChanged()
	// Nothing to do here, everything will auto-update.
End

Function TrainBuilderModelParamsChanged()
	// Used to notify the model that a parameter has been changed
	// by a old-style SetVariable
	TrainBuilderModelUpdateWave()
End

