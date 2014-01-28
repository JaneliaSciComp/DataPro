#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// This is a swticher designed for one of the modern computer-controlled Axon Instruments amplifiers,
// which switches its primary output depending on whether you're doing current clamp
// or voltage clamp.

//
// Controller methods
//

Function ASwitcherContConstructor()
	ASwitcherModelConstructor()
	ASwitcherViewConstructor()
End

//Function ASwitcherContDigitizerEtcChngd()
//	// Called when the digitizer or the sweeper are changed.
//	//ASwitcherModelDigitizerEtcChngd()
//	ASwitcherViewUpdate()
//End

Function ASwitcherContRadioButton(controlName,checked) : CheckBoxControl
	String controlName
	Variable checked
	// Figure out CC vs VC, and the amplifier number, from the button control name
	String regExp="^amp(.)(.*)CB$"
	String amplifierIndexAsString, modeStringRaw
	SplitString /E=(regExp) controlName, amplifierIndexAsString, modeStringRaw
	Variable amplifierIndex=str2num(amplifierIndexAsString)

	// Determine the mode string from the "raw" mode string	
	String modeString
	if ( AreStringsEqual(modeStringRaw,"CurrentClamp") )
		modeString="Current Clamp"
	elseif ( AreStringsEqual(modeStringRaw,"VoltageClamp") )
		modeString="Voltage Clamp"
	else
		modeString=modeStringRaw
	endif
	
	// Update the switcher itself
	//ASwitcherModelSetMode(amplifierIndex,modeString)

	// Notify the other objects that need to change
	ASwitcherContSetOthersToMode(amplifierIndex,modeString)

	// Notify ourselves that the other object have changed (which will update the view)
	ASwitcherViewUpdate()	
	SwitcherViewUpdate()	
End

Function ASwitcherContTestPulseButton(controlName) : ButtonControl
	String controlName
	
	// Figure out the amplifier number from the button control name
	String regExp="^amp(.)TestPulseButton$"
	String amplifierIndexAsString
	SplitString /E=(regExp) controlName, amplifierIndexAsString
	Variable amplifierIndex=str2num(amplifierIndexAsString)
	Variable dacIndex=ASwitcherModelGetOutputDACIndex(amplifierIndex)
	Variable adcIndex=ASwitcherModelGetInputADCIndex(amplifierIndex)
	TestPulserContConstructor() 	// make sure the test pulser exists
	TestPulserContSetDACIndex(dacIndex)
	TestPulserContSetADCIndex(adcIndex)
	TestPulserContStart()
End

Function ASwitcherContSetVariable(controlName,newValue,varStr,varName) : SetVariableControl
	String controlName
	Variable newValue	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable

	// Figure out which setvariable, and the amplifier number, from the button control name,
	// And update the model.
	String regExp="^amp(.)(.*)SV$"
	String amplifierIndexAsString, variableNameRaw
	SplitString /E=(regExp) controlName, amplifierIndexAsString, variableNameRaw
	Variable amplifierIndex=str2num(amplifierIndexAsString)
	if ( AreStringsEqual(variableNameRaw,"InputADC") )
		ASwitcherModelSetInputADCIndex(amplifierIndex,newValue)
	endif
	if ( AreStringsEqual(variableNameRaw,"OutputDAC") )
		ASwitcherModelSetOutputDACIndex(amplifierIndex,newValue)
	endif

	// Update the view
	ASwitcherViewUpdate()
End

Function ASwitcherContSetOthersToMode(amplifierIndex,modeName)
	// Set the digitizer and sweeper to be consistent with the given modeName.
	// This is a private method.
	Variable amplifierIndex
	String modeName

	// Set the DAC channel appropriately
	Variable dacIndex=ASwitcherModelGetOutputDACIndex(amplifierIndex)
	// Determine the ADC channel used for recording
	Variable adcIndex=ASwitcherModelGetInputADCIndex(amplifierIndex)
	if ( AreStringsEqual(modeName,"Current Clamp") )
		SweeperContSetDACChannelOn(dacIndex,1)
		DigitizerContSetDACModeName(dacIndex,"Current")
		SweeperContSetADCChannelOn(adcIndex,1)	// Turn channels on before off, b/c can't turn all channels off
		DigitizerContSetADCModeName(adcIndex,"Voltage")
	elseif ( AreStringsEqual(modeName,"Voltage Clamp") )
		SweeperContSetDACChannelOn(dacIndex,1)
		DigitizerContSetDACModeName(dacIndex,"Voltage")
		SweeperContSetADCChannelOn(adcIndex,1)
		DigitizerContSetADCModeName(adcIndex,"Current")
	elseif ( AreStringsEqual(modeName,"Unused") )
		SweeperContSetDACChannelOn(dacIndex,0)
		SweeperContSetADCChannelOn(adcIndex,0)
	endif
