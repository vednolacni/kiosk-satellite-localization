Attribute VB_Name = "RandomReze"
'==============================================================================
' RandomReze - nakljucni izrezi (reze) za panelno ograjo
' SolidWorks VBA makro (SW 2014 ali novejsi)
'
' UPORABA
'   1. Odpri part s ploscho (pravokotnik centriran v izhodiscu, npr. 2876 x 680).
'   2. (neobvezno) Izberi ravno ploskev plosce ali ravnino, vzporedno s plosco.
'      Ce ni nic izbrano, makro skicira na prvi ravnini v drevesu (Front / Spredaj).
'   3. Tools > Macro > Run, potrdi ali spremeni parametre.
'
' Vse mere so v mm. Vzorec je centriran na izhodisce skice (sredisce gabarita).
' Reze so pravokotniki z zaobljenimi vogali (R). Ce je R = visina/2 -> polkrozni konci.
'
' NAMESTITEV
'   Tools > Macro > New... > shrani kot RandomReze.swp
'   V VBA urejevalniku: File > Import File... > RandomReze.bas
'   Izbrisi prazen modul "Module1" (ce obstaja) in shrani.
'==============================================================================
Option Explicit

' ---------- privzete vrednosti [mm] ----------
Private Const DEF_SIRINA As Double = 2876     ' gabarit plosce X
Private Const DEF_VISINA As Double = 680      ' gabarit plosce Y
Private Const DEF_ODMIK As Double = 40        ' min. odmik rez od vseh robov
Private Const DEF_H As Double = 10            ' visina reze
Private Const DEF_R As Double = 3             ' radij vogalov reze
Private Const DEF_RAZMIK As Double = 15       ' material med vrstami
Private Const DEF_LMIN As Double = 40         ' min. dolzina reze
Private Const DEF_LMAX As Double = 200        ' max. dolzina reze
Private Const DEF_GMIN As Double = 20         ' min. material med rezami v vrsti
Private Const DEF_GMAX As Double = 120        ' max. material med rezami v vrsti
Private Const DEF_PORAVNAJ As Long = 1        ' 1 = raven levi/desni rob vzorca, 0 = razgiban rob
Private Const DEF_SEME As Long = 0            ' 0 = nakljucno, >0 = ponovljiv vzorec
Private Const DEF_NACIN As Long = 1           ' 1 = hitro (crte + loki), 2 = pravokotnik + zaokrozitev
Private Const DEF_REZ As Long = 1             ' 1 = naredi Cut-Extrude skozi vse, 0 = samo skica

Private Const EPS As Double = 0.000001        ' [mm]
Private Const EPS_M As Double = 0.000000001   ' [m]

' ---------- parametri ----------
Private pW As Double, pH As Double, pM As Double
Private pSh As Double, pR As Double, pRow As Double
Private pLmin As Double, pLmax As Double, pGmin As Double, pGmax As Double
Private pAlign As Long, pSeed As Long, pMode As Long, pCut As Long

' ---------- generirane reze [mm]: center X, center Y, dolzina ----------
Private sX() As Double, sY() As Double, sL() As Double
Private sN As Long
Private nRows As Long

Private mCancel As Boolean

