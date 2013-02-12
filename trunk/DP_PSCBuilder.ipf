#pragma rtGlobals=1		// Use modern global access method.

Function PSCBuilderViewConstructor() : Graph
	PSCBuilderModelConstructor()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_PSCBuilder
	WAVE theDACWave
	// These are all in pixels
	Variable xOffset=105
	Variable yOffset=200
	Variable width=770
	Variable height=400
	// Convert dimensions to points
	Variable pointsPerPixel=72/ScreenResolution
	Variable xOffsetInPoints=pointsPerPixel*xOffset
	Variable yOffsetInPoints=pointsPerPixel*yOffset
	Variable widthInPoints=pointsPerPixel*width
	Variable heightInPoints=pointsPerPixel*height
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) 	 /K=1 /N=PSCBuilderView theDACWave as "PSC Wave Builder"
	//ModifyGraph /W=PSCBuilderView /Z margin(top)=36
	ModifyGraph /W=PSCBuilderView /Z grid(left)=1
	Label /W=PSCBuilderView /Z bottom "Time (ms)"
	Label /W=PSCBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=PSCBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=PSCBuilderView /Z tickUnit(left)=1
	ControlBar 90
	SetVariable psc_pre,pos={42,12},size={110,17},proc=PSCBuilderSetVariableTwiddled,title="Delay (ms)"
	SetVariable psc_pre,limits={0,1000,1},value= delay
	SetVariable psc_post,pos={301,13},size={120,17},proc=PSCBuilderSetVariableTwiddled,title="Time After (ms)"
	SetVariable psc_post,limits={10,1000,10},value= timeAfter
	SetVariable psc_amp,pos={28,43},size={120,17},proc=PSCBuilderSetVariableTwiddled,title="Amplitude"
	SetVariable psc_amp,limits={-10000,10000,10},value= amplitude
	SetVariable psc_taur,pos={163,43},size={120,17},proc=PSCBuilderSetVariableTwiddled,title="Rise Tau (ms)"
	SetVariable psc_taur,format="%g",limits={0,10000,0.1},value= tauRise
	SetVariable psc_taud1,pos={320,42},size={130,17},proc=PSCBuilderSetVariableTwiddled,title="Decay Tau 1 (ms)"
	SetVariable psc_taud1,format="%g",limits={0,10000,1},value= tauDecay1
	SetVariable psc_taud2,pos={470,41},size={130,17},proc=PSCBuilderSetVariableTwiddled,title="Decay Tau 2 (ms)"
	SetVariable psc_taud2,format="%g",limits={0,10000,10},value= tauDecay2
	
	SetVariable psc_dur,pos={173,13},size={110,17},proc=PSCBuilderSetVariableTwiddled,title="Duration (ms)"
	SetVariable psc_dur,limits={0,1000,10},value= duration

	SetVariable psc_wt_td2,pos={440,12},size={140,17},proc=PSCBuilderSetVariableTwiddled,title="Weight of Decay 2"
	SetVariable psc_wt_td2,format="%2.1f",limits={0,1,0.1},value= weightDecay2
	
	Button train_save,win=PSCBuilderView,pos={670,10},size={90,20},proc=PSCBuilderSaveAsButtonPressed,title="Save As..."
	Button PSCBuilderImportButton,win=PSCBuilderView,pos={670,45},size={90,20},proc=PSCBuilderImportButtonPressed,title="Import..."
	//SetDrawLayer UserFront
	//SetDrawEnv fstyle= 1
	//DrawText -0.038,-0.06,"When done, save the wave with an extension _DAC"
	//DrawLine -0.085,-0.035,1.04,-0.035
	PSCBuilderModelParamsChanged()
	SetDataFolder savedDF
End

Function PSCBuilderModelConstructor()
	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /O /S root:DP_PSCBuilder
	
	Variable /G dt=DigitizerGetDt()		// sampling interval, ms
	
	// Parameters of post-synaptic current stimulus
	Variable /G delay
	Variable /G duration
	Variable /G timeAfter
	Variable /G amplitude
	Variable /G tauRise
	Variable /G tauDecay1
	Variable /G tauDecay2
	Variable /G weightDecay2

	// Create the wave
	Make /O theDACWave

	// Set to default params
	ImportPSCWave("(Default Settings)")
		
	// Restore the original data folder
	SetDataFolder savedDF
End

Function PSCBuilderSetVariableTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	PSCBuilderModelParamsChanged()
End

Function PSCBuilderSaveAsButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	Prompt waveNameString, "Enter wave name to save as (should end in _DAC):"
	DoPrompt "Save as...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_PSCBuilder
	WAVE theDACWave
	DigitizerAddDACWave(theDACWave,waveNameString)
	SetDataFolder savedDF
End

Function PSCBuilderImportButtonPressed(ctrlName) : ButtonControl
	String ctrlName

	String waveNameString
	String popupListString="(Default Settings);"+GetDigitizerWaveNamesEndingIn("DAC")
	Prompt waveNameString, "Select wave to import:", popup, popupListString
	DoPrompt "Import...", waveNameString
	if (V_Flag)
		return -1		// user hit Cancel
	endif
	ImportPSCWave(waveNameString)
