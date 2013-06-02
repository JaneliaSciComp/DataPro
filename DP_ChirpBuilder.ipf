#pragma rtGlobals=1		// Use modern global access method.

Function ChirpBuilderViewConstructor() : Graph
	//BuilderModelConstructor("Chirp")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_ChirpBuilder
	WAVE theWave
	WAVE parameters
	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable initialFrequency=parameters[3]	
	Variable finalFrequency=parameters[4]	
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=ChirpBuilderView theWave as "Chirp Builder"
	ModifyGraph /W=ChirpBuilderView /Z grid(left)=1
	Label /W=ChirpBuilderView /Z bottom "Time (ms)"
	Label /W=ChirpBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=ChirpBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=ChirpBuilderView /Z tickUnit(left)=1
	ControlBar 80
	SetVariable delaySV,win=ChirpBuilderView,pos={40,12},size={140,17},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=ChirpBuilderView,limits={0,1000,1},value= _NUM:delay
	SetVariable durationSV,win=ChirpBuilderView,pos={205,12},size={120,17},proc=BuilderContSVTwiddled,title="Duration (ms)"
	SetVariable durationSV,win=ChirpBuilderView,format="%g",limits={0,10000,10},value= _NUM:duration
	SetVariable amplitudeSV,win=ChirpBuilderView,pos={128,43},size={120,17},proc=BuilderContSVTwiddled,title="Amplitude"
	SetVariable amplitudeSV,win=ChirpBuilderView,limits={-10000,10000,10},value= _NUM:amplitude
	SetVariable initialFrequencySV,win=ChirpBuilderView,pos={205+165,12},size={150,17},proc=BuilderContSVTwiddled,title="Initial Frequency (Hz)"
	SetVariable initialFrequencySV,win=ChirpBuilderView,format="%g",limits={0,10000,10},value= _NUM:initialFrequency
	SetVariable finalFrequencySV,win=ChirpBuilderView,pos={205+165,43},size={150,17},proc=BuilderContSVTwiddled,title="Final Frequency (Hz)"
	SetVariable finalFrequencySV,win=ChirpBuilderView,format="%g",limits={0,10000,10},value= _NUM:finalFrequency
	Button saveAsDACButton,win=ChirpBuilderView,pos={601,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	Button importButton,win=ChirpBuilderView,pos={601,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function ChirpBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=5
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="duration"
	parameterNames[2]="amplitude"
	parameterNames[3]="initialFrequency"
	parameterNames[4]="finalFrequency"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=50
	parametersDefault[2]=10
	parametersDefault[3]=50
	parametersDefault[4]=200
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
End

Function fillChirpFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable delay=parameters[0]
	Variable duration=parameters[1]
	Variable amplitude=parameters[2]
	Variable initialFrequency=parameters[3]
	Variable finalFrequency=parameters[4]

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
	w[jFirst,jLast]=amplitude*sin(2*PI*(x-delay)/1000*(0.5*(finalFrequency-initialFrequency)/(duration/1000)*(x-delay)/1000+initialFrequency))
	jFirst=jLast+1
	jLast=nScans-1
	if (jFirst>=nScans)
		return 0
	endif
	w[jFirst,jLast]=0	
End