'==============================================================================
Sub main()
    Dim swApp As SldWorks.SldWorks
    Dim swModel As SldWorks.ModelDoc2
    Dim skMgr As SldWorks.SketchManager
    Dim swSketch As SldWorks.Sketch
    Dim swSketchFeat As SldWorks.Feature
    Dim swCutFeat As SldWorks.Feature
    Dim usedMode As Long
    Dim t As Single
    Dim msg As String

    Set swApp = Application.SldWorks
    Set swModel = swApp.ActiveDoc
    If swModel Is Nothing Then
        MsgBox "Ni odprtega dokumenta. Odpri part s plosco.", vbExclamation, "Random reze"
        Exit Sub
    End If
    If swModel.GetType <> 1 Then  ' swDocPART
        MsgBox "Makro deluje samo v partu (.sldprt).", vbExclamation, "Random reze"
        Exit Sub
    End If
    Set skMgr = swModel.SketchManager
    If Not skMgr.ActiveSketch Is Nothing Then
        MsgBox "Zapri odprto skico in pozeni makro znova.", vbExclamation, "Random reze"
        Exit Sub
    End If

    ' --- parametri ---
    SetDefaults
    If Not AskParams() Then Exit Sub
    If Not ValidateParams() Then Exit Sub

    ' --- seme nakljucnih stevil (vedno ponovljivo, da lahko vzorec ponovis) ---
    If pSeed <= 0 Then
        Randomize
        pSeed = 1 + Int(Rnd * 999999)
    End If
    Rnd -1
    Randomize pSeed

    ' --- generiraj vzorec ---
    GeneratePattern
    If sN = 0 Then
        MsgBox "Ni prostora za reze s temi parametri.", vbExclamation, "Random reze"
        Exit Sub
    End If

    ' --- ravnina skice ---
    If Not PrepareSketchPlane(swModel) Then Exit Sub

    t = Timer
    On Error GoTo ErrH

    skMgr.InsertSketch True
    Set swSketch = skMgr.ActiveSketch
    If swSketch Is Nothing Then
        MsgBox "Skice ni bilo mogoce odpreti na izbrani ploskvi/ravnini.", vbExclamation, "Random reze"
        Exit Sub
    End If
    Set swSketchFeat = swSketch

    usedMode = pMode
    DrawAll swModel, skMgr, usedMode
    skMgr.InsertSketch True             ' zapri skico

    On Error Resume Next
    swSketchFeat.Name = "Random reze"
    On Error GoTo ErrH

    If pCut = 1 Then
        Set swCutFeat = DoCut(swModel, swSketchFeat)

        ' Ce hitri nacin ne da zaprtih kontur -> samodejno ponovi z robustnim nacinom
        If swCutFeat Is Nothing And usedMode = 1 Then
            swModel.ClearSelection2 True
            swSketchFeat.Select2 False, 0
            swModel.EditSketch
            swModel.Extension.SelectAll
            swModel.EditDelete
            usedMode = 2
            DrawAll swModel, skMgr, usedMode
            skMgr.InsertSketch True
            Set swCutFeat = DoCut(swModel, swSketchFeat)
        End If
    End If

    swModel.ClearSelection2 True
    swModel.GraphicsRedraw2

    ' --- povzetek ---
    msg = "Narejeno v " & Format(Timer - t, "0.0") & " s" & vbCrLf & vbCrLf & _
          "Vrst: " & nRows & vbCrLf & _
          "Rez: " & sN & vbCrLf & _
          "Seme: " & pSeed & "  (vpisi ga za enak vzorec)" & vbCrLf & _
          "Nacin risanja: " & IIf(usedMode = 1, "hitro", "robustno") & vbCrLf & _
          SummaryText()
    If pCut = 1 Then
        If swCutFeat Is Nothing Then
            msg = msg & vbCrLf & vbCrLf & "POZOR: Cut-Extrude ni uspel. Skica 'Random reze' je ostala - " & _
                  "naredi rez rocno (Extruded Cut, Through All)."
        Else
            msg = msg & vbCrLf & vbCrLf & "Izrez: " & swCutFeat.Name
        End If
    End If
    MsgBox msg, vbInformation, "Random reze"
    Exit Sub

ErrH:
    On Error Resume Next
    skMgr.AddToDB = False
    skMgr.DisplayWhenAdded = True
    swModel.FeatureManager.EnableFeatureTree = True
    swModel.ActiveView.EnableGraphicsUpdate = True
    MsgBox "Napaka: " & Err.Description, vbCritical, "Random reze"
End Sub

'==============================================================================
' PARAMETRI
'==============================================================================
Private Sub SetDefaults()
    pW = DEF_SIRINA: pH = DEF_VISINA: pM = DEF_ODMIK
    pSh = DEF_H: pR = DEF_R: pRow = DEF_RAZMIK
    pLmin = DEF_LMIN: pLmax = DEF_LMAX: pGmin = DEF_GMIN: pGmax = DEF_GMAX
    pAlign = DEF_PORAVNAJ: pSeed = DEF_SEME: pMode = DEF_NACIN: pCut = DEF_REZ
End Sub

