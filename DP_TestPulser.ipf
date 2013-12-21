//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserConstructor()
	String savedDF=GetDataFolder(1)
	// If the TestPulser data folder doesn't exist, create it
	if (!DataFolderExists("root:DP_TestPulser"))
 		NewDataFolder /S root:DP_TestPulser
		Variable /G amplitude=1		// test pulse amplitude, units determined by channel type
		Variable /G duration=10		// test pulse duration, ms
		Variable /G dt=0.02		// sample interval for the test pulse, ms
		Variable /G adcIndex=0		// index of the ADC channel to be used for the test pulse
		Variable /G dacIndex=0		// index of the DAC channel to be used for the test pulse	
		Variable /G ttlOutput=0		// whether or not to do a TTL output during test pulse
		Variable /G ttlOutIndex=0	   // index of the TTL used for gate output, if ttlOutput is true
		Variable /G doBaselineSubtraction=1	// whether to do baseline subtraction
		Variable /G RSeal=nan	// GOhm
		Variable /G updateRate=nan		// Hz	
	endif
	SetDataFolder savedDF
End


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserSetDACIndex(newValue)
	Variable newValue

	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	NVAR dacIndex
	dacIndex=newValue	

	SetDataFolder savedDF
End	


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserSetADCIndex(newValue)
	Variable newValue
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser
	
	NVAR adcIndex
	adcIndex=newValue	

	SetDataFolder savedDF
End	


//----------------------------------------------------------------------------------------------------------------------------
Function TestPulserIsTTLInUse(ttlOutputIndexInQuestion)
	Variable ttlOutputIndexInQuestion
	
	String savedDF=GetDataFolder(1)
	SetDataFolder root:DP_TestPulser

	NVAR ttlOutput		// whether or not to do a TTL output during test pulse
	NVAR ttlOutIndex	   // index of the TTL used for gate output, if ttlOutput is true

	Variable value=( ttlOutput && (ttlOutIndex==ttlOutputIndexInQuestion) )

	SetDataFolder savedDF	
	
	return value
End

