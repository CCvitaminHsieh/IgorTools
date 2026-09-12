#pragma rtGlobals=3    // Use modern global access method and strict wave access
#pragma IgorVersion = 6.37
// This is a beta version for coding practice.
//////////////////////////////////////////////////////////////////////////////
// 常數集中管理
//////////////////////////////////////////////////////////////////////////////
static strconstant kTmpFolder       = "root:tmpDirectory"
static strconstant kMergedWaveName  = "TracesMerged"
static strconstant kAxisWaveName    = "_axisInfo"
static strconstant kFirstTraceName  = "wave0"
static constant    kMaxSupportedDim = 2

//////////////////////////////////////////////////////////////////////////////
// 選單
//////////////////////////////////////////////////////////////////////////////
Menu "Data Browser Wave Import / Export"
	"Import csv files as experimental wave", DataImportAsWave()
	 help = {"Import data (*.csv) into Data Browser as a wave."}
	"Export wave to dat files", SelectWaveToExport()
	 help = {"Select and export a wave with (*.dat) extensions."}
End

//////////////////////////////////////////////////////////////////////////////
// GUI 層
//////////////////////////////////////////////////////////////////////////////

// 選擇要匯出的 wave，然後呼叫匯出流程
Function SelectWaveToExport()
	String anyWave
	Prompt anyWave, "Exported Wave:", popup Wavelist("*", ";", "")
	DoPrompt "Select and export a wave with (*.dat) extensions.", anyWave
	If (V_flag)
		Print "WaveExportToDatFormat Cancelled!!!"
		return -1
	EndIf
	WaveExportToDatFormat($anyWave)
End

// 匯入 CSV 檔並合併成一個 wave
Function DataImportAsWave()
	String outputPath = PopupFileDialog("wData", "Read", "")
	If (StrLen(outputPath) == 0)
		Print "DataImportAsWave Cancelled!!!"
		return -1
	EndIf
	ImportCsvToDataBrowser(outputPath)
End

//////////////////////////////////////////////////////////////////////////////
// IO 層
//////////////////////////////////////////////////////////////////////////////

// 從 CSV 載入並合併成單一 wave，最後搬到 root
Function ImportCsvToDataBrowser(String outputPath)
	String folderPath = kTmpFolder
	NewDataFolder/o $folderPath
	SetDataFolder $folderPath

	// 清空 tmp 資料夾，避免殘留 wave 影響計數
	KillWaves/A/Z
	KillStrings/A/Z

	LoadWave/o/a/d/g/k=0 outputPath
	Variable numLoaded = CountObjects(folderPath, 1)
	If (numLoaded <= 0)
		Print "ImportCsvToDataBrowser: LoadWave failed for " + outputPath
		KillDataFolder/z $folderPath
		SetDataFolder root:
		return -1
	EndIf

	Variable ok = MergeTracesToWave(numLoaded)
	If (ok != 0)
		Print "ImportCsvToDataBrowser: MergeTracesToWave failed"
		KillDataFolder/z $folderPath
		SetDataFolder root:
		return -1
	EndIf

	// 把合併後的 wave 搬到 root，並以原檔名命名
	String fileName = ParseFilePath(3, outputPath, ":", 0, 0)
	MoveWave $(folderPath + ":" + kMergedWaveName), root:

	// 若 root 已有同名 wave，先清掉再改名
	If (WaveExists($"root:" + fileName))
		KillWaves/Z $"root:" + fileName
	EndIf
	Rename $"root:" + kMergedWaveName, $"root:" + fileName

	KillDataFolder/z $folderPath
	SetDataFolder root:
End