Private Function ParamText() As String
    ParamText = _
        "Plosca: " & F(pW) & " x " & F(pH) & vbCrLf & _
        "Min. odmik od robov: " & F(pM) & vbCrLf & _
        "Reza: visina " & F(pSh) & ", R" & F(pR) & vbCrLf & _
        "Dolzina reze: " & F(pLmin) & " - " & F(pLmax) & vbCrLf & _
        "Material med rezami v vrsti: " & F(pGmin) & " - " & F(pGmax) & vbCrLf & _
        "Material med vrstami: " & F(pRow) & vbCrLf & _
        "Raven levi/desni rob: " & IIf(pAlign = 1, "da", "ne") & vbCrLf & _
        "Seme: " & IIf(pSeed <= 0, "nakljucno", CStr(pSeed)) & vbCrLf & _
        "Nacin: " & IIf(pMode = 1, "1 hitro", "2 robustno") & vbCrLf & _
        "Cut-Extrude: " & IIf(pCut = 1, "da", "ne (samo skica)")
End Function

Private Function AskParams() As Boolean
    Dim ans As VbMsgBoxResult
    Do
        ans = MsgBox("Parametri [mm]:" & vbCrLf & vbCrLf & ParamText() & vbCrLf & vbCrLf & _
                     "Da = zazeni s temi vrednostmi" & vbCrLf & _
                     "Ne = spremeni vrednosti" & vbCrLf & _
                     "Preklici = izhod", vbYesNoCancel + vbQuestion, "Random reze")
        If ans = vbCancel Then Exit Function
        If ans = vbYes Then AskParams = True: Exit Function

        mCancel = False
        pW = AskNum("Sirina plosce X [mm]", pW)
        pH = AskNum("Visina plosce Y [mm]", pH)
        pM = AskNum("Min. odmik rez od vseh robov [mm]", pM)
        pSh = AskNum("Visina reze [mm]", pSh)
        pR = AskNum("Radij vogalov reze [mm]" & vbCrLf & "(0 = ostri vogali, visina/2 = polkrozni konci)", pR)
        pRow = AskNum("Material med vrstami [mm]", pRow)
        pLmin = AskNum("Min. dolzina reze [mm]", pLmin)
        pLmax = AskNum("Max. dolzina reze [mm]", pLmax)
        pGmin = AskNum("Min. material med rezami v vrsti [mm]", pGmin)
        pGmax = AskNum("Max. material med rezami v vrsti [mm]", pGmax)
        pAlign = CLng(AskNum("Raven levi/desni rob vzorca?" & vbCrLf & "1 = da (vse vrste od odmika do odmika)" & vbCrLf & "0 = ne (vrste centrirane, razgiban rob)", pAlign))
        pSeed = CLng(AskNum("Seme nakljucnih stevil" & vbCrLf & "0 = vsakic nov vzorec, npr. 1234 = vedno enak vzorec", pSeed))
        pMode = CLng(AskNum("Nacin risanja" & vbCrLf & "1 = hitro (crte + loki)" & vbCrLf & "2 = robustno (pravokotnik + sketch fillet, pocasneje)", pMode))
        pCut = CLng(AskNum("Naredi Cut-Extrude skozi vse?" & vbCrLf & "1 = da, 0 = samo skica", pCut))
        If mCancel Then Exit Function
    Loop
End Function

Private Function AskNum(prompt As String, def As Double) As Double
    Dim s As String
    AskNum = def
    If mCancel Then Exit Function
    s = InputBox(prompt, "Random reze", F(def))
    If StrPtr(s) = 0 Then mCancel = True: Exit Function   ' Cancel
    s = Trim$(Replace(s, ",", "."))
    If Len(s) > 0 Then AskNum = Val(s)
End Function

Private Function ValidateParams() As Boolean
    Dim e As String
    If pW <= 2 * pM Or pH <= 2 * pM Then e = e & "- Plosca je premajhna za izbrani odmik." & vbCrLf
    If pM < 0 Then e = e & "- Odmik ne sme biti negativen." & vbCrLf
    If pSh <= 0 Then e = e & "- Visina reze mora biti > 0." & vbCrLf
    If pSh > pH - 2 * pM Then e = e & "- Visina reze je vecja od uporabne visine." & vbCrLf
    If pR < 0 Then e = e & "- Radij ne sme biti negativen." & vbCrLf
    If pRow <= 0 Then e = e & "- Material med vrstami mora biti > 0." & vbCrLf
    If pLmin <= 0 Or pLmax < pLmin Then e = e & "- Preveri min/max dolzino reze." & vbCrLf
    If pGmin <= 0 Or pGmax < pGmin Then e = e & "- Preveri min/max material med rezami." & vbCrLf
    If pLmin > pW - 2 * pM Then e = e & "- Min. dolzina reze je vecja od uporabne sirine." & vbCrLf
    If pMode <> 1 And pMode <> 2 Then e = e & "- Nacin mora biti 1 ali 2." & vbCrLf
    If pAlign <> 0 Then pAlign = 1
    If pCut <> 0 Then pCut = 1

    If pR > pSh / 2 Then pR = pSh / 2          ' vec kot polkrog ni mogoce
    If pLmin < 2 * pR Then e = e & "- Min. dolzina reze mora biti >= 2 x R." & vbCrLf

    If Len(e) > 0 Then
        MsgBox "Napacni parametri:" & vbCrLf & vbCrLf & e, vbExclamation, "Random reze"
        Exit Function
    End If
    ValidateParams = True
