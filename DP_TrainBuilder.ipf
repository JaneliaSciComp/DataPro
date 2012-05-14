#pragma rtGlobals=1		// Use modern global access method.

Function TrainBuilderViewConstructor() : Graph
	//BuilderModelConstructor("Train")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TrainBuilder
	WAVE theWave
	WAVE parameters
	Variable baseLevel=parameters[0]
	Variable delay=parameters[1]
	Variable nPulses=parameters[2]
	Variable pulseDuration=parameters[3]			
	Variable pulseAmplitude=parameters[4]			
	Variable pulseFrequency=parameters[5]				
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

	SetVariable baseLevelSV,win=TrainBuilderView,pos={15,15},size={110,15},proc=BuilderContSVTwiddled,title="Base Level"
	SetVariable baseLevelSV,win=TrainBuilderView,limits={-10000,10000,1},value= _NUM:baseLevel

	SetVariable delaySV,win=TrainBuilderView,pos={15,45},size={110,15},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=TrainBuilderView,limits={0,200000,1},value= _NUM:delay

	SetVariable pulseAmplitudeSV,win=TrainBuilderView,pos={155,15},size={130,15},proc=BuilderContSVTwiddled,title="Pulse Amplitude"
	SetVariable pulseAmplitudeSV,win=TrainBuilderView,limits={-10000,10000,10},value= _NUM:pulseAmplitude

	SetVariable pulseDurationSV,win=TrainBuilderView,pos={155,45},size={140,15},proc=BuilderContSVTwiddled,title="Pulse Duration (ms)"
	SetVariable pulseDurationSV,win=TrainBuilderView,limits={0.001,inf,1},value= _NUM:pulseDuration

	SetVariable nPulsesSV,win=TrainBuilderView,pos={330,15},size={105,15},proc=BuilderContSVTwiddled,title="# of Pulses"
	SetVariable nPulsesSV,win=TrainBuilderView,limits={1,inf,1},value= _NUM:nPulses

	SetVariable pulseFrequencySV,win=TrainBuilderView,pos={330,45},size={150,15},proc=BuilderContSVTwiddled,title="Pulse Frequency (Hz)"
	SetVariable pulseFrequencySV,win=TrainBuilderView,limits={0.001,inf,10},value= _NUM:pulseFrequency
	
	Button saveAsDACButton,win=TrainBuilderView,pos={601,5},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As DAC..."
	Button saveAsTTLButton,win=TrainBuilderView,pos={601,30},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As TTL..."
	Button importButton,win=TrainBuilderView,pos={601,55},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function TrainBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=6
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="baseLevel"
	parameterNames[1]="delay"
	parameterNames[2]="nPulses"
	parameterNames[3]="pulseDuration"
	parameterNames[4]="pulseAmplitude"
	parameterNames[5]="pulseFrequency"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=0
	parametersDefault[1]=20		// ms
	parametersDefault[2]=10
	parametersDefault[3]=2		// ms
	parametersDefault[4]=10
	parametersDefault[5]=100		// Hz
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
End

Function fillTrainFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable baseLevel=parameters[0]
	Variable delay=parameters[1]
	Variable nPulses=parameters[2]
	Variable pulseDuration=parameters[3]			
	Variable pulseAmplitude=parameters[4]			
	Variable pulseFrequency=parameters[5]				

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