// 將 wave 存成 .dat，並附帶一份 _axisInfo
Function WaveExportToDatFormat(Wave anyWave)
	// 產生軸資訊 wave（會放在當前資料夾）
	Variable axisStatus = GenWaveAxisInfo(anyWave)
	If (axisStatus != 0)
		Print "WaveExportToDatFormat: GenWaveAxisInfo failed"
		return -1
	EndIf

	// 先把 wAxis 改名成 _axisInfo，避免匯出時名稱衝突
	If (WaveExists($"wAxis"))
		Rename $"wAxis", $kAxisWaveName
	EndIf

	// 匯出主要資料
	Variable ok = ExportWaveAsDat(anyWave, "", "wData")
	If (ok != 0)
		Print "WaveExportToDatFormat: export main wave cancelled or failed"
		KillWaves/Z $kAxisWaveName
		return -1
	EndIf

	// 匯出軸資訊
	Wave axisInfo = $kAxisWaveName
	ok = ExportWaveAsDat(axisInfo, NameOfWave(anyWave), "wAxisInfo")
	If (ok != 0)
		Print "WaveExportToDatFormat: export axis info cancelled or failed"
		KillWaves/Z axisInfo
		return -1
	EndIf

	// 清理
	KillWaves/Z axisInfo
	DeleteGlobalVariables()
End

// 單一 wave 匯出為 .dat
Function ExportWaveAsDat(Wave anyWave, String prefix, String titleEvent)
	String datName
	Variable V_flag
	If (StrLen(prefix) == 0)
		Sprintf datName, "%s.dat", NameOfWave(anyWave)
	Else
		Sprintf datName, "%s%s.dat", prefix, NameOfWave(anyWave)
	EndIf

	String outputPath = PopupFileDialog(titleEvent, "Write", datName)
	If (StrLen(outputPath) == 0)
		return -1    // 使用者取消
	EndIf

	Save/j/o/m="\r\n" anyWave as outputPath
	If (V_flag != 0)
		Print "ExportWaveAsDat: Save failed for " + outputPath
		return -1
	EndIf
	return 0
End

//////////////////////////////////////////////////////////////////////////////
// 處理層
//////////////////////////////////////////////////////////////////////////////

// 把 wave0, wave1, ... 合併成一個 2D wave（或 1D，若只有一條）
Function MergeTracesToWave(Variable totalWaveNum)
	If (totalWaveNum <= 0)
		return -1
	EndIf

	If (!WaveExists($kFirstTraceName))
		Print "MergeTracesToWave: " + kFirstTraceName + " not found"
		return -1
	EndIf

	Wave wave0 = $kFirstTraceName
	Variable wavPts = DimSize(wave0, 0)

	// 建立合併後的 wave
	If (totalWaveNum == 1)
		Make/d/o/n=(wavPts) $kMergedWaveName
	Else
		Make/d/o/n=(wavPts, totalWaveNum) $kMergedWaveName
	EndIf
	Wave merged = $kMergedWaveName

	// 逐條 trace 填入
	Variable idx
	For (idx = 0; idx < totalWaveNum; idx += 1)
		String traceName = "wave" + Num2Str(idx)
		If (!WaveExists($traceName))
			Print "MergeTracesToWave: missing " + traceName
			continue
		EndIf
		Wave trace = $traceName
		If (totalWaveNum == 1)
			merged[] = trace[p][0]
		Else
			merged[][idx] = trace[p][0]
		EndIf
	EndFor

	return 0
End

// 由 wave 的維度資訊產生軸資訊（2 x 6 的文字 wave，轉置後為 6 x 2）
Function GenWaveAxisInfo(Wave anyWave)
	Variable dim = WaveDims(anyWave)
	If (dim > kMaxSupportedDim)
		Print "GenWaveAxisInfo: only 1D/2D waves are supported (got " + Num2Str(dim) + "D)"
		return -1
	EndIf

	Make/t/o/n=(2, 6) wAxis
	Variable r
	For (r = 0; r < dim; r += 1)
		If (StrLen(wAxis[r][0]) == 0)
			If (r == 0)
				wAxis[r][0] = "X"
			ElseIf (r == 1)
				wAxis[r][0] = "Y"
			EndIf
		EndIf
		wAxis[r][1] = ""                                          // quantity
		wAxis[r][2] = WaveUnits(anyWave, r)                       // unit
		wAxis[r][3] = Num2Str(DimOffset(anyWave, r))              // start
		wAxis[r][4] = Num2Str(DimOffset(anyWave, r) + (DimSize(anyWave, r) - 1) * DimDelta(anyWave, r))  // end
		wAxis[r][5] = Num2Str(DimDelta(anyWave, r))               // delta
	EndFor

	MatrixTranspose wAxis
	return 0
