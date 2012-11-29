//	DataPro//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18//	Nelson Spruston//	Northwestern University//	project began 10/27/1998#pragma rtGlobals=1		// Use modern global access method.Function SyncADCGainSetVariableToModel(i)	Variable i 	// ADC channel index	String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl	WAVE adcgain	WAVE adcType	String setVariableName=sprintf1d("adcGain%dSetVariable",i)	SetVariable $setVariableName value=_NUM:adcgain[i]	String titleBoxName=sprintf1d("adcGain%dUnitsTitleBox",i)	TitleBox $titleBoxName,title=adcGainUnitsStringFromAdcType(adcType[i])		SetDataFolder savDF	EndFunction SyncDACGainSetVariableToModel(i)	Variable i 	// DAC channel index	String savDF=GetDataFolder(1)	SetDataFolder root:DP_DigitizerControl	WAVE dacgain	WAVE dacType	String setVariableName=sprintf1d("dacGain%dSetVariable",i)	SetVariable $setVariableName value=_NUM:dacgain[i]	String titleBoxName=sprintf1d("dacGain%dUnitsTitleBox",i)	TitleBox $titleBoxName,title=dacGainUnitsStringFromDacType(dacType[i])	SetDataFolder savDF	End