End Function

' stevilo -> niz s piko kot decimalnim locilom
Private Function F(v As Double) As String
    F = Replace(CStr(Round(v, 3)), ",", ".")
End Function

'==============================================================================
' GENERIRANJE VZORCA (vse v mm, izhodisce = sredisce plosce)
'==============================================================================
Private Sub GeneratePattern()
    Dim wu As Double, hu As Double, pitch As Double
    Dim totH As Double, yTop As Double, r As Long

    wu = pW - 2 * pM
    hu = pH - 2 * pM
    pitch = pSh + pRow
    nRows = Int((hu + pRow) / pitch + EPS)
    sN = 0
    If nRows < 1 Then Exit Sub

    ReDim sX(0 To 511): ReDim sY(0 To 511): ReDim sL(0 To 511)

    ' vrste centrirane po visini
    totH = nRows * pSh + (nRows - 1) * pRow
    yTop = totH / 2 - pSh / 2
    For r = 0 To nRows - 1
        GenerateRow -wu / 2, wu, yTop - r * pitch
    Next r
End Sub

Private Sub GenerateRow(xmin As Double, wu As Double, yc As Double)
    Dim st() As Double, ln() As Double, n As Long, i As Long
    Dim pos As Double, L As Double, G As Double, remain As Double, lFit As Double
    Dim extra As Double

    ReDim st(0 To 63): ReDim ln(0 To 63)
    pos = 0: n = 0
    Do
        L = RandBetween(pLmin, pLmax)
        If n = 0 Then G = 0 Else G = RandBetween(pGmin, pGmax)
        If pos + G + L > wu + EPS Then
            ' ne gre vec - poskusi zapolniti ostanek z min. presledkom
            If n = 0 Then G = 0 Else G = pGmin
            remain = wu - pos - G
            If remain < pLmin - EPS Then Exit Do
            lFit = remain
            If lFit > pLmax Then lFit = pLmax
            L = RandBetween(pLmin, lFit)
        End If
        If n > UBound(st) Then
            ReDim Preserve st(0 To 2 * n): ReDim Preserve ln(0 To 2 * n)
        End If
        st(n) = pos + G
        ln(n) = L
        pos = st(n) + L
        n = n + 1
    Loop
    If n = 0 Then Exit Sub

    extra = wu - pos      ' preostanek (< min presledek + min dolzina)
    If pAlign = 1 And n > 1 Then
        ' raztegni presledke, da vrsta sega tocno od odmika do odmika
        For i = 1 To n - 1
            st(i) = st(i) + extra * i / (n - 1)
        Next i
    Else
        ' centriraj vrsto
        For i = 0 To n - 1
            st(i) = st(i) + extra / 2
        Next i
    End If

    For i = 0 To n - 1
        AddSlot xmin + st(i) + ln(i) / 2, yc, ln(i)
    Next i
End Sub

Private Sub AddSlot(xc As Double, yc As Double, L As Double)
    If sN > UBound(sX) Then
        ReDim Preserve sX(0 To 2 * sN)
        ReDim Preserve sY(0 To 2 * sN)
        ReDim Preserve sL(0 To 2 * sN)
    End If
    sX(sN) = xc: sY(sN) = yc: sL(sN) = L
    sN = sN + 1
End Sub

Private Function RandBetween(a As Double, b As Double) As Double
    RandBetween = a + Rnd * (b - a)
End Function

