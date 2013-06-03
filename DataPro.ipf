//	DataPro
//	DAC/ADC macros for use with Igor Pro and the ITC-16 or ITC-18
//	Nelson Spruston
//	Northwestern University
//	project began 10/27/1998

#pragma rtGlobals=1		// Use modern global access method.

//#include <Strings as Lists> 
#include ":datapro_rel_706:DP_Sampler"
#include ":datapro_rel_706:DP_DigitizerModel"
#include ":datapro_rel_706:DP_DigitizerView"
#include ":datapro_rel_706:DP_DigitizerController"
#include ":datapro_rel_706:DP_BrowserModel"
#include ":datapro_rel_706:DP_BrowserView"
#include ":datapro_rel_706:DP_BrowserController"
#include ":datapro_rel_706:DP_Sweeper"
#include ":datapro_rel_706:DP_SweeperView"
#include ":datapro_rel_706:DP_SweeperController"
#include ":datapro_rel_706:DP_TestPulser"
#include ":datapro_rel_706:DP_SineBuilder"
#include ":datapro_rel_706:DP_ChirpBuilder"
#include ":datapro_rel_706:DP_PSCBuilder"
#include ":datapro_rel_706:DP_RampBuilder"
#include ":datapro_rel_706:DP_TrainBuilder"
#include ":datapro_rel_706:DP_TTLTrainBuilder"
#include ":datapro_rel_706:DP_MulTrainBuilder"
#include ":datapro_rel_706:DP_TTLMTrainBuilder"
#include ":datapro_rel_706:DP_StairBuilder"
#include ":datapro_rel_706:DP_OutputViewer"
#include ":datapro_rel_706:DP_Utilities"
#include ":datapro_rel_706:DP_MyProcedures"
#include ":datapro_rel_706:DP_BuilderModel"
#include ":datapro_rel_706:DP_BuilderView"
#include ":datapro_rel_706:DP_BuilderController"
#include ":datapro_rel_706:DP_Switcher"
#include ":datapro_rel_706:DP_ASwitcher"
//#include "DP_Acquire"
//#include "DP_Analyze"
//#include "DP_Image"
//#include "DP_SIDX"
//#include "DP_Windows"
//#include "DP_MyVariables"
//#include "DP_LTP"

//---------------------- DataPro MENU -----------------------//

Menu "DataPro"
	"All Controls",MainConstructors()
	"-"
	"Sweeper Controls",SweeperContConstructor()
	"Digitizer Controls",DigitizerContConstructor()
	"New Browser",BrowserContConstructor("New")
	"-"
	"Test Pulser",TestPulserContConstructor()
	"-"
	"Stair Builder",BuilderContConstructor("Stair")
	"Train Builder",BuilderContConstructor("Train")
	"TTL Train Builder",BuilderContConstructor("TTLTrain")
	"Multiple Train Builder",BuilderContConstructor("MulTrain")
	"Multiple TTL Train Builder",BuilderContConstructor("TTLMTrain")
	"Ramp Builder",BuilderContConstructor("Ramp")
	"PSC Builder",BuilderContConstructor("PSC")
	"Sine Builder",BuilderContConstructor("Sine")
	"Chirp Builder",BuilderContConstructor("Chirp")
	"-"
	"Output Viewer",OutputViewerContConstructor()
	"-"
	"Switcher",SwitcherContConstructor()
	"Axon Switcher",ASwitcherContConstructor()
End

//Function IgorStartOrNewHook(igorApplicationNameStr)
//	String igorApplicationNameStr
//	InitializeDataPro()
//End

Function AfterCompiledHook()
	InitializeDataPro()
End

Function InitializeDataPro()
	//String savedDF=GetDataFolder(1)
	//NewDataFolder /O/S root:DP_Digitizer
	//String pathToThisFile=FunctionPath("")
	//String dataProPathAbs=ParseFilePath(1,pathToThisFile,":",1,0)
	//	// first 1 says to get the path up but not including the specified element
	//	// second 1 says the specified element is relative to the last element
	//	// 0 indicates the zeroth element (relative to the last), hence the last element
	//NewPath /O DataPro dataProPathAbs
	//LoadPICT /O /P=DataPro "DataProMenu.jpg", DataProMenu
	SamplerConstructor()
	DigitizerModelConstructor()
	SweeperConstructor()
End

//Function AcquisitionPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum
//	String popStr
//End

//Function StartPanel() : Panel
//	PauseUpdate; Silent 1		// building window...
//	NewPanel /W=(271,307,737,541)
//	SetDrawLayer UserBack
//	SetDrawEnv fstyle= 1
//	DrawText 68,30,"It is very important that you save this as an"
//	SetDrawEnv fstyle= 1
//	DrawText 38,56,"unpacked experiment before you begin acquiring data."
//	SetDrawEnv fstyle= 1
//	DrawText 66,85,"Click the start button below and this will be"
//	SetDrawEnv fstyle= 1
//	DrawText 86,115,"the first thing you are prompted to do."
//	Button startbutton0,pos={177,136},size={100,30},proc=StartButtonProc,title="Start DataPro"
//EndMacro

//Function StartButtonProc(ctrlName) : ButtonControl
//	String ctrlName
//	Execute "StartDataPro()"
//	DoWindow /K StartPanel
//End

Function MainConstructors()
	// Raise or create the three main windows used for data acquisition
	SamplerConstructor()
	DigitizerContConstructor()
	TestPulserContConstructor()
	SweeperContConstructor()
	BrowserContConstructor("NewOnlyIfNone")
End