End

// 讀取 _axisInfo 並套用到指定 wave 的 scale
Function ImportAxisInfoToData(String fileName)
	String outputPath = PopupFileDialog("wAxisInfo", "Read", "")
	If (StrLen(outputPath) == 0)
		Print "ImportAxisInfo Cancelled!!!"
		return -1
	EndIf

	Variable bAddQuantToUnit = 0
	LoadWave/O/Q/A/J/D/W/K=0/V={","," $",1,0}/L={0,0,0,0,4} outputPath

	If (!WaveExists($"XW") || !WaveExists($"YW"))
		Print "ImportAxisInfoToData: failed to load axis waves from " + outputPath
		return -1
	EndIf

	Wave/T XW, YW
	ModifyXYScale($fileName, XW, YW, bAddQuantToUnit)

	KillWaves/Z XW, YW
	return 0
End

// 套用 X/Y 軸的 scale 與單位
Function ModifyXYScale(Wave targetWave, Wave/T xWave, Wave/T yWave, Variable bAddQuantToUnit)
	String xUnit, yUnit
	If (bAddQuantToUnit)
		Sprintf xUnit "%s (%s)", xWave[0], xWave[1]
		Sprintf yUnit "%s (%s)", yWave[0], yWave[1]
	Else
		Sprintf xUnit "%s", xWave[1]
		Sprintf yUnit "%s", yWave[1]
	EndIf
	SetScale/I x, Str2Num(xWave[2]), Str2Num(xWave[3]), xUnit, targetWave
	SetScale/I y, Str2Num(yWave[2]), Str2Num(yWave[3]), yUnit, targetWave
End

//////////////////////////////////////////////////////////////////////////////
// 共用工具
//////////////////////////////////////////////////////////////////////////////

// 檔案選擇對話框；Read 模式回傳選取路徑，Write 模式回傳使用者指定路徑
Function/S PopupFileDialog(String titleEvent, String ioHandle, String anyWaveToExport)
	String titleMsg = ""
	String fileFilters

	StrSwitch (ioHandle)
		Case "Read":
			StrSwitch (titleEvent)
				Case "wData":
					titleMsg = "Select a file for experiment data to continue"
					break
				Case "wScaleProperties":
					titleMsg = "Select a file with wScaleProperties to continue"
					break
				Case "wUnits":
					titleMsg = "Select a file with wUnits to continue"
					break
				Case "wAxisInfo":
					titleMsg = "Select a file with \"_axisInfo\" suffix to continue"
					break
			EndSwitch
			fileFilters = "Data Files (*.csv):.csv;"
			Open /D /R /F=fileFilters /M=titleMsg refNum
			break

		Case "Write":
			StrSwitch (titleEvent)
				Case "wData":
					titleMsg = "Export a \"Wave\" as dat extension to continue."
					break
				Case "wAxisInfo":
					titleMsg = "Export its \"_axisInfo\" as dat extension to continue."
					break
			EndSwitch
			fileFilters = "Data Files (*.dat):.dat;"
			Open /D /F=fileFilters /M=titleMsg refNum as anyWaveToExport
			break
	EndSwitch

	return S_fileName
End

// 清理暫時性的全域 wave / string
Function DeleteGlobalVariables()
	KillWaves/Z XW, YW
	KillWaves/Z wUnits
	KillStrings/Z outputPath
End