Private Function SummaryText() As String
    Dim i As Long, x0 As Double, x1 As Double, y0 As Double, y1 As Double
    Dim area As Double, cornerLoss As Double
    x0 = 1E+30: x1 = -1E+30: y0 = 1E+30: y1 = -1E+30
    cornerLoss = (4 - 3.14159265358979) * pR * pR
    For i = 0 To sN - 1
        If sX(i) - sL(i) / 2 < x0 Then x0 = sX(i) - sL(i) / 2
        If sX(i) + sL(i) / 2 > x1 Then x1 = sX(i) + sL(i) / 2
        If sY(i) - pSh / 2 < y0 Then y0 = sY(i) - pSh / 2
        If sY(i) + pSh / 2 > y1 Then y1 = sY(i) + pSh / 2
        area = area + sL(i) * pSh - cornerLoss
    Next i
    SummaryText = "Gabarit vzorca: " & F(x1 - x0) & " x " & F(y1 - y0) & vbCrLf & _
                  "Odmik levo/desno: " & F(x0 + pW / 2) & " / " & F(pW / 2 - x1) & vbCrLf & _
                  "Odmik spodaj/zgoraj: " & F(y0 + pH / 2) & " / " & F(pH / 2 - y1) & vbCrLf & _
                  "Odprtost plosce: " & Format(100 * area / (pW * pH), "0.0") & " %"
End Function

'==============================================================================
' SOLIDWORKS
'==============================================================================
Private Function PrepareSketchPlane(swModel As SldWorks.ModelDoc2) As Boolean
    Dim selMgr As SldWorks.SelectionMgr
    Dim feat As SldWorks.Feature
    Dim tp As Long

    Set selMgr = swModel.SelectionManager
    If selMgr.GetSelectedObjectCount2(-1) >= 1 Then
        tp = selMgr.GetSelectedObjectType3(1, -1)
        If tp = 2 Or tp = 4 Then        ' swSelFACES, swSelDATUMPLANES
            PrepareSketchPlane = True
            Exit Function
        End If
    End If

    ' nic izbrano -> prva ravnina v drevesu (Front / Spredaj), neodvisno od jezika
    swModel.ClearSelection2 True
    Set feat = swModel.FirstFeature
    Do While Not feat Is Nothing
        If feat.GetTypeName2 = "RefPlane" Then
            PrepareSketchPlane = feat.Select2(False, 0)
            Exit Function
        End If
        Set feat = feat.GetNextFeature
    Loop
    MsgBox "Ni ravnine za skico. Izberi ploskev ali ravnino in pozeni znova.", vbExclamation, "Random reze"
End Function

Private Sub DrawAll(swModel As SldWorks.ModelDoc2, skMgr As SldWorks.SketchManager, mode As Long)
    Dim i As Long, h As Double, r As Double
    Dim view As Object

    h = pSh / 1000#
    r = pR / 1000#

    Set view = swModel.ActiveView
    If Not view Is Nothing Then view.EnableGraphicsUpdate = False
    swModel.FeatureManager.EnableFeatureTree = False
    skMgr.AddToDB = True              ' brez snapanja / avtomatskih relacij
    skMgr.DisplayWhenAdded = False

    For i = 0 To sN - 1
        If mode = 1 Then
            DrawSlotFast skMgr, sX(i) / 1000#, sY(i) / 1000#, sL(i) / 1000#, h, r
        Else
            DrawSlotSafe swModel, skMgr, sX(i) / 1000#, sY(i) / 1000#, sL(i) / 1000#, h, r
        End If
    Next i

    skMgr.AddToDB = False
    skMgr.DisplayWhenAdded = True
    swModel.FeatureManager.EnableFeatureTree = True
    If Not view Is Nothing Then view.EnableGraphicsUpdate = True
    swModel.ClearSelection2 True
End Sub