End



//
// View methods
//

Function ASwitcherViewConstructor() : Graph
	// If the panel already exists, just bring it forward
	if (PanelExists("ASwitcherView"))
		DoWindow /F ASwitcherView
		return 0
	endif

	// Draw the panel
	ASwitcherViewLayout()
	
	// Sync the panel to the model
	ASwitcherViewUpdate()
End

Function ASwitcherViewLayout()
	// Draws the ASwitcher panel
	
	// Make the GroupBoxes, one per amplifier
	// (the first iteration actually makes the panel, too)
	Variable nAmplifiers=ASwitcherModelGetNumAmplifiers()
	Variable amplifierIndex
	for (amplifierIndex=1; amplifierIndex<=nAmplifiers; amplifierIndex+=1)
		ASwitcherViewLayoutGroup(amplifierIndex)
	endfor
End


Function ASwitcherViewLayoutGroup(amplifierIndex)
	Variable amplifierIndex	// Amplifier index

	// Pads are named after the thing _inside_ the padding
	// The size of a "cluster" includes the size of the padding around the cluster.
	// The button "cluster" contains only the one button

	// Parameters controlling the placement of the panel 
	Variable panelXOffset=720
	Variable panelYOffset=54

	// Set the parameters that determine the layout of each group box
	Variable nAmplifiers=ASwitcherModelGetNumAmplifiers()
	Variable nSetVariables=2
	Variable tbWidth=70		// tb==titlebox
	Variable tbHeight=16
	Variable tbShimHeight=1
	Variable svWidth=30
	Variable svHeight=16
	Variable svRowHeight=max(tbHeight,svHeight)
	Variable interSVRowHeight=5
	Variable svRowClusterTopPadHeight=10
	Variable svRowClusterPadWidth=20
	Variable svRowWidth=tbWidth+svWidth
	Variable svRowClusterHeight=nSetVariables*svRowHeight+(nSetVariables-1)*interSVRowHeight+svRowClusterTopPadHeight
	Variable svRowClusterWidth=svRowWidth+2*svRowClusterPadWidth

	Variable svRowClusterButtonSpaceHeight=20

	Variable buttonWidth=90
	Variable buttonHeight=25
	Variable buttonPadWidth=10
	Variable buttonBottomPadHeight=15
	Variable buttonClusterWidth=buttonWidth+2*buttonPadWidth
	Variable buttonClusterHeight=buttonHeight+buttonBottomPadHeight

	// The "left column" consists of the svCluster and the buttonCluster, one on top of the other
	Variable leftColumnWidth=max(svRowClusterWidth,buttonClusterWidth)
	Variable leftColumnHeight=svRowClusterHeight+svRowClusterButtonSpaceHeight+buttonClusterHeight

	Variable nRadioButtons=3
	Variable rbHeight=14
	Variable rbWidth=90
	Variable interRBHeight=7
	Variable rbClusterRightPadWidth=25
	Variable rbClusterPadHeight=0	
	Variable rbClusterWidth=rbWidth+rbClusterRightPadWidth
	Variable rbClusterHeight=nRadioButtons*rbHeight+(nRadioButtons-1)*interRBHeight+2*rbClusterPadHeight

	Variable interColumnSpaceWidth=10

	Variable groupWidth=leftColumnWidth+interColumnSpaceWidth+rbClusterWidth
	Variable groupInnerHeight=max(leftColumnHeight,rbClusterHeight)
	Variable groupTitleHeight=14	// Approximate height of text for each groupbox
	Variable groupOuterHeight=groupInnerHeight+groupTitleHeight
	
	Variable interGroupSpaceHeight=8
	Variable groupClusterPadWidth=8
	Variable groupClusterPadHeight=8
	Variable panelWidth=groupWidth+2*groupClusterPadWidth
	Variable panelHeight=nAmplifiers*groupOuterHeight+(nAmplifiers-1)*interGroupSpaceHeight+2*groupClusterPadHeight
	
	Variable groupXOffset=groupClusterPadWidth
	Variable groupYOffset=groupClusterPadHeight+(amplifierIndex-1)*(groupOuterHeight+interGroupSpaceHeight)
	Variable xOffset=groupXOffset
	Variable yOffset=groupYOffset

	Variable nADCChannels=DigitizerModelGetNumADCChans()
	Variable nDACChannels=DigitizerModelGetNumDACChans()

	// If this the first time through, actually make the panel
	if (amplifierIndex==1)
		NewPanel /W=(panelXOffset,panelYOffset,panelXOffset+panelWidth,panelYOffset+panelHeight) /K=1 /N=ASwitcherView as "Axon Switcher"
		ModifyPanel /W=ASwitcherView fixedSize=1
	endif

	String controlName=sprintf1v("amp%dGroup",amplifierIndex)	
	GroupBox $controlName,win=ASwitcherView,pos={xOffset,yOffset},size={groupWidth,groupOuterHeight},title=sprintf1v("Amplifier %d",amplifierIndex)

	xOffset=groupXOffset+(leftColumnWidth-svRowWidth)/2
	yOffset=groupYOffset+groupTitleHeight+svRowClusterTopPadHeight
	controlName=sprintf1v("amp%dInputADCTB",amplifierIndex)	
	TitleBox $controlName, win=ASwitcherView, pos={xOffset,yOffset+tbShimHeight}, size={tbWidth,tbHeight}, frame=0, title="Input ADC:"
	controlName=sprintf1v("amp%dInputADCSV",amplifierIndex)
	SetVariable $controlName, win=ASwitcherView, pos={xOffset+tbWidth,yOffset}, size={svWidth,svHeight}, limits={0,nADCChannels-1,1}, proc=ASwitcherContSetVariable, title=""

	yOffset+=svRowHeight+interSVRowHeight
	controlName=sprintf1v("amp%dOutputDACTB",amplifierIndex)
	TitleBox $controlName, win=ASwitcherView, pos={xOffset,yOffset+tbShimHeight}, size={tbWidth,tbHeight}, frame=0, title="Output DAC:"
	controlName=sprintf1v("amp%dOutputDACSV",amplifierIndex)
	SetVariable $controlName, win=ASwitcherView, pos={xOffset+tbWidth,yOffset}, size={svWidth,svHeight}, limits={0,nDACChannels-1,1}, proc=ASwitcherContSetVariable, title=""
	
	xOffset=groupXOffset+(leftColumnWidth-buttonWidth)/2
	yOffset=groupYOffset+groupTitleHeight+svRowClusterHeight+svRowClusterButtonSpaceHeight
	controlName=sprintf1v("amp%dTestPulseButton",amplifierIndex)
	Button $controlName, win=ASwitcherView,pos={xOffset,yOffset},size={buttonWidth,buttonHeight},proc=ASwitcherContTestPulseButton,title="Test Pulse"
	
	xOffset=groupXOffset+leftColumnWidth+interColumnSpaceWidth
	yOffset=	groupYOffset+groupTitleHeight+(groupInnerHeight-rbClusterHeight)/2
	controlName=sprintf1v("amp%dCurrentClampCB",amplifierIndex)
	CheckBox $controlName, win=ASwitcherView, pos={xOffset,yOffset}, size={rbWidth,rbHeight},mode=1, proc=ASwitcherContRadioButton, title="Current Clamp"
	yOffset+=rbHeight+interRBHeight
	controlName=sprintf1v("amp%dVoltageClampCB",amplifierIndex)
	CheckBox $controlName, win=ASwitcherView, pos={xOffset,yOffset}, size={rbWidth,rbHeight}, mode=1, proc=ASwitcherContRadioButton, title="Voltage Clamp"
	yOffset+=rbHeight+interRBHeight
	controlName=sprintf1v("amp%dUnusedCB",amplifierIndex)
	CheckBox $controlName, win=ASwitcherView, pos={xOffset,yOffset}, size={rbWidth,rbHeight}, mode=1, proc=ASwitcherContRadioButton, title="Unused"
