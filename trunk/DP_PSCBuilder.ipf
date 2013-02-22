#pragma rtGlobals=1		// Use modern global access method.

Function PSCBuilderViewConstructor() : Graph
	//BuilderModelConstructor("PSC")
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_PSCBuilder
	WAVE theWave
	WAVE parameters
	Variable delay=parameters[0]
	Variable amplitude=parameters[1]
	Variable tauRise=parameters[2]		
	Variable tauDecay1=parameters[3]		
	Variable tauDecay2=parameters[4]		
	Variable weightDecay2=parameters[5]		
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
	Display /W=(xOffsetInPoints,yOffsetInPoints,xOffsetInPoints+widthInPoints,yOffsetInPoints+heightInPoints) /K=1 /N=PSCBuilderView theWave as "PSC Builder"
	//ModifyGraph /W=PSCBuilderView /Z margin(top)=36
	ModifyGraph /W=PSCBuilderView /Z grid(left)=1
	Label /W=PSCBuilderView /Z bottom "Time (ms)"
	Label /W=PSCBuilderView /Z left "Signal (pure)"
	ModifyGraph /W=PSCBuilderView /Z tickUnit(bottom)=1
	ModifyGraph /W=PSCBuilderView /Z tickUnit(left)=1
	ControlBar 80
	SetVariable delaySV,win=PSCBuilderView,pos={42,12},size={110,17},proc=BuilderContSVTwiddled,title="Delay (ms)"
	SetVariable delaySV,win=PSCBuilderView,limits={0,1000,1},value= _NUM:delay
	SetVariable amplitudeSV,win=PSCBuilderView,pos={28,43},size={120,17},proc=BuilderContSVTwiddled,title="Amplitude"
	SetVariable amplitudeSV,win=PSCBuilderView,limits={-10000,10000,10},value= _NUM:amplitude
	SetVariable tauRiseSV,win=PSCBuilderView,pos={163,43},size={120,17},proc=PSCBControllerRiseTauSVTwiddled,title="Rise Tau (ms)"
	SetVariable tauRiseSV,win=PSCBuilderView,format="%g",limits={0,10000,0.1},value= _NUM:tauRise
	SetVariable tauDecay1SV,win=PSCBuilderView,pos={320,42},size={130,17},proc=PSCBControllerDecayTauSVTwid,title="Decay Tau 1 (ms)"
	SetVariable tauDecay1SV,win=PSCBuilderView,format="%g",limits={0,10000,1},value= _NUM:tauDecay1
	SetVariable tauDecay2SV,win=PSCBuilderView,pos={470,41},size={130,17},proc=PSCBControllerDecayTauSVTwid,title="Decay Tau 2 (ms)"
	SetVariable tauDecay2SV,win=PSCBuilderView,format="%g",limits={0,10000,10},value= _NUM:tauDecay2
	SetVariable weightDecay2SV,pos={440,12},size={140,17},proc=BuilderContSVTwiddled,title="Weight of Decay 2"
	SetVariable weightDecay2SV,format="%2.1f",limits={0,1,0.1},value= _NUM:weightDecay2
	Button saveAsDACButton,win=PSCBuilderView,pos={670,10},size={90,20},proc=BuilderContSaveAsButtonPressed,title="Save As..."
	Button importButton,win=PSCBuilderView,pos={670,45},size={90,20},proc=BuilderContImportButtonPressed,title="Import..."
	SetDataFolder savedDF
End

Function PSCBuilderModelInitialize()
	// Called from the constructor, so DF already set.
	Variable nParameters=6
	WAVE /T parameterNames
	WAVE parametersDefault
	WAVE parameters
	Redimension /N=(nParameters) parameterNames
	parameterNames[0]="delay"
	parameterNames[1]="amplitude"
	parameterNames[2]="tauRise"
	parameterNames[3]="tauDecay1"
	parameterNames[4]="tauDecay2"
	parameterNames[5]="weightDecay2"
	Redimension /N=(nParameters) parametersDefault
	parametersDefault[0]=10
	parametersDefault[1]=10
	parametersDefault[2]=0.2
	parametersDefault[3]=2
	parametersDefault[4]=10
	parametersDefault[5]=0.5
	Redimension /N=(nParameters) parameters
	parameters=parametersDefault
End

Function fillPSCFromParamsBang(w,dt,nScans,parameters,parameterNames)
	Wave w
	Variable dt,nScans
	Wave parameters
	Wave /T parameterNames

	Variable delay=parameters[0]
	Variable amplitude=parameters[1]
	Variable tauRise=parameters[2]		
	Variable tauDecay1=parameters[3]		
	Variable tauDecay2=parameters[4]		
	Variable weightDecay2=parameters[5]		

	// Set the delay portion
	Variable nDelay=floor(delay/dt)		// err on the side of making this too small, if anything
	w[0,nDelay-1]=0
	// Set the main portion
	if (nDelay>=nScans)
		return 0
	endif
	w[nDelay,nScans-1]= (x>=delay)*(-exp(-(x-delay)/tauRise)+(1-weightDecay2)*exp(-(x-delay)/tauDecay1)+weightDecay2*exp(-(x-delay)/tauDecay2))
	// re-scale to have the proper amplitude
	Wavestats /Q w
	w=(amplitude/V_max)*w		// want the peak amplitude to be amplitude
End

// Below are special callback functions that check the validity of certain parameter values

Function PSCBControllerRiseTauSVTwiddled(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif
	
	// Extract the parameterName from the SV name
	String svName=svStruct.ctrlName
	String parameterName=svName[0,strlen(svName)-3]
	
	// Get the value
	Variable value=svStruct.dval
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_PSCBuilder"

	WAVE parameters
	Variable tauDecay1=parameters[3]		
	Variable tauDecay2=parameters[4]		

	if (value<tauDecay1 && value<tauDecay2) 
		// valid value, set the instance var
		BuilderModelSetParameter("PSC","tauRise",value)
	endif
	BuilderViewModelChanged("PSC")
	
	SetDataFolder savedDF
End

Function PSCBControllerDecayTauSVTwid(svStruct) : SetVariableControl
	STRUCT WMSetVariableAction &svStruct
	if ( svStruct.eventCode==-1 ) 
		return 0
	endif
	
	// Extract the parameterName from the SV name
	String svName=svStruct.ctrlName
	String parameterName=svName[0,strlen(svName)-3]
	
	// Get the value
	Variable value=svStruct.dval
	
	String savedDF=GetDataFolder(1)
	SetDataFolder "root:DP_PSCBuilder"

	WAVE parameters
	Variable tauRise=parameters[2]		

	if (tauRise<value)
		// valid value, set the instance var
		BuilderModelSetParameter("PSC",parameterName,value)
	endif
	BuilderViewModelChanged("PSC")
	
	SetDataFolder savedDF
End
