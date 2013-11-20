//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=3		// Use modern global access method and strict wave access

Function ImagePlaneSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	ImageBrowserModelSetIFrame(varNum)
	ImageBrowserViewModelChanged()
	//ModifyImage ''#0 plane=(iFrame)
End

Function BlackCountSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	ImageBrowserModelSetBlackCount(varNum)
	ImageBrowserViewModelChanged()
End

Function WhiteCountSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	ImageBrowserModelSetWhiteCount(varNum)
	ImageBrowserViewModelChanged()
End

Function AutoGrayScaleButtonProc(ctrlName) : ButtonControl
	String ctrlName
	
	ImageBrowserModelAutoscale()
	ImageBrowserViewModelChanged()
End

Function ImagePopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	ImageBrowserModelSetVideo(popStr)
	ImageBrowserViewModelChanged()
End


Function ImageBrowserContAutoscaleCB(ctrlName,isChecked): CheckboxControl
	String ctrlName
	Variable isChecked
	
	ImageBrowserModSetAutoscaleFly(isChecked)
	ImageBrowserViewModelChanged()	

End




Function ImageBrowserContSetVideo(imageWaveName)
	String imageWaveName
	
	ImageBrowserModelSetVideo(imageWaveName)
	RaiseOrCreateView("ImageBrowserView")
	ImageBrowserViewModelChanged()	
End