End

Function PSCBuilderModelParamsChanged()
	// Updates the theDACWave wave to match the model parameters.
	// This is a _model_ method -- The view updates itself when theDACWave changes.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_PSCBuilder"
	NVAR delay, duration, amplitude, tauRise, tauDecay1, tauDecay2, weightDecay2, timeAfter
	Variable totalDuration=delay+duration+timeAfter
	NVAR dt
	WAVE theDACWave
	Variable nTotal=round(totalDuration/dt)
	Redimension /N=(nTotal) theDACWave
	Setscale /P x, 0, dt, "ms", theDACWave
	Note /K theDACWave
	ReplaceStringByKeyInWaveNote(theDACWave,"WAVETYPE","pscdac")
	ReplaceStringByKeyInWaveNote(theDACWave,"TIME",time())
	ReplaceStringByKeyInWaveNote(theDACWave,"amplitude",num2str(amplitude))
	ReplaceStringByKeyInWaveNote(theDACWave,"tauRise",num2str(tauRise))
	ReplaceStringByKeyInWaveNote(theDACWave,"tauDecay1",num2str(tauDecay1))
	ReplaceStringByKeyInWaveNote(theDACWave,"tauDecay2",num2str(tauDecay2))
	ReplaceStringByKeyInWaveNote(theDACWave,"weightDecay2",num2str(weightDecay2))
	ReplaceStringByKeyInWaveNote(theDACWave,"delay",num2str(delay))
	ReplaceStringByKeyInWaveNote(theDACWave,"duration",num2str(duration))
	ReplaceStringByKeyInWaveNote(theDACWave,"timeAfter",num2str(timeAfter))
	Variable nDelay=round(delay/dt)
	Variable nCentral=round(duration/dt)
	// Set the delay portion
	Variable jFirst=0
	Variable jLast=nDelay-1
	theDACWave[jFirst,jLast]=0
	// Set the main portion
	jFirst=jLast+1
	jLast=jFirst+round(duration/dt)-1
	theDACWave[jFirst,jLast]=	-exp(-(x-delay)/tauRise)+(1-weightDecay2)*exp(-(x-delay)/tauDecay1)+weightDecay2*exp(-(x-delay)/tauDecay2)
	// Set the trailing portion
	jFirst=jLast+1
	jLast=nTotal-1
	theDACWave[jFirst,jLast]=0
	// re-scale to have the proper amplitude
	Make /FREE waveAbs=abs(theDACWave)
	Wavestats /Q waveAbs
	theDACWave=(amplitude/V_max)*theDACWave		// want the peak amplitude to be amplitude
	// restore saved DF
	SetDataFolder savedDF
End

Function ImportPSCWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave in the digitizer
	// This is a model method
	String waveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_PSCBuilder"

	NVAR delay, duration, amplitude, tauRise, tauDecay1, tauDecay2, weightDecay2, timeAfter

	String waveTypeString
	Variable i
	if (AreStringsEqual(waveNameString,"(Default Settings)"))
		delay=10
		duration=50
		amplitude=10
		tauRise=0.2
		tauDecay1=2
		tauDecay2=10
		weightDecay2=0.5
		timeAfter=10
	else
		// Get the wave from the digitizer
		Wave exportedWave=DigitizerGetWaveByName(waveNameString)
		waveTypeString=StringByKeyInWaveNote(exportedWave,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"pscdac"))
			duration=NumberByKeyInWaveNote(exportedWave,"duration")
			amplitude=NumberByKeyInWaveNote(exportedWave,"amplitude")
			tauRise=NumberByKeyInWaveNote(exportedWave,"tauRise")
			tauDecay1=NumberByKeyInWaveNote(exportedWave,"tauDecay1")
			tauDecay2=NumberByKeyInWaveNote(exportedWave,"tauDecay2")
			weightDecay2=NumberByKeyInWaveNote(exportedWave,"weightDecay2")
			delay=NumberByKeyInWaveNote(exportedWave,"delay")
			timeAfter=NumberByKeyInWaveNote(exportedWave,"timeAfter")
		else
			Abort("This is not a PSC wave; choose another")
		endif
	endif
	PSCBuilderModelParamsChanged()
	
	SetDataFolder savedDF	
End

//Function /WAVE PSCFunction(dt,duration,amplitude,tauRise,tauDecay1,tauDecay2,weightDecay2)
//	Variable dt, duration, amplitude, tauRise, tauDecay1, tauDecay2, weightDecay2
//	
//	Variable n=round(duration/dt)
//	Make /FREE /N=(n) psc
//	Setscale /P x, 0, dt, "ms", psc
//	psc=(1-exp(-x/tauRise))*((1-weightDecay2)*exp(-x/tauDecay1)+weightDecay2*exp(-x/tauDecay2))
//		// THIS IS DIFFERENT THAN IN OLD DATAPRO!!
//	Wavestats /Q psc
//	psc=(amplitude/V_max)*psc		// want the peak amplitude to be amplitude
//	return psc
//End