End

Function ASwitcherViewUpdate()
	if ( !ASwitcherModelExists() )
		return 0		// Have to return something
	endif
	if (!PanelExists("ASwitcherView"))
		return 0		// Have to return something
	endif	
	Variable nAmplifiers=ASwitcherModelGetNumAmplifiers()
	Variable amplifierIndex
	for (amplifierIndex=1; amplifierIndex<=nAmplifiers; amplifierIndex+=1)
		ASwitcherViewUpdateGroup(amplifierIndex)
	endfor
End

Function ASwitcherViewUpdateGroup(amplifierIndex)
	Variable amplifierIndex	// Amplifier index (1st element is element 1)

	if ( !ASwitcherModelExists() )
		return 0		// Have to return something
	endif
	if (!PanelExists("ASwitcherView"))
		return 0		// Have to return something
	endif	

	String savedDF=GetDataFolder(1)
	SetDataFolder root:ASwitcher

	WAVE inputADCIndex
	WAVE outputDACIndex
	//WAVE /T amplifierMode
	
	String amplifierMode=ASwitcherModelGetMode(amplifierIndex)
	Variable j=amplifierIndex-1		// Amplifier index (1st element is element 0)
	String controlName=sprintf1v("amp%dInputADCSV",amplifierIndex)
	SetVariable $controlName, win=ASwitcherView, value= _NUM:inputADCIndex[j]
	controlName=sprintf1v("amp%dOutputDACSV",amplifierIndex)
	SetVariable $controlName, win=ASwitcherView, value= _NUM:outputDACIndex[j]
	controlName=sprintf1v("amp%dCurrentClampCB",amplifierIndex)
	CheckBox $controlName, win=ASwitcherView, value= (AreStringsEqual(amplifierMode,"Current Clamp"))
	controlName=sprintf1v("amp%dVoltageClampCB",amplifierIndex)
	CheckBox $controlName, win=ASwitcherView, value= (AreStringsEqual(amplifierMode,"Voltage Clamp")) 
	controlName=sprintf1v("amp%dUnusedCB",amplifierIndex)
	CheckBox $controlName, win=ASwitcherView, value= (AreStringsEqual(amplifierMode,"Unused"))
	// Gray the test pulse if the mode is not ("Current Clamp" or "Voltage Clamp")
	Variable buttonEnabled= ( AreStringsEqual(amplifierMode,"Current Clamp") || AreStringsEqual(amplifierMode,"Voltage Clamp") )
	controlName=sprintf1v("amp%dTestPulseButton",amplifierIndex)
	Button $controlName, win=ASwitcherView, disable=2*(1-buttonEnabled)

	SetDataFolder savedDF		