' Nacin 1: 4 crte + 4 loki (tocno enake koordinate krajisc)  [m]
Private Sub DrawSlotFast(skMgr As SldWorks.SketchManager, xc As Double, yc As Double, _
                         L As Double, h As Double, r As Double)
    Dim x1 As Double, x2 As Double, y1 As Double, y2 As Double
    Dim xa As Double, xb As Double, ya As Double, yb As Double
    Dim hasH As Boolean, hasV As Boolean

    x1 = xc - L / 2: x2 = xc + L / 2
    y1 = yc - h / 2: y2 = yc + h / 2

    If r <= EPS_M Then
        skMgr.CreateLine x1, y1, 0, x2, y1, 0
        skMgr.CreateLine x2, y1, 0, x2, y2, 0
        skMgr.CreateLine x2, y2, 0, x1, y2, 0
        skMgr.CreateLine x1, y2, 0, x1, y1, 0
        Exit Sub
    End If

    xa = x1 + r: xb = x2 - r
    ya = y1 + r: yb = y2 - r
    hasH = (xb - xa > EPS_M)
    hasV = (yb - ya > EPS_M)
    If Not hasH Then xa = xc: xb = xc
    If Not hasV Then ya = yc: yb = yc

    If hasH Then skMgr.CreateLine xa, y1, 0, xb, y1, 0           ' spodaj
    skMgr.CreateArc xb, ya, 0, xb, y1, 0, x2, ya, 0, 1           ' spodaj desno
    If hasV Then skMgr.CreateLine x2, ya, 0, x2, yb, 0           ' desno
    skMgr.CreateArc xb, yb, 0, x2, yb, 0, xb, y2, 0, 1           ' zgoraj desno
    If hasH Then skMgr.CreateLine xb, y2, 0, xa, y2, 0           ' zgoraj
    skMgr.CreateArc xa, yb, 0, xa, y2, 0, x1, yb, 0, 1           ' zgoraj levo
    If hasV Then skMgr.CreateLine x1, yb, 0, x1, ya, 0           ' levo
    skMgr.CreateArc xa, ya, 0, x1, ya, 0, xa, y1, 0, 1           ' spodaj levo
End Sub

' Nacin 2: corner rectangle + sketch fillet (ali slot pri R = h/2)  [m]
Private Sub DrawSlotSafe(swModel As SldWorks.ModelDoc2, skMgr As SldWorks.SketchManager, _
                         xc As Double, yc As Double, L As Double, h As Double, r As Double)
    Dim v As Variant, i As Long, k As Long, j As Long, nP As Long
    Dim seg As SldWorks.SketchSegment, ln As SldWorks.SketchLine
    Dim pts(1 To 8) As SldWorks.SketchPoint, p As SldWorks.SketchPoint
    Dim dup As Boolean

    If r >= h / 2 - EPS_M Then
        ' polkrozni konci -> standardni slot (center-center)
        skMgr.CreateSketchSlot 0, 0, h, xc - (L - h) / 2, yc, 0, xc + (L - h) / 2, yc, 0, 0, 0, 0, 1, False
        Exit Sub
    End If

    v = skMgr.CreateCornerRectangle(xc - L / 2, yc - h / 2, 0, xc + L / 2, yc + h / 2, 0)
    If r <= EPS_M Then Exit Sub
    If IsEmpty(v) Then Exit Sub

    ' zberi 4 unikatne vogalne tocke
    nP = 0
    For i = LBound(v) To UBound(v)
        Set seg = v(i)
        If seg.GetType = 0 Then                 ' swSketchLINE
            Set ln = seg
            For k = 0 To 1
                If k = 0 Then Set p = ln.GetStartPoint2 Else Set p = ln.GetEndPoint2
                dup = False
                For j = 1 To nP
                    If Abs(pts(j).X - p.X) < EPS_M And Abs(pts(j).Y - p.Y) < EPS_M Then dup = True: Exit For
                Next j
                If Not dup And nP < 8 Then nP = nP + 1: Set pts(nP) = p
            Next k
        End If
    Next i

    swModel.ClearSelection2 True
    For j = 1 To nP
        pts(j).Select4 True, Nothing
    Next j
    skMgr.CreateFillet r, 1                     ' swConstrainedCornerKeepGeometry
    swModel.ClearSelection2 True
End Sub

Private Function DoCut(swModel As SldWorks.ModelDoc2, sketchFeat As SldWorks.Feature) As SldWorks.Feature
    swModel.ClearSelection2 True
    sketchFeat.Select2 False, 0
    ' Extruded Cut, Through All v obe smeri (deluje ne glede na stran skice)
    Set DoCut = swModel.FeatureManager.FeatureCut4( _
        False, False, False, 1, 1, 0.01, 0.01, _
        False, False, False, False, 0, 0, _
        False, False, False, False, _
        False, True, True, True, True, False, _
        0, 0, False, False)
End Function
