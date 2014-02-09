//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function EpiLightConstructor()
	// if the DF already exists, nothing to do
	if (DataFolderExists("root:DP_EpiLight"))
		return 0		// have to return something
	endif

	// Save the current DF
	String savedDF=GetDataFolder(1)

	// Make a new DF, switch to it
	NewDataFolder /O/S root:DP_EpiLight

	// Instance vars
	Variable /G isInControl=1	
		// boolean, if true it means that we assert control of the light.  If false, we cede control to others, typically the Sweeper.
	Variable /G isOn=0	// boolean, only relevant if 
		// To outsiders, the EpiLight is in one of three possible states: on, off, and agnostic.
		// on: isInControl=1, isOn=1
		// off: isInControl=1, isOn=0
		// agnostic: isInControl=0, isOn=0
		// We ensure that isInControl=0, isOn=1 never happens
	Variable /G ttlOutputIndex=1		// the TTL channel to which the light is hooked up
	Variable /G triggeredDelay=10		// ms
	Variable /G triggeredDuration=210		// ms
	
	// Restore the original data folder
	SetDataFolder savedDF	
End



Function EpiLightTurnOn()
	// This implicitly sets isInControl to true
	Variable value
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isInControl
	NVAR isOn
	NVAR ttlOutputIndex
	isOn=1
	isInControl=1
	SamplerSetBackgroundTTLOutput(ttlOutputIndex,1)
	SetDataFolder savedDF	
End



Function EpiLightTurnOff()
	// This implicitly sets isInControl to true
	Variable value
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isInControl
	NVAR isOn
	NVAR ttlOutputIndex
	isOn=0
	isInControl=1
	SamplerSetBackgroundTTLOutput(ttlOutputIndex,0)
	SetDataFolder savedDF	
End



Function EpiLightTurnAgnostic()
	// This sets EpiLight to the agnostic state
	Variable value
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isInControl
	NVAR isOn
	NVAR ttlOutputIndex
	isOn=0
	isInControl=0
	SamplerSetBackgroundTTLOutput(ttlOutputIndex,0)
	// Q: If turning it agnostic turns it off, why even have an "agnostic" state?
	// A: Because the ImageView displays differently depending on whether the EpiLight is
	//		off or agnostic, to signal the user that in the agnostic state, 
	//		the EpiLight object is not really in control of the light.
	SetDataFolder savedDF	
End



Function EpiLightToggle()
	// If EpiLight is in a non-agnostic state, switch to the other
	// non-agnostic state.  If EpiLight is an an agnostic state, do nothing.
	if ( !EpiLightGetIsAgnostic() )
		if ( EpiLightGetIsOn() )
			EpiLightTurnOff()
		else
			EpiLightTurnOn()
		endif
	endif
End



Function EpiLightGetState()
	// Returns 1 for on, 0 for off, and 0.5 for agnostic
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isInControl
	NVAR isOn
	Variable value
	if (isInControl)
		value=isOn
	else
		value=0.5
	endif
	SetDataFolder savedDF	
	return value
End



Function EpiLightGetIsOn()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isInControl
	NVAR isOn	
	Variable value=(isInControl&&isOn)
	SetDataFolder savedDF	
	return value
End



Function EpiLightGetIsOff()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isInControl
	NVAR isOn	
	Variable value=(isInControl&&!isOn)
	SetDataFolder savedDF	
	return value
End



Function EpiLightGetIsAgnostic()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR isInControl
	Variable value=(!isInControl)
	SetDataFolder savedDF	
	return value
End




Function EpiLightSetTTLOutputIndex(newValue)
	Variable newValue
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	
	NVAR ttlOutputIndex
	NVAR isInControl
	NVAR isOn

	Variable originalValue=ttlOutputIndex
	// If the EpiLight is on right now, no changes to the TTL output setting are allowed
	if ( !EpiLightGetIsOn() )
		// Make sure the value is in-range
		if ( (0<=newValue) && (newValue<=3) )
			// Check that the new TTL output is not in use by the test pulser
			Variable conflictsWithTestPulser=( TestPulserExists() && TestPulserIsTTLInUse(newValue) )
			Variable conflictsWithSweeper=( SweeperGetTTLOutputChannelOn(newValue) || SweeperGetTTLOutputHijacked(newValue) )
			if ( !(conflictsWithTestPulser || conflictsWithSweeper) )
				// If we get here, then the destination TTL channel is available, so we'll proceed with the switch
				if ( ImagerGetIsTriggered() )
					if ( SweeperGetTTLOutputHijacked(originalValue) )
						// This means that the original TTL channel is hijacked, and we are the hijacker
						ImagerUnhijackSweeperEpiGate(originalValue)
					endif
					ImagerHijackSweeperEpiGate(newValue)
				endif
				ttlOutputIndex=newValue
			endif
		endif
	endif
	
	SetDataFolder savedDF	
End



Function EpiLightGetTTLOutputIndex()	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR ttlOutputIndex
	Variable value=ttlOutputIndex
	SetDataFolder savedDF	
	return value
End



Function EpiLightIsTTLOutputInUse(i)
	Variable i 
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR ttlOutputIndex
	Variable value=(ttlOutputIndex==i)
	SetDataFolder savedDF	
	return value
End



Function EpiLightGetTriggeredDelay()
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR triggeredDelay
	Variable value=triggeredDelay
	SetDataFolder savedDF	
	return value
End



Function EpiLightSetTriggeredDelay(newValue)
	Variable newValue
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR triggeredDelay
	if (newValue>=0)
		triggeredDelay=newValue
		ImagerChangeSweeperEpiGate()
	endif
	SetDataFolder savedDF	
End



Function EpiLightGetTriggeredDuration()	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR triggeredDuration
	Variable value=triggeredDuration
	SetDataFolder savedDF	
	return value
End



Function EpiLightSetTriggeredDuration(newValue)
	Variable newValue
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_EpiLight
	NVAR triggeredDuration
	if (newValue>=0)
		triggeredDuration=newValue
		ImagerChangeSweeperEpiGate()
	endif
	SetDataFolder savedDF	
End