End



//
// Model methods
//

Function ASwitcherModelConstructor()
	// Construct the model

	// if the DF already exists, nothing to do
	if (ASwitcherModelExists())
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)
	
	// Create a new DF
	NewDataFolder /S root:ASwitcher
	
	// Create the instance variables
	Variable /G nAmplifiers=2
	Make /N=(nAmplifiers) inputADCIndex={0,1,2,3}
	Make /N=(nAmplifiers) outputDACIndex={0,1,2,3}
	//Make /T /N=(nAmplifiers) amplifierMode
	
	//ASwitcherModelDigitizerEtcChngd()		// Set the amplifier mode based on the current state of the digitizer and sweeper

	// Restore the original data folder
	SetDataFolder savedDF
End

//Function ASwitcherModelDigitizerEtcChngd()
//	// Updates the switcher mode to be consistent with the digitizer and sweeper state.
//	Variable nAmplifiers=ASwitcherModelGetNumAmplifiers()
//	Variable amplifierIndex
//	for (amplifierIndex=1; amplifierIndex<=nAmplifiers; amplifierIndex+=1)
//		ASwitcherModelSyncModeToOthers(amplifierIndex)
//	endfor
//End

//Function ASwitcherModelSyncModeToOthers(amplifierIndex)
//	// Updates the switcher mode for the given amplifier to be consistent with the digitizer and sweeper state.
//	Variable amplifierIndex
//	
//	String amplifierMode=ASwitcherModelGetMode(amplifierIndex)
//	
//	// Set the mode
//	ASwitcherModelSetMode(amplifierIndex,amplifierMode)
//End

