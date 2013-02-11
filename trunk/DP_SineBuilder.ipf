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
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_Digitizer
	WAVE SineDAC	
	Display /W=(80,150,780,450) /K=1 /N=SineBuilderView SineDAC as "Sine Wave Builder"
	//ModifyGraph /W=SineBuilderView /Z margin(top)=36
	ModifyGraph /W=SineBuilderView /Z grid(left)=1
	Label /W=SineBuilderView /Z bottom "Time (ms)"
	Label /W=SineBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=SineBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=SineBuilderView /Z tickUnit(left)=1
	ControlBar 90
	SetVariable sine_pre,pos={42,12},size={140,17},proc=SineBuilderSetVariableTwiddled,title="Delay Before (ms)"
	SetVariable sine_pre,limits={0,1000,1},value= sineDelayBefore
	SetVariable sine_dur,pos={200,13},size={120,17},proc=SineBuilderSetVariableTwiddled,title="Duration (ms)"
	SetVariable sine_dur,format="%g",limits={0,10000,10},value= sineDuration
	SetVariable sine_post,pos={331,13},size={140,17},proc=SineBuilderSetVariableTwiddled,title="Delay After (ms)"
	SetVariable sine_post,limits={10,1000,10},value= sineDelayAfter
	SetVariable sine_amp,pos={128,43},size={120,17},proc=SineBuilderSetVariableTwiddled,title="Amplitude"
	SetVariable sine_amp,limits={-10000,10000,10},value= sineAmplitude
	SetVariable sine_freq,pos={286,41},size={130,17},proc=SineBuilderSetVariableTwiddled,title="Frequency (Hz)"
	SetVariable sine_freq,format="%g",limits={0,10000,10},value= sineFrequency
	//SetVariable sine_sint,pos={466,12},size={120,17},proc=SineBuilderSetVariableTwiddled,title="samp. int."
	//SetVariable sine_sint,limits={0.01,1000,0.01},value= dtSine
	Button train_save,pos={601,10},size={90,20},proc=SineBuilderSaveAsButtonPressed,title="Save As..."
	PopupMenu editsine_popup0,pos={578,42},size={100,19},proc=SineBuilderImportPopupTwiddled,title="Import: "
	PopupMenu editsine_popup0,mode=1,value=#"\"(New);\"+GetPopupItems(\"DAC\")"
	//SetDrawLayer UserFront
	//SetDrawEnv fstyle= 1
	//DrawText -0.038,-0.06,"When done, save the wave with an extension _DAC"
	//DrawLine -0.085,-0.035,1.04,-0.035
	SineBuilderModelChanged()
	SetDataFolder savedDF
End

//Function SineButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	//LaunchSineBuilder()
//	RaiseOrCreateView("SineBuilderView")
//End

Function SineBuilderSetVariableTwiddled(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SineBuilderModelChanged()
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
	SetDataFolder root:DP_Digitizer
	WAVE NewDAC
	Duplicate /O NewDAC $waveNameString
	//String filestr
	//filestr=waveNameString+".bwav"
	//Save /C $waveNameString as filestr
	DigitizerModelChanged()
	SetDataFolder savedDF
End

Function SineBuilderModelChanged()
	// Updates the view to match the model.
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_Digitizer"
	NVAR sineDelayBefore, sineDuration, sineDelayAfter, sineAmplitude, sineFrequency
	Variable totalDuration=sineDelayBefore+sineDuration+sineDelayAfter
	NVAR dt
	WAVE SineDAC
	Variable nTotal=round(totalDuration/dt)
	Redimension /N=(nTotal) SineDAC
	Setscale /P x, 0, dt, "ms", SineDAC
	Note /K SineDAC
	ReplaceStringByKeyInWaveNote(SineDAC,"WAVETYPE","sinedac")
	ReplaceStringByKeyInWaveNote(SineDAC,"TIME",time())
	ReplaceStringByKeyInWaveNote(SineDAC,"sineAmplitude",num2str(sineAmplitude))
	ReplaceStringByKeyInWaveNote(SineDAC,"sineFrequency",num2str(sineFrequency))
	ReplaceStringByKeyInWaveNote(SineDAC,"sineDelayBefore",num2str(sineDelayBefore))
	ReplaceStringByKeyInWaveNote(SineDAC,"sineDuration",num2str(sineDuration))
	ReplaceStringByKeyInWaveNote(SineDAC,"sineDelayAfter",num2str(sineDelayAfter))
	Variable jFirst=0
	Variable jLast=round(sineDelayBefore/dt)-1
	SineDAC[jFirst,jLast]=0
	jFirst=jLast+1
	jLast=jFirst+round(sineDuration/dt)-1
	SineDAC[jFirst,jLast]=sineAmplitude*sin(sineFrequency*2*PI*(x-sineDelayBefore)/1000)
	jFirst=jLast+1
	jLast=nTotal-1
	SineDAC[jFirst,jLast]=0
	WAVE NewDAC
	Duplicate /O SineDAC NewDAC
	SetDataFolder savedDF
End

Function SineBuilderImportPopupTwiddled(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	//String showstr
	//sprintf showstr, "ShowSineWave(\"%s\")", popStr
	//Execute showstr
	ImportSineWave(popStr)
	SineBuilderModelChanged()
End

Function ImportSineWave(waveNameString)
	// Imports the stimulus parameters from a pre-existing wave
	// This is a model method
	String waveNameString
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_Digitizer"

	NVAR sineDelayBefore, sineDuration, sineDelayAfter, sineAmplitude, sineFrequency
	
	String waveTypeString
	Variable i
	if (AreStringsEqual(waveNameString,"(New)"))
		sineDelayBefore=10
		sineDuration=50
		sineDelayAfter=10
		sineAmplitude=10
		sineFrequency=100
	else
		waveTypeString=StringByKeyInWaveNote($waveNameString,"WAVETYPE")
		if (AreStringsEqual(waveTypeString,"sinedac"))
			sineAmplitude=NumberByKeyInWaveNote($waveNameString,"sineAmplitude")
			sineFrequency=NumberByKeyInWaveNote($waveNameString,"sineFrequency")
			sineDuration=NumberByKeyInWaveNote($waveNameString,"sineDuration")
			sineDelayBefore=NumberByKeyInWaveNote($waveNameString,"sineDelayBefore")
			sineDelayAfter=NumberByKeyInWaveNote($waveNameString,"sineDelayAfter")
			//dtFiveSegment=deltax($popstr)
		else
			Abort("This is not a sine wave; choose another")
		endif
	endif
	
	SetDataFolder savedDF	
End