Function ASwitcherModelGetNumAmplifiers()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:ASwitcher

	NVAR nAmplifiers
	Variable result=nAmplifiers
		
	SetDataFolder savedDF		
	
	return result
End

Function ASwitcherModelGetOutputDACIndex(amplifierIndex)
	Variable amplifierIndex
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:ASwitcher

	WAVE outputDACIndex
	Variable result=outputDACIndex[amplifierIndex-1]
		
	SetDataFolder savedDF			

	return result
End

Function ASwitcherModelGetInputADCIndex(amplifierIndex)
	Variable amplifierIndex
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:ASwitcher

	WAVE inputADCIndex
	Variable result=inputADCIndex[amplifierIndex-1]
		
	SetDataFolder savedDF			
	
	return result
End

//Function ASwitcherModelSetMode(amplifierIndex,modeString)
//	Variable amplifierIndex
//	String modeString
//	
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:ASwitcher
//
//	WAVE /T amplifierMode
//	amplifierMode[amplifierIndex-1]=modeString
//		
//	SetDataFolder savedDF		
//End

//Function /S ASwitcherModelGetMode(amplifierIndex)
//	Variable amplifierIndex
//
//	String savedDF=GetDataFolder(1)
//	SetDataFolder root:ASwitcher
//
//	WAVE /T amplifierMode
//	
//	Variable j=amplifierIndex-1		// Amplifier index (1st element is element 0)
//	String result=amplifierMode[j]
//	
//	SetDataFolder savedDF		
//
//	return result
//End

Function ASwitcherModelSetOutputDACIndex(amplifierIndex,newValue)
	Variable amplifierIndex
	Variable newValue
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:ASwitcher

	WAVE outputDACIndex
	outputDACIndex[amplifierIndex-1]=newValue
		
	SetDataFolder savedDF			
End

Function ASwitcherModelSetInputADCIndex(amplifierIndex,newValue)
	Variable amplifierIndex
	Variable newValue
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:ASwitcher

	WAVE inputADCIndex
	inputADCIndex[amplifierIndex-1]=newValue
		
	SetDataFolder savedDF			
End

Function /S ASwitcherModelGetMode(amplifierIndex)
	// Queries the digitizer and sweeper to determine the current switcher mode for the
	// given amplifier
	Variable amplifierIndex
	
	Variable dacIndex=ASwitcherModelGetOutputDACIndex(amplifierIndex)
	Variable adcIndex=ASwitcherModelGetInputADCIndex(amplifierIndex)

	// Probe the digitizer, sweeper, figure out what the amplifier mode is
	String amplifierMode="Other"		// default to this
	if ( SweeperGetDACOn(dacIndex) )
		// The DAC channel is on
		String dacModeName=DigitizerModelGetDACModeName(dacIndex)
		// We look at the DAC mode first, because that primarily determines whether we're in current clamp or voltage clamp.
		// After we know that, we just have to make sure everything else is consistent
		if ( AreStringsEqual(dacModeName,"Current") ) 
			// Initial signs point to current clamp
			if ( SweeperGetADCOn(adcIndex) )
				if ( AreStringsEqual(DigitizerModelGetADCModeName(adcIndex),"Voltage") )
					amplifierMode="Current Clamp"
				endif
			endif			
		elseif ( AreStringsEqual(dacModeName,"Voltage") )
			// Looks like amplifier mode is voltage-clamp, but verify that everything else is in order
			if ( SweeperGetADCOn(adcIndex) )
				if ( AreStringsEqual(DigitizerModelGetADCModeName(adcIndex),"Current") )
					amplifierMode="Voltage Clamp"
				endif
			endif			
		endif	
	else
		// The DAC channel is off, so the only possible switcher modes are
		// Unused and Other.
		if ( !SweeperGetADCOn(adcIndex) )
			amplifierMode="Unused"
		endif
	endif
	
	// Set the mode
	return amplifierMode
End



// Not sure where this belongs, but it's useful
Function ASwitcherModelExists()
	return (DataFolderExists("root:ASwitcher"))
End


