Attribute VB_Name = "RandomReze"
'==============================================================================
' RandomReze - nakljucni izrezi (reze) za panelno ograjo
' SolidWorks VBA makro (SW 2014 ali novejsi)
'
' OBLIKA PLOSCE - makro jo vzame iz tega, kar je izbrano ob zagonu:
'   a) ravna PLOSKEV plosce -> reze znotraj obrisa ploskve (poljubna oblika,
'      npr. ograja ob stopniscu; obstojece luknje se upostevajo)
'   b) SKICA obrisa (izbrana v drevesu, izbran njen rob ali odprta skica)
'      -> reze znotraj obrisa skice (pomozne / construction crte se ne upostevajo)
'   c) nic ali ravnina -> vpises sirino in visino (pravokotnik centriran v izhodiscu)
'
' SMER REZ:  0 = vodoravno, A = vzporedno z najdaljsim ravnim robom,
'            S = sledi obliki (vsaka reza v smeri najblizjega dolgega roba),
'            ali poljuben kot v stopinjah.
'
' Ob zagonu najprej izberes GOSTOTO (1 zelo zaprto ... 5 zelo odprto, 6 po meri).
' Razporeditev 1 (privzeto): reze prosto razmetane do ciljne odprtosti.
' Razporeditev 2: vrste (enotna smer), vsaka z nakljucnim zamikom na robu.
' Reze so pravokotniki z zaobljenimi vogali (R). Ce je R = visina/2 -> polkrozni konci.
'
' NAMESTITEV
'   Tools > Macro > New... > shrani kot RandomReze.swp
'   V VBA urejevalniku: File > Import File... > RandomReze.bas
'   Izbrisi prazen modul "Module1" (ce obstaja) in shrani.
'==============================================================================
Option Explicit

' ---------- privzete vrednosti [mm] ----------
Private Const DEF_SIRINA As Double = 2876     ' plosca X (samo ce ni izbrana ploskev/skica)
Private Const DEF_VISINA As Double = 680      ' plosca Y (samo ce ni izbrana ploskev/skica)
Private Const DEF_ODMIK As Double = 40        ' min. odmik rez od vseh robov
Private Const DEF_H As Double = 10            ' visina reze
Private Const DEF_R As Double = 3             ' radij vogalov reze
Private Const DEF_KOT As String = "0"         ' smer rez: "0", "A", "S" ali kot v stopinjah
Private Const DEF_RAZPORED As Long = 1        ' 1 = prosto (nakljucno razmetano), 2 = v vrstah
Private Const DEF_GOSTOTA As Long = 3         ' 1 zelo zaprto, 2 zaprto, 3 srednje, 4 odprto, 5 zelo odprto, 6 po meri
Private Const DEF_ODPRTOST As Double = 13     ' ciljna odprtost plosce [%] (za 6 = po meri)
Private Const DEF_RAZMIK As Double = 10       ' min. material nad/pod rezo
Private Const DEF_LMIN As Double = 40         ' min. dolzina reze
Private Const DEF_LMAX As Double = 220        ' max. dolzina reze
Private Const DEF_GMIN As Double = 25         ' min. material levo/desno med rezami
Private Const DEF_GMAX As Double = 120        ' max. material med rezami v vrsti (samo vrste)
Private Const DEF_ROB As Double = 150         ' max. nakljucni zamik vrste na robu (samo vrste, 0 = raven rob)
Private Const DEF_SEME As Long = 0            ' 0 = nakljucno, >0 = ponovljiv vzorec
Private Const DEF_NACIN As Long = 1           ' 1 = hitro (crte + loki), 2 = pravokotnik + zaokrozitev
Private Const DEF_REZ As Long = 1             ' 1 = naredi Cut-Extrude skozi vse, 0 = samo skica

' ---------- notranje nastavitve ----------
Private Const EPS As Double = 0.000001        ' [mm]
Private Const EPS_M As Double = 0.000000001   ' [m]
Private Const PI As Double = 3.14159265358979
Private Const K_CAND As Long = 12             ' prosto: kandidatov na rezo (vec = bolj enakomerno)
Private Const V_SCALE As Double = 4           ' prosto: utez navpicnega razmika pri izbiri kandidata
Private Const MAX_FAILS As Long = 300         ' prosto: zaporednih neuspelih poskusov -> konec
Private Const ARC_STEP_DEG As Double = 5      ' razdelitev lokov obrisa skice
Private Const EDGE_SEGS As Long = 48          ' razdelitev krivih robov ploskve
Private Const SCAN_STEP As Double = 2         ' [mm] korak iskanja prostora v vrsti
Private Const SCAN_LINES As Long = 800        ' natancnost izracuna povrsine
Private Const LONG_EDGE As Double = 0.5       ' S: "dolg" rob = vsaj 50 % najdaljsega ravnega roba

' ---------- parametri ----------
Private pW As Double, pH As Double, pM As Double
Private pSh As Double, pR As Double, pRow As Double
Private pLmin As Double, pLmax As Double, pGmin As Double, pGmax As Double
Private pLayout As Long, pTarget As Double, pDensity As Long
Private pEdge As Double, pSeed As Long, pMode As Long, pCut As Long
Private pAngMode As Long, pAngDeg As Double     ' pAngMode: 0 = kot, 1 = A, 2 = S

' ---------- oblika (obris) v koordinatah ciljne skice [mm] ----------
Private gSrc As Long                            ' 1 = vpisane mere, 2 = ploskev, 3 = skica
Private gSrcName As String
Private gMath As SldWorks.MathUtility
Private rAx() As Double, rAy() As Double, rBx() As Double, rBy() As Double
Private rLine() As Boolean
Private rN As Long
Private bMinX As Double, bMaxX As Double, bMinY As Double, bMaxY As Double
Private gArea As Double, gPerim As Double, gLongLen As Double, gLongAng As Double

' ---------- reze: center, dolzina, kot (koordinate skice) [mm, rad] ----------
Private sX() As Double, sY() As Double, sL() As Double, sA() As Double
Private sN As Long
Private nRows As Long, pRowUsed As Double, gRowAng As Double
Private gOpen As Double, gMinDist As Double, gAngNote As String
Private mCancel As Boolean

' trenutni okvir reze pri risanju
Private dCx As Double, dCy As Double, dCos As Double, dSin As Double

'==============================================================================
Sub main()
    Dim swApp As SldWorks.SldWorks
    Dim swModel As SldWorks.ModelDoc2
    Dim skMgr As SldWorks.SketchManager
    Dim selMgr As SldWorks.SelectionMgr
    Dim srcFace As SldWorks.Face2
    Dim srcSketch As SldWorks.Sketch
    Dim tgtSketch As SldWorks.Sketch
    Dim tgtFeat As SldWorks.Feature
    Dim swCutFeat As SldWorks.Feature
    Dim xf As SldWorks.MathTransform
    Dim usedMode As Long, unsup As Long
    Dim t0 As Single
    Dim msg As String, cutNote As String
    Dim ok As Boolean

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
    Set selMgr = swModel.SelectionManager
    Set gMath = swApp.GetMathUtility
    On Error GoTo ErrH

    ' ---------- 1. od kod vzamemo obliko ----------
    gSrc = 1: gSrcName = "vpisane mere"
    If Not skMgr.ActiveSketch Is Nothing Then
        Set srcSketch = skMgr.ActiveSketch
        gSrc = 3: gSrcName = "skica " & SketchName(srcSketch)
        skMgr.InsertSketch True              ' zapri skico, iz nje beremo obris
    ElseIf selMgr.GetSelectedObjectCount2(-1) >= 1 Then
        Select Case selMgr.GetSelectedObjectType3(1, -1)
            Case 2                            ' swSelFACES
                Set srcFace = selMgr.GetSelectedObject6(1, -1)
                If Not srcFace.GetSurface.IsPlane Then
                    MsgBox "Izbrana ploskev ni ravna. Izberi ravno celno ploskev plosce.", vbExclamation, "Random reze"
                    Exit Sub
                End If
                gSrc = 2: gSrcName = "izbrana ploskev"
            Case 9, 10                        ' swSelSKETCHES, swSelSKETCHSEGS
                Set srcSketch = SelectedSketch(selMgr)
                If srcSketch Is Nothing Then
                    MsgBox "Izbrane skice ni bilo mogoce prebrati.", vbExclamation, "Random reze"
                    Exit Sub
                End If
                gSrc = 3: gSrcName = "skica " & SketchName(srcSketch)
        End Select
    End If

    ' ---------- 2. ciljna skica za reze ----------
    Select Case gSrc
        Case 2: ok = SelectEntity(srcFace)
        Case 3: ok = SelectSketchPlane(swModel, srcSketch)
        Case Else: ok = PrepareSketchPlane(swModel)
    End Select
    If Not ok Then
        MsgBox "Ravnine za skico ni bilo mogoce izbrati." & vbCrLf & _
               "Izberi ravno ploskev plosce in pozeni znova.", vbExclamation, "Random reze"
        Exit Sub
    End If
    skMgr.InsertSketch True
    Set tgtSketch = skMgr.ActiveSketch
    If tgtSketch Is Nothing Then
        MsgBox "Skice ni bilo mogoce odpreti.", vbExclamation, "Random reze"
        Exit Sub
    End If
    Set tgtFeat = tgtSketch
    Set xf = tgtSketch.ModelToSketchTransform

    ' ---------- 3. preberi obris ----------
    ResetRegion
    If gSrc = 2 Then
        ok = ReadFaceRegion(srcFace, xf)
    ElseIf gSrc = 3 Then
        ok = ReadSketchRegion(srcSketch, xf, unsup)
        If ok And unsup > 0 Then
            MsgBox "Skica vsebuje elemente, ki jih makro ne zna prebrati (elipsa, spline ...)." & vbCrLf & _
                   "Izberi raje ravno ploskev plosce.", vbExclamation, "Random reze"
            AbortSketch swModel, skMgr, tgtFeat
            Exit Sub
        End If
        If ok Then ok = RegionClosed()
    Else
        ok = True
    End If
    If Not ok Then
        MsgBox "Obris ni zaprt ali ga ni bilo mogoce prebrati." & vbCrLf & _
               "Skica mora biti en zaprt obris (pomozne crte so dovoljene).", vbExclamation, "Random reze"
        AbortSketch swModel, skMgr, tgtFeat
        Exit Sub
    End If
    If gSrc <> 1 Then RegionStats

    ' ---------- 4. parametri ----------
    SetDefaults
    If Not AskDensity() Then AbortSketch swModel, skMgr, tgtFeat: Exit Sub
    If Not AskParams() Then AbortSketch swModel, skMgr, tgtFeat: Exit Sub
    If Not ValidateParams() Then AbortSketch swModel, skMgr, tgtFeat: Exit Sub
    If gSrc = 1 Then BuildRegionTyped: RegionStats

    ' seme nakljucnih stevil (vedno ponovljivo)
    If pSeed <= 0 Then
        Randomize
        pSeed = 1 + Int(Rnd * 999999)
    End If
    Rnd -1
    Randomize pSeed

    ' ---------- 5. generiraj vzorec ----------
    GeneratePattern
    If sN = 0 Then
        MsgBox "Ni prostora za reze s temi parametri.", vbExclamation, "Random reze"
        AbortSketch swModel, skMgr, tgtFeat
        Exit Sub
    End If
    ComputeStats

    ' ---------- 6. risanje ----------
    t0 = Timer
    usedMode = pMode
    DrawAll swModel, skMgr, usedMode
    skMgr.InsertSketch True                  ' zapri skico
    On Error Resume Next
    tgtFeat.Name = "Random reze"
    On Error GoTo ErrH

    ' ---------- 7. izrez ----------
    If pCut = 1 Then
        If Not HasBody(swModel) Then
            cutNote = "V partu ni telesa - izvleci plosco in naredi Extruded Cut iz skice 'Random reze'."
        Else
            Set swCutFeat = DoCut(swModel, tgtFeat)
            ' Ce hitri nacin ne da zaprtih kontur -> samodejno ponovi z robustnim nacinom
            If swCutFeat Is Nothing And usedMode = 1 Then
                swModel.ClearSelection2 True
                tgtFeat.Select2 False, 0
                swModel.EditSketch
                swModel.Extension.SelectAll
                swModel.EditDelete
                usedMode = 2
                DrawAll swModel, skMgr, usedMode
                skMgr.InsertSketch True
                Set swCutFeat = DoCut(swModel, tgtFeat)
            End If
            If swCutFeat Is Nothing Then
                cutNote = "POZOR: Cut-Extrude ni uspel. Skica 'Random reze' je ostala - " & _
                          "naredi rez rocno (Extruded Cut, Through All)."
            Else
                cutNote = "Izrez: " & swCutFeat.Name
            End If
        End If
    End If

    swModel.ClearSelection2 True
    swModel.GraphicsRedraw2

    ' ---------- 8. povzetek ----------
    msg = "Narejeno v " & Format(Timer - t0, "0.0") & " s" & vbCrLf & vbCrLf & _
          "Gostota: " & DensityName() & vbCrLf & _
          IIf(pLayout = 1, "Razporeditev: prosto", "Vrst: " & nRows & " (razmik " & F(pRowUsed) & ")") & vbCrLf & _
          "Rez: " & sN & vbCrLf & _
          "Seme: " & pSeed & "  (vpisi ga za enak vzorec)" & vbCrLf & _
          "Nacin risanja: " & IIf(usedMode = 1, "hitro", "robustno") & vbCrLf & _
          SummaryText()
    If gOpen < pTarget - 0.5 Then
        msg = msg & vbCrLf & vbCrLf & "Ciljna odprtost " & F(pTarget) & " % ni dosezena - plosca je polna. " & _
              "Za bolj odprto ograjo zmanjsaj min. material med rezami ali izberi gostoto 5."
    End If
    If Len(gAngNote) > 0 Then msg = msg & vbCrLf & vbCrLf & gAngNote
    If Len(cutNote) > 0 Then msg = msg & vbCrLf & vbCrLf & cutNote
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
    pLayout = DEF_RAZPORED: pTarget = DEF_ODPRTOST: pDensity = DEF_GOSTOTA
    pEdge = DEF_ROB: pSeed = DEF_SEME: pMode = DEF_NACIN: pCut = DEF_REZ
    ParseAngle DEF_KOT
End Sub

Private Function ShapeText() As String
    If gSrc = 1 Then
        ShapeText = "Plosca: " & F(pW) & " x " & F(pH) & " (vpisane mere, centrirano v izhodiscu)"
    Else
        ShapeText = "Oblika: " & gSrcName & vbCrLf & _
                    "   gabarit " & F(bMaxX - bMinX) & " x " & F(bMaxY - bMinY) & _
                    ", povrsina " & Format(gArea / 1000000#, "0.000") & " m2"
    End If
End Function

Private Function ParamText() As String
    ParamText = _
        ShapeText() & vbCrLf & _
        "Min. odmik od robov: " & F(pM) & vbCrLf & _
        "Reza: visina " & F(pSh) & ", R" & F(pR) & vbCrLf & _
        "Dolzina reze: " & F(pLmin) & " - " & F(pLmax) & vbCrLf & _
        "Smer rez: " & AngleText() & vbCrLf & _
        "Gostota: " & DensityName() & ", ciljna odprtost " & F(pTarget) & " %" & vbCrLf & _
        "Razporeditev: " & IIf(pLayout = 1, "1 prosto", "2 v vrstah") & vbCrLf & _
        "Min. material levo/desno: " & F(pGmin) & IIf(pLayout = 2, " (max " & F(pGmax) & ")", "") & vbCrLf & _
        "Min. material zgoraj/spodaj: " & F(pRow) & vbCrLf & _
        IIf(pLayout = 2, "Nakljucni zamik na robu: 0 - " & F(pEdge) & vbCrLf, "") & _
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
        If gSrc = 1 Then
            pW = AskNum("Sirina plosce X [mm]", pW)
            pH = AskNum("Visina plosce Y [mm]", pH)
        End If
        pM = AskNum("Min. odmik rez od vseh robov [mm]", pM)
        pSh = AskNum("Visina reze [mm]", pSh)
        pR = AskNum("Radij vogalov reze [mm]" & vbCrLf & "(0 = ostri vogali, visina/2 = polkrozni konci)", pR)
        pLmin = AskNum("Min. dolzina reze [mm]", pLmin)
        pLmax = AskNum("Max. dolzina reze [mm]", pLmax)
        AskAngle
        pLayout = CLng(AskNum("Razporeditev" & vbCrLf & "1 = prosto (nakljucno razmetano)" & vbCrLf & "2 = v vrstah", pLayout))
        pGmin = AskNum("Min. material levo/desno med rezami [mm]", pGmin)
        pRow = AskNum("Min. material zgoraj/spodaj med rezami [mm]", pRow)
        pTarget = AskNum("Ciljna odprtost plosce [%]" & vbCrLf & "manj = bolj zaprta ograja (npr. 5), vec = bolj odprta (npr. 20)", pTarget)
        If pLayout = 2 Then
            pGmax = AskNum("Max. material med rezami v vrsti [mm]", pGmax)
            pEdge = AskNum("Max. nakljucni zamik vrste od roba [mm]" & vbCrLf & "Vsaka vrsta se zacne/konca nakljucno 0 - X mm za odmikom." & vbCrLf & "0 = raven rob", pEdge)
        End If
        pSeed = CLng(AskNum("Seme nakljucnih stevil" & vbCrLf & "0 = vsakic nov vzorec, npr. 1234 = vedno enak vzorec", pSeed))
        pMode = CLng(AskNum("Nacin risanja" & vbCrLf & "1 = hitro (crte + loki)" & vbCrLf & "2 = robustno (pravokotnik + sketch fillet, pocasneje)", pMode))
        pCut = CLng(AskNum("Naredi Cut-Extrude skozi vse?" & vbCrLf & "1 = da, 0 = samo skica", pCut))
        If mCancel Then Exit Function
    Loop
End Function

' Izbira gostote vzorca (kako odprta je ograja)
Private Function AskDensity() As Boolean
    Dim s As String, v As Long
    Do
        s = InputBox("Gostota vzorca - kako odprta naj bo ograja?" & vbCrLf & vbCrLf & _
            "1 = zelo zaprto  (~5 % odprtosti, malo rez)" & vbCrLf & _
            "2 = zaprto  (~9 %)" & vbCrLf & _
            "3 = srednje  (~13 %)" & vbCrLf & _
            "4 = odprto  (~18 %)" & vbCrLf & _
            "5 = zelo odprto  (~23 %, razmiki zmanjsani na 18 / 8 mm)" & vbCrLf & _
            "6 = po meri (vpises % odprtosti)", "Random reze - gostota", CStr(pDensity))
        If StrPtr(s) = 0 Then Exit Function          ' Cancel
        v = CLng(Val(Trim$(s)))
        If v >= 1 And v <= 6 Then Exit Do
        MsgBox "Vpisi stevilko od 1 do 6.", vbExclamation, "Random reze"
    Loop

    pDensity = v
    Select Case v
        Case 1: pTarget = 5
        Case 2: pTarget = 9
        Case 3: pTarget = 13
        Case 4: pTarget = 18
        Case 5
            pTarget = 23
            If pGmin > 18 Then pGmin = 18           ' sicer se 23 % ne da doseci
            If pRow > 8 Then pRow = 8
        Case 6
            mCancel = False
            pTarget = AskNum("Ciljna odprtost plosce [%]" & vbCrLf & _
                "Pri razmikih 25 / 10 mm je prosto mozno do ~20 %.", pTarget)
            If mCancel Then Exit Function
    End Select
    AskDensity = True
End Function

Private Function DensityName() As String
    Dim names As Variant, std As Variant
    names = Array("", "zelo zaprto", "zaprto", "srednje", "odprto", "zelo odprto")
    std = Array(0, 5, 9, 13, 18, 23)
    If pDensity >= 1 And pDensity <= 5 Then
        If Abs(std(pDensity) - pTarget) < EPS Then DensityName = pDensity & " " & names(pDensity): Exit Function
    End If
    DensityName = "po meri"
End Function

Private Sub AskAngle()
    Dim s As String
    If mCancel Then Exit Sub
    s = InputBox("Smer rez" & vbCrLf & vbCrLf & _
                 "0 = vodoravno" & vbCrLf & _
                 "A = vzporedno z najdaljsim ravnim robom" & vbCrLf & _
                 "S = sledi obliki: vsaka reza v smeri najblizjega dolgega roba" & vbCrLf & _
                 "      (npr. ograja z vodoravnim in posevnim delom ob stopniscu)" & vbCrLf & _
                 "ali poljuben kot v stopinjah, npr. 32", "Random reze", AngleCode())
    If StrPtr(s) = 0 Then mCancel = True: Exit Sub
    If Len(Trim$(s)) > 0 Then ParseAngle s
End Sub

Private Sub ParseAngle(ByVal s As String)
    s = UCase$(Trim$(Replace(s, ",", ".")))
    If s = "A" Then
        pAngMode = 1
    ElseIf s = "S" Then
        pAngMode = 2
    Else
        pAngMode = 0: pAngDeg = Val(s)
    End If
End Sub

Private Function AngleCode() As String
    Select Case pAngMode
        Case 1: AngleCode = "A"
        Case 2: AngleCode = "S"
        Case Else: AngleCode = F(pAngDeg)
    End Select
End Function

Private Function AngleText() As String
    Select Case pAngMode
        Case 1: AngleText = "A (vzporedno z najdaljsim robom)"
        Case 2: AngleText = "S (sledi obliki)"
        Case Else
            If Abs(pAngDeg) < EPS Then AngleText = "0 (vodoravno)" Else AngleText = F(pAngDeg) & " st."
    End Select
End Function

Private Function AskNum(prompt As String, ByVal def As Double) As Double
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
    If gSrc = 1 Then
        If pW <= 2 * pM Or pH <= 2 * pM Then e = e & "- Plosca je premajhna za izbrani odmik." & vbCrLf
        If pSh > pH - 2 * pM Then e = e & "- Visina reze je vecja od uporabne visine." & vbCrLf
        If pLmin > pW - 2 * pM Then e = e & "- Min. dolzina reze je vecja od uporabne sirine." & vbCrLf
    End If
    If pM < 0 Then e = e & "- Odmik ne sme biti negativen." & vbCrLf
    If pSh <= 0 Then e = e & "- Visina reze mora biti > 0." & vbCrLf
    If pR < 0 Then e = e & "- Radij ne sme biti negativen." & vbCrLf
    If pRow <= 0 Then e = e & "- Material zgoraj/spodaj mora biti > 0." & vbCrLf
    If pLayout <> 1 And pLayout <> 2 Then e = e & "- Razporeditev mora biti 1 ali 2." & vbCrLf
    If pTarget <= 0 Or pTarget > 60 Then e = e & "- Ciljna odprtost mora biti med 0 in 60 %." & vbCrLf
    If pLmin <= 0 Or pLmax < pLmin Then e = e & "- Preveri min/max dolzino reze." & vbCrLf
    If pGmin <= 0 Or pGmax < pGmin Then e = e & "- Preveri min/max material med rezami." & vbCrLf
    If pEdge < 0 Then e = e & "- Zamik na robu ne sme biti negativen." & vbCrLf
    If pMode <> 1 And pMode <> 2 Then e = e & "- Nacin mora biti 1 ali 2." & vbCrLf
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
Private Function F(ByVal v As Double) As String
    F = Replace(CStr(Round(v, 3)), ",", ".")
End Function

'==============================================================================
' OBRIS PLOSCE
'==============================================================================
Private Sub ResetRegion()
    rN = 0: gLongLen = 0: gLongAng = 0
    ReDim rAx(0 To 63): ReDim rAy(0 To 63): ReDim rBx(0 To 63): ReDim rBy(0 To 63)
    ReDim rLine(0 To 63)
End Sub

Private Sub AddRegionSeg(ByVal ax As Double, ByVal ay As Double, ByVal ex As Double, ByVal ey As Double, ByVal isLine As Boolean)
    Dim n As Long, ln As Double
    If Abs(ex - ax) < EPS And Abs(ey - ay) < EPS Then Exit Sub
    If rN > UBound(rAx) Then
        n = 2 * rN
        ReDim Preserve rAx(0 To n): ReDim Preserve rAy(0 To n)
        ReDim Preserve rBx(0 To n): ReDim Preserve rBy(0 To n)
        ReDim Preserve rLine(0 To n)
    End If
    rAx(rN) = ax: rAy(rN) = ay: rBx(rN) = ex: rBy(rN) = ey: rLine(rN) = isLine
    rN = rN + 1
    If isLine Then
        ln = Sqr((ex - ax) ^ 2 + (ey - ay) ^ 2)
        If ln > gLongLen + EPS Then gLongLen = ln: gLongAng = NormAng(Atan2(ey - ay, ex - ax))
    End If
End Sub

Private Sub BuildRegionTyped()
    ResetRegion
    AddRegionSeg -pW / 2, -pH / 2, pW / 2, -pH / 2, True
    AddRegionSeg pW / 2, -pH / 2, pW / 2, pH / 2, True
    AddRegionSeg pW / 2, pH / 2, -pW / 2, pH / 2, True
    AddRegionSeg -pW / 2, pH / 2, -pW / 2, -pH / 2, True
End Sub

' robovi ravne ploskve (zunanji obris + luknje) -> koordinate ciljne skice
Private Function ReadFaceRegion(fc As SldWorks.Face2, xf As SldWorks.MathTransform) As Boolean
    Dim edges As Variant, i As Long, k As Long
    Dim ed As SldWorks.Edge, cv As SldWorks.Curve
    Dim prm As Variant, pv As Variant
    Dim tPar As Double, tA As Double, tB As Double
    Dim px As Double, py As Double, qx As Double, qy As Double

    edges = fc.GetEdges
    If IsEmpty(edges) Then Exit Function
    For i = 0 To UBound(edges)
        Set ed = edges(i)
        Set cv = ed.GetCurve
        prm = ed.GetCurveParams2
        If cv.IsLine Then
            ModelToSk prm(0), prm(1), prm(2), xf, px, py
            ModelToSk prm(3), prm(4), prm(5), xf, qx, qy
            AddRegionSeg px, py, qx, qy, True
        Else
            tA = prm(6): tB = prm(7)
            For k = 0 To EDGE_SEGS
                tPar = tA + (tB - tA) * k / EDGE_SEGS
                pv = cv.Evaluate2(tPar, 0)
                ModelToSk pv(0), pv(1), pv(2), xf, qx, qy
                If k > 0 Then AddRegionSeg px, py, qx, qy, False
                px = qx: py = qy
            Next k
        End If
    Next i
    ReadFaceRegion = (rN >= 3)
End Function

' segmenti skice (brez pomoznih crt) -> koordinate ciljne skice
Private Function ReadSketchRegion(sk As SldWorks.Sketch, xf As SldWorks.MathTransform, ByRef unsup As Long) As Boolean
    Dim segs As Variant, i As Long, k As Long, n As Long, dirn As Long
    Dim seg As SldWorks.SketchSegment
    Dim sLn As SldWorks.SketchLine, sArc As SldWorks.SketchArc
    Dim p As SldWorks.SketchPoint, q As SldWorks.SketchPoint, c As SldWorks.SketchPoint
    Dim inv As SldWorks.MathTransform
    Dim ax As Double, ay As Double, ex As Double, ey As Double
    Dim a0 As Double, a1 As Double, sw As Double, rr As Double, ang As Double
    Dim px As Double, py As Double, ux As Double, uy As Double

    Set inv = sk.ModelToSketchTransform.Inverse
    segs = sk.GetSketchSegments
    If IsEmpty(segs) Then Exit Function
    For i = 0 To UBound(segs)
        Set seg = segs(i)
        If Not seg.ConstructionGeometry Then
            Select Case seg.GetType
                Case 0                                 ' crta
                    Set sLn = seg
                    Set p = sLn.GetStartPoint2: Set q = sLn.GetEndPoint2
                    SkToSk p.X, p.Y, inv, xf, ax, ay
                    SkToSk q.X, q.Y, inv, xf, ex, ey
                    AddRegionSeg ax, ay, ex, ey, True
                Case 1                                 ' lok / krog
                    Set sArc = seg
                    Set c = sArc.GetCenterPoint2: Set p = sArc.GetStartPoint2: Set q = sArc.GetEndPoint2
                    rr = Sqr((p.X - c.X) ^ 2 + (p.Y - c.Y) ^ 2)
                    a0 = Atan2(p.Y - c.Y, p.X - c.X)
                    a1 = Atan2(q.Y - c.Y, q.X - c.X)
                    dirn = sArc.GetRotationDir
                    If dirn = 0 Then dirn = 1
                    If Abs(p.X - q.X) < EPS_M And Abs(p.Y - q.Y) < EPS_M Then
                        sw = 2 * PI * dirn
                    Else
                        sw = a1 - a0
                        If dirn > 0 Then
                            If sw <= 0 Then sw = sw + 2 * PI
                        Else
                            If sw >= 0 Then sw = sw - 2 * PI
                        End If
                    End If
                    n = Int(Abs(sw) / (ARC_STEP_DEG * PI / 180)) + 1
                    If n < 4 Then n = 4
                    For k = 0 To n
                        ang = a0 + sw * k / n
                        SkToSk c.X + rr * Cos(ang), c.Y + rr * Sin(ang), inv, xf, ux, uy
                        If k > 0 Then AddRegionSeg px, py, ux, uy, False
                        px = ux: py = uy
                    Next k
                Case 4                                 ' besedilo - preskoci
                Case Else
                    unsup = unsup + 1
            End Select
        End If
    Next i
    ReadSketchRegion = (rN >= 3)
End Function

' vsako krajisce se mora stikati z drugim segmentom (zaprt obris)
Private Function RegionClosed() As Boolean
    Dim i As Long
    For i = 0 To rN - 1
        If Not EndMatched(i, rAx(i), rAy(i)) Then Exit Function
        If Not EndMatched(i, rBx(i), rBy(i)) Then Exit Function
    Next i
    RegionClosed = True
End Function

Private Function EndMatched(ByVal skip As Long, ByVal x As Double, ByVal y As Double) As Boolean
    Dim j As Long
    For j = 0 To rN - 1
        If j <> skip Then
            If Abs(rAx(j) - x) < 0.01 And Abs(rAy(j) - y) < 0.01 Then EndMatched = True: Exit Function
            If Abs(rBx(j) - x) < 0.01 And Abs(rBy(j) - y) < 0.01 Then EndMatched = True: Exit Function
        End If
    Next j
End Function

' gabarit, obseg in povrsina obrisa
Private Sub RegionStats()
    Dim i As Long, j As Long, k As Long, m As Long, nx As Long
    Dim xs() As Double, y As Double, dy As Double, sumL As Double, tmp As Double

    bMinX = 1E+30: bMaxX = -1E+30: bMinY = 1E+30: bMaxY = -1E+30: gPerim = 0
    For i = 0 To rN - 1
        bMinX = Mn(bMinX, Mn(rAx(i), rBx(i))): bMaxX = Mx(bMaxX, Mx(rAx(i), rBx(i)))
        bMinY = Mn(bMinY, Mn(rAy(i), rBy(i))): bMaxY = Mx(bMaxY, Mx(rAy(i), rBy(i)))
        gPerim = gPerim + Sqr((rBx(i) - rAx(i)) ^ 2 + (rBy(i) - rAy(i)) ^ 2)
    Next i

    ReDim xs(0 To rN)
    dy = (bMaxY - bMinY) / SCAN_LINES
    gArea = 0
    For j = 0 To SCAN_LINES - 1
        y = bMinY + (j + 0.5) * dy
        nx = 0
        For i = 0 To rN - 1
            If (rAy(i) > y) <> (rBy(i) > y) Then
                xs(nx) = rAx(i) + (y - rAy(i)) * (rBx(i) - rAx(i)) / (rBy(i) - rAy(i))
                nx = nx + 1
            End If
        Next i
        For k = 1 To nx - 1                    ' insertion sort
            tmp = xs(k): m = k - 1
            Do While m >= 0
                If xs(m) <= tmp Then Exit Do
                xs(m + 1) = xs(m): m = m - 1
            Loop
            xs(m + 1) = tmp
        Next k
        sumL = 0
        For k = 0 To nx - 2 Step 2
            sumL = sumL + xs(k + 1) - xs(k)
        Next k
        gArea = gArea + sumL * dy
    Next j
End Sub

Private Function InRegion(ByVal x As Double, ByVal y As Double) As Boolean
    Dim i As Long, c As Boolean
    For i = 0 To rN - 1
        If (rAy(i) > y) <> (rBy(i) > y) Then
            If rAx(i) + (y - rAy(i)) * (rBx(i) - rAx(i)) / (rBy(i) - rAy(i)) > x Then c = Not c
        End If
    Next i
    InRegion = c
End Function

'==============================================================================
' GEOMETRIJA [mm]
'==============================================================================
Private Function Atan2(ByVal y As Double, ByVal x As Double) As Double
    If x > 0 Then
        Atan2 = Atn(y / x)
    ElseIf x < 0 Then
        If y >= 0 Then Atan2 = Atn(y / x) + PI Else Atan2 = Atn(y / x) - PI
    ElseIf y > 0 Then
        Atan2 = PI / 2
    ElseIf y < 0 Then
        Atan2 = -PI / 2
    Else
        Atan2 = 0
    End If
End Function

' kot reze v obmocje (-90, 90] stopinj, zaokrozen (da so enaki koti res enaki)
Private Function NormAng(ByVal a As Double) As Double
    Do While a > PI / 2 + 0.000000001: a = a - PI: Loop
    Do While a <= -PI / 2 + 0.000000001: a = a + PI: Loop
    NormAng = CLng(a * 10000000#) / 10000000#
End Function

Private Function Mn(ByVal a As Double, ByVal b As Double) As Double
    If a < b Then Mn = a Else Mn = b
End Function

Private Function Mx(ByVal a As Double, ByVal b As Double) As Double
    If a > b Then Mx = a Else Mx = b
End Function

Private Function PtSegDist(ByVal px As Double, ByVal py As Double, ByVal ax As Double, ByVal ay As Double, _
                           ByVal ex As Double, ByVal ey As Double) As Double
    Dim dx As Double, dy As Double, l2 As Double, t As Double
    dx = ex - ax: dy = ey - ay: l2 = dx * dx + dy * dy
    If l2 < 1E-12 Then
        t = 0
    Else
        t = ((px - ax) * dx + (py - ay) * dy) / l2
        If t < 0 Then t = 0
        If t > 1 Then t = 1
    End If
    PtSegDist = Sqr((px - ax - t * dx) ^ 2 + (py - ay - t * dy) ^ 2)
End Function

Private Function Orient(ByVal x1 As Double, ByVal y1 As Double, ByVal x2 As Double, ByVal y2 As Double, _
                        ByVal x3 As Double, ByVal y3 As Double) As Double
    Orient = (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1)
End Function

Private Function SegSegDist(ByVal p1x As Double, ByVal p1y As Double, ByVal p2x As Double, ByVal p2y As Double, _
                            ByVal q1x As Double, ByVal q1y As Double, ByVal q2x As Double, ByVal q2y As Double) As Double
    Dim d1 As Double, d2 As Double, d3 As Double, d4 As Double, d As Double
    d1 = Orient(q1x, q1y, q2x, q2y, p1x, p1y)
    d2 = Orient(q1x, q1y, q2x, q2y, p2x, p2y)
    d3 = Orient(p1x, p1y, p2x, p2y, q1x, q1y)
    d4 = Orient(p1x, p1y, p2x, p2y, q2x, q2y)
    If ((d1 > 0 And d2 < 0) Or (d1 < 0 And d2 > 0)) And ((d3 > 0 And d4 < 0) Or (d3 < 0 And d4 > 0)) Then
        SegSegDist = 0: Exit Function
    End If
    d = PtSegDist(p1x, p1y, q1x, q1y, q2x, q2y)
    d = Mn(d, PtSegDist(p2x, p2y, q1x, q1y, q2x, q2y))
    d = Mn(d, PtSegDist(q1x, q1y, p1x, p1y, p2x, p2y))
    d = Mn(d, PtSegDist(q2x, q2y, p1x, p1y, p2x, p2y))
    SegSegDist = d
End Function

' razdalja segmenta (v okviru reze) do pravokotnika [-hl,hl] x [-hh,hh]
Private Function SegRectLocal(ByVal ax As Double, ByVal ay As Double, ByVal ex As Double, ByVal ey As Double, _
                              ByVal hl As Double, ByVal hh As Double) As Double
    Dim d As Double
    If ax >= -hl And ax <= hl And ay >= -hh And ay <= hh Then Exit Function
    If ex >= -hl And ex <= hl And ey >= -hh And ey <= hh Then Exit Function
    d = SegSegDist(ax, ay, ex, ey, -hl, -hh, hl, -hh)
    d = Mn(d, SegSegDist(ax, ay, ex, ey, hl, -hh, hl, hh))
    d = Mn(d, SegSegDist(ax, ay, ex, ey, hl, hh, -hl, hh))
    d = Mn(d, SegSegDist(ax, ay, ex, ey, -hl, hh, -hl, -hh))
    SegRectLocal = d
End Function

' najmanjsa razdalja reze do obrisa (lim = ce je ze vecja od lim, se ne racuna natancno)
Private Function SlotEdgeDist(ByVal cx As Double, ByVal cy As Double, ByVal L As Double, ByVal a As Double, _
                              ByVal lim As Double) As Double
    Dim i As Long, c As Double, s As Double, rad As Double, best As Double, d As Double
    Dim ux As Double, uy As Double, vx As Double, vy As Double
    c = Cos(a): s = Sin(a)
    best = 1E+30
    For i = 0 To rN - 1
        rad = Sqr((L / 2) ^ 2 + (pSh / 2) ^ 2) + Mn(lim, best)
        If Not (Mn(rAx(i), rBx(i)) > cx + rad Or Mx(rAx(i), rBx(i)) < cx - rad Or _
                Mn(rAy(i), rBy(i)) > cy + rad Or Mx(rAy(i), rBy(i)) < cy - rad) Then
            ux = (rAx(i) - cx) * c + (rAy(i) - cy) * s: uy = -(rAx(i) - cx) * s + (rAy(i) - cy) * c
            vx = (rBx(i) - cx) * c + (rBy(i) - cy) * s: vy = -(rBx(i) - cx) * s + (rBy(i) - cy) * c
            d = SegRectLocal(ux, uy, vx, vy, L / 2, pSh / 2)
            If d < best Then best = d
        End If
    Next i
    SlotEdgeDist = best
End Function

' reza je znotraj obrisa in vsaj pM od vseh robov
Private Function SlotValid(ByVal cx As Double, ByVal cy As Double, ByVal L As Double, ByVal a As Double) As Boolean
    If Not InRegion(cx, cy) Then Exit Function
    SlotValid = (SlotEdgeDist(cx, cy, L, a, pM) >= pM - EPS)
End Function

' razdalja med dvema zasukanima rezama
Private Function SlotSlotDist(ByVal x1 As Double, ByVal y1 As Double, ByVal L1 As Double, ByVal a1 As Double, _
                              ByVal x2 As Double, ByVal y2 As Double, ByVal L2 As Double, ByVal a2 As Double) As Double
    Dim P(0 To 3, 0 To 1) As Double, Q(0 To 3, 0 To 1) As Double
    Dim i As Long, j As Long, d As Double
    SlotCorners x1, y1, L1, a1, P
    SlotCorners x2, y2, L2, a2, Q
    d = 1E+30
    For i = 0 To 3
        For j = 0 To 3
            d = Mn(d, SegSegDist(P(i, 0), P(i, 1), P((i + 1) Mod 4, 0), P((i + 1) Mod 4, 1), _
                                 Q(j, 0), Q(j, 1), Q((j + 1) Mod 4, 0), Q((j + 1) Mod 4, 1)))
        Next j
    Next i
    SlotSlotDist = d
End Function

Private Sub SlotCorners(ByVal cx As Double, ByVal cy As Double, ByVal L As Double, ByVal a As Double, ByRef P() As Double)
    Dim c As Double, s As Double, i As Long, u As Double, v As Double
    c = Cos(a): s = Sin(a)
    For i = 0 To 3
        If i = 0 Or i = 3 Then u = -L / 2 Else u = L / 2
        If i < 2 Then v = -pSh / 2 Else v = pSh / 2
        P(i, 0) = cx + u * c - v * s
        P(i, 1) = cy + u * s + v * c
    Next i
End Sub

'==============================================================================
' GENERIRANJE VZORCA
'==============================================================================
Private Sub ResetSlots()
    sN = 0
    ReDim sX(0 To 511): ReDim sY(0 To 511): ReDim sL(0 To 511): ReDim sA(0 To 511)
End Sub

Private Sub AddSlot(ByVal xc As Double, ByVal yc As Double, ByVal L As Double, ByVal a As Double)
    If sN > UBound(sX) Then
        ReDim Preserve sX(0 To 2 * sN): ReDim Preserve sY(0 To 2 * sN)
        ReDim Preserve sL(0 To 2 * sN): ReDim Preserve sA(0 To 2 * sN)
    End If
    sX(sN) = xc: sY(sN) = yc: sL(sN) = L: sA(sN) = a
    sN = sN + 1
End Sub

Private Function RandBetween(ByVal a As Double, ByVal b As Double) As Double
    RandBetween = a + Rnd * (b - a)
End Function

Private Function R05(ByVal v As Double) As Double
    R05 = Int(v * 2 + 0.5) / 2
End Function

' smer reze v tocki (x, y)
Private Function AngleAt(ByVal x As Double, ByVal y As Double) As Double
    Dim i As Long, d As Double, best As Double
    Select Case pAngMode
        Case 1: AngleAt = gLongAng
        Case 2
            best = 1E+30: AngleAt = 0
            For i = 0 To rN - 1
                If rLine(i) Then
                    If Sqr((rBx(i) - rAx(i)) ^ 2 + (rBy(i) - rAy(i)) ^ 2) >= LONG_EDGE * gLongLen Then
                        d = PtSegDist(x, y, rAx(i), rAy(i), rBx(i), rBy(i))
                        If d < best Then best = d: AngleAt = NormAng(Atan2(rBy(i) - rAy(i), rBx(i) - rAx(i)))
                    End If
                End If
            Next i
        Case Else: AngleAt = NormAng(pAngDeg * PI / 180)
    End Select
End Function

Private Sub GeneratePattern()
    gAngNote = ""
    If pLayout = 1 Then
        GenerateFree
    Else
        If pAngMode = 2 Then
            gRowAng = gLongAng
            gAngNote = "Opomba: pri razporeditvi v vrstah smer S ni mogoca - uporabljena je smer A."
        Else
            gRowAng = AngleAt(0, 0)
        End If
        GenerateRows
    End If
End Sub

' ---------- PROSTA razporeditev ----------
' Za vsako rezo se preizkusi K_CAND nakljucnih polozajev; izbere se veljaven
' polozaj z najvec prostora do sosedov. Konec, ko je dosezena ciljna odprtost.
Private Sub GenerateFree()
    Dim L As Double, x As Double, y As Double, a As Double
    Dim bestX As Double, bestY As Double, bestA As Double, bs As Double, s As Double
    Dim area As Double, cornerLoss As Double
    Dim k As Long, fails As Long, found As Boolean

    ResetSlots
    cornerLoss = (4 - PI) * pR * pR
    If gArea <= 0 Then Exit Sub
    If bMaxX - bMinX < 2 * pM + pLmin Or bMaxY - bMinY < 2 * pM + pSh Then Exit Sub

    Do While (area / gArea * 100 < pTarget) And (fails < MAX_FAILS)
        L = R05(RandBetween(pLmin, pLmax))
        found = False
        For k = 1 To K_CAND
            x = R05(RandBetween(bMinX + pM, bMaxX - pM))
            y = R05(RandBetween(bMinY + pM, bMaxY - pM))
            a = AngleAt(x, y)
            If SlotValid(x, y, L, a) Then
                s = FreeScore(x, y, L, a)
                If s > -1E+29 Then
                    If (Not found) Or (s > bs) Then bs = s: bestX = x: bestY = y: bestA = a: found = True
                End If
            End If
        Next k
        If found Then
            AddSlot bestX, bestY, L, bestA
            area = area + L * pSh - cornerLoss
            fails = 0
        Else
            fails = fails + 1
        End If
    Loop
    CenterPattern
End Sub

' -1E30 = trk (premalo materiala), sicer najmanjsi utezeni razmik do sosedov
Private Function FreeScore(ByVal x As Double, ByVal y As Double, ByVal L As Double, ByVal a As Double) As Double
    Dim i As Long, gx As Double, gy As Double, c As Double, best As Double
    Dim cs As Double, sg As Double, du As Double, dv As Double, dc As Double, d As Double
    best = 1E+30
    cs = Cos(a): sg = Sin(a)
    For i = 0 To sN - 1
        If Abs(sA(i) - a) < 0.000001 Then
            ' enaka smer: locen razmik vzdolz in precno
            du = (sX(i) - x) * cs + (sY(i) - y) * sg
            dv = -(sX(i) - x) * sg + (sY(i) - y) * cs
            gx = Abs(du) - (L + sL(i)) / 2
            gy = Abs(dv) - pSh
            If gx < pGmin - EPS And gy < pRow - EPS Then FreeScore = -1E+30: Exit Function
            If gx > gy * V_SCALE Then c = gx Else c = gy * V_SCALE
        Else
            ' razlicna smer (npr. na pregibu): vsaj pGmin materiala v vse smeri
            dc = Sqr((sX(i) - x) ^ 2 + (sY(i) - y) ^ 2)
            If dc > (L + sL(i)) / 2 + pSh + pGmin + 1 Then
                c = (dc - (L + sL(i)) / 2) * V_SCALE
            Else
                d = SlotSlotDist(x, y, L, a, sX(i), sY(i), sL(i), sA(i))
                If d < pGmin - EPS Then FreeScore = -1E+30: Exit Function
                c = d * V_SCALE
            End If
        End If
        If c < best Then best = c
    Next i
    FreeScore = best
End Function

' premakne vzorec tako, da je njegov gabarit na sredini gabarita plosce
' (samo ce pri tem vse reze ostanejo veljavne)
Private Sub CenterPattern()
    Dim i As Long, x0 As Double, x1 As Double, y0 As Double, y1 As Double
    Dim dx As Double, dy As Double, k As Long
    Dim P(0 To 3, 0 To 1) As Double
    If sN = 0 Then Exit Sub
    ' gabarit vogalov vseh rez
    x0 = 1E+30: x1 = -1E+30: y0 = 1E+30: y1 = -1E+30
    For i = 0 To sN - 1
        SlotCorners sX(i), sY(i), sL(i), sA(i), P
        For k = 0 To 3
            x0 = Mn(x0, P(k, 0)): x1 = Mx(x1, P(k, 0))
            y0 = Mn(y0, P(k, 1)): y1 = Mx(y1, P(k, 1))
        Next k
    Next i
    dx = (bMinX + bMaxX) / 2 - (x0 + x1) / 2
    dy = (bMinY + bMaxY) / 2 - (y0 + y1) / 2
    If Not TryShift(R05(dx), R05(dy)) Then
        If Not TryShift(dx, dy) Then TryShift 0, 0
    End If
End Sub

Private Function TryShift(ByVal dx As Double, ByVal dy As Double) As Boolean
    Dim i As Long, ok As Boolean
    If Abs(dx) < EPS And Abs(dy) < EPS Then TryShift = True: Exit Function
    ok = True
    For i = 0 To sN - 1
        If Not SlotValid(sX(i) + dx, sY(i) + dy, sL(i), sA(i)) Then ok = False: Exit For
    Next i
    If ok Then
        For i = 0 To sN - 1
            sX(i) = sX(i) + dx: sY(i) = sY(i) + dy
        Next i
    End If
    TryShift = ok
End Function

' ---------- razporeditev V VRSTAH (enotna smer gRowAng) ----------
' Vrste se racunajo v lokalnem sistemu, kjer so reze vodoravne (u, v).
Private Sub GenerateRows()
    Dim c As Double, s As Double, i As Long, r As Long
    Dim u0 As Double, u1 As Double, v0 As Double, v1 As Double, u As Double, v As Double
    Dim wLoc As Double, hLoc As Double, fillX As Double, uFrac As Double, eFac As Double
    Dim pitch As Double, totH As Double, vTop As Double

    ResetSlots
    c = Cos(gRowAng): s = Sin(gRowAng)
    u0 = 1E+30: u1 = -1E+30: v0 = 1E+30: v1 = -1E+30
    For i = 0 To rN - 1
        u = rAx(i) * c + rAy(i) * s: v = -rAx(i) * s + rAy(i) * c
        u0 = Mn(u0, u): u1 = Mx(u1, u): v0 = Mn(v0, v): v1 = Mx(v1, v)
    Next i
    wLoc = u1 - u0 - 2 * pM
    hLoc = v1 - v0 - 2 * pM
    If wLoc < pLmin Or hLoc < pSh Then Exit Sub

    ' razmik med vrstami iz ciljne odprtosti (ocena), nikoli manj od min. materiala
    fillX = ((pLmin + pLmax) / 2) / ((pLmin + pLmax) / 2 + (pGmin + pGmax) / 2)
    uFrac = (gArea - gPerim * pM + 4 * pM * pM) / gArea
    If uFrac < 0.05 Then uFrac = 0.05
    If uFrac > 1 Then uFrac = 1
    eFac = 1 - pEdge / wLoc
    If eFac < 0.2 Then eFac = 0.2
    pRowUsed = pSh * (uFrac * eFac * fillX * 100 / pTarget - 1)
    If pRowUsed < pRow Then pRowUsed = pRow
    pitch = pSh + pRowUsed
    nRows = Int((hLoc + pRowUsed) / pitch + EPS)
    If nRows < 1 Then Exit Sub

    totH = nRows * pSh + (nRows - 1) * pRowUsed
    vTop = (v0 + v1) / 2 + totH / 2 - pSh / 2
    For r = 0 To nRows - 1
        ScanRow u0, u1, vTop - r * pitch
    Next r
    DropInvalid
End Sub

' lokalno (u, v) -> skica (x, y)
Private Sub LocToSk(ByVal u As Double, ByVal v As Double, ByRef x As Double, ByRef y As Double)
    x = u * Cos(gRowAng) - v * Sin(gRowAng)
    y = u * Sin(gRowAng) + v * Cos(gRowAng)
End Sub

Private Function RowProbe(ByVal u As Double, ByVal v As Double, ByVal Lp As Double) As Boolean
    Dim x As Double, y As Double
    LocToSk u, v, x, y
    RowProbe = SlotValid(x, y, Lp, gRowAng)
End Function

' poisci odseke vrste, kjer je prostor za reze, in jih zapolni
Private Sub ScanRow(ByVal u0 As Double, ByVal u1 As Double, ByVal v As Double)
    Dim u As Double, uEnd As Double, Lp As Double, a As Double, b As Double
    Dim inRun As Boolean, ok As Boolean, prevU As Double, havePrev As Boolean
    Lp = 2 * pR
    If Lp < 1 Then Lp = 1
    u = u0 + pM + Lp / 2: uEnd = u1 - pM - Lp / 2
    Do While u <= uEnd + EPS
        ok = RowProbe(u, v, Lp)
        If ok Then
            If Not inRun Then
                If havePrev Then a = Refine(u, prevU, v, Lp) Else a = u
                inRun = True
            End If
            b = u
        ElseIf inRun Then
            RowInterval a - Lp / 2, Refine(b, u, v, Lp) + Lp / 2, v
            inRun = False
        End If
        prevU = u: havePrev = True
        u = u + SCAN_STEP
    Loop
    If inRun Then RowInterval a - Lp / 2, b + Lp / 2, v
End Sub

' meja med veljavnim (uOk) in neveljavnim (uBad) polozajem
Private Function Refine(ByVal uOk As Double, ByVal uBad As Double, ByVal v As Double, ByVal Lp As Double) As Double
    Dim k As Long, um As Double
    For k = 1 To 12
        um = (uOk + uBad) / 2
        If RowProbe(um, v, Lp) Then uOk = um Else uBad = um
    Next k
    Refine = uOk
End Function

Private Sub RowInterval(ByVal ua As Double, ByVal ub As Double, ByVal v As Double)
    Dim w As Double, insL As Double, insR As Double
    w = ub - ua
    If w < pLmin - EPS Then Exit Sub
    insL = Rnd * pEdge: insR = Rnd * pEdge
    If w - insL - insR < pLmin Then insL = 0: insR = 0
    GenerateRow ua + insL, w - insL - insR, v
End Sub

Private Sub GenerateRow(ByVal umin As Double, ByVal wu As Double, ByVal v As Double)
    Dim st() As Double, ln() As Double, n As Long, i As Long
    Dim pos As Double, L As Double, G As Double, remain As Double, lFit As Double
    Dim extra As Double, x As Double, y As Double

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
    If n > 1 Then
        For i = 1 To n - 1                   ' raztegni presledke do konca odseka
            st(i) = st(i) + extra * i / (n - 1)
        Next i
    Else
        st(0) = st(0) + extra / 2            ' ena sama reza -> na sredino
    End If

    For i = 0 To n - 1
        LocToSk umin + st(i) + ln(i) / 2, v, x, y
        AddSlot x, y, ln(i), gRowAng
    Next i
End Sub

' odstrani reze, ki niso v celoti znotraj obrisa (npr. ob vbocenih vogalih)
Private Sub DropInvalid()
    Dim i As Long, k As Long
    k = 0
    For i = 0 To sN - 1
        If SlotValid(sX(i), sY(i), sL(i), sA(i)) Then
            sX(k) = sX(i): sY(k) = sY(i): sL(k) = sL(i): sA(k) = sA(i)
            k = k + 1
        End If
    Next i
    sN = k
End Sub

Private Sub ComputeStats()
    Dim i As Long, area As Double, d As Double
    area = 0: gMinDist = 1E+30
    For i = 0 To sN - 1
        area = area + sL(i) * pSh - (4 - PI) * pR * pR
        d = SlotEdgeDist(sX(i), sY(i), sL(i), sA(i), gMinDist)
        If d < gMinDist Then gMinDist = d
    Next i
    gOpen = 100 * area / gArea
End Sub

Private Function SummaryText() As String
    Dim i As Long, a0 As Double, a1 As Double
    a0 = 1E+30: a1 = -1E+30
    For i = 0 To sN - 1
        a0 = Mn(a0, sA(i)): a1 = Mx(a1, sA(i))
    Next i
    SummaryText = ShapeText() & vbCrLf & _
        "Smer rez: " & F(a0 * 180 / PI) & IIf(a1 - a0 > 0.000001, " do " & F(a1 * 180 / PI), "") & " st." & vbCrLf & _
        "Najmanjsi odmik reze od roba: " & F(gMinDist) & vbCrLf & _
        "Odprtost plosce: " & Format(gOpen, "0.0") & " %"
End Function

'==============================================================================
' SOLIDWORKS
'==============================================================================
Private Function SketchName(sk As SldWorks.Sketch) As String
    Dim fe As SldWorks.Feature
    On Error Resume Next
    Set fe = sk
    SketchName = fe.Name
End Function

Private Function SelectedSketch(selMgr As SldWorks.SelectionMgr) As SldWorks.Sketch
    Dim obj As Object, fe As SldWorks.Feature, seg As SldWorks.SketchSegment, sk As SldWorks.Sketch
    On Error Resume Next
    Set obj = selMgr.GetSelectedObject6(1, -1)
    If selMgr.GetSelectedObjectType3(1, -1) = 10 Then
        Set seg = obj
        Set sk = seg.GetSketch
    Else
        Set fe = obj
        If Not fe Is Nothing Then Set sk = fe.GetSpecificFeature2
        If sk Is Nothing Then Set sk = obj
    End If
    Set SelectedSketch = sk
End Function

Private Function SelectEntity(fc As SldWorks.Face2) As Boolean
    Dim ent As SldWorks.Entity
    Set ent = fc
    SelectEntity = ent.Select4(False, Nothing)
End Function

' izberi ravnino / ploskev, na kateri lezi skica
Private Function SelectSketchPlane(swModel As SldWorks.ModelDoc2, sk As SldWorks.Sketch) As Boolean
    Dim refObj As Object, refType As Long, ent As SldWorks.Entity, fPl As SldWorks.Feature
    Dim skFeat As SldWorks.Feature, par As Variant, i As Long
    On Error Resume Next
    swModel.ClearSelection2 True
    Set refObj = sk.GetReferenceEntity(refType)
    If Not refObj Is Nothing Then
        Set ent = refObj
        If Not ent Is Nothing Then SelectSketchPlane = ent.Select4(False, Nothing)
        If Not SelectSketchPlane Then
            Set fPl = refObj
            If Not fPl Is Nothing Then SelectSketchPlane = fPl.Select2(False, 0)
        End If
    End If
    If Not SelectSketchPlane Then
        Set skFeat = sk
        par = skFeat.GetParents
        If Not IsEmpty(par) Then
            For i = 0 To UBound(par)
                Set fPl = par(i)
                If fPl.GetTypeName2 = "RefPlane" Then
                    SelectSketchPlane = fPl.Select2(False, 0)
                    Exit For
                End If
            Next i
        End If
    End If
    Err.Clear
End Function

Private Function PrepareSketchPlane(swModel As SldWorks.ModelDoc2) As Boolean
    Dim selMgr As SldWorks.SelectionMgr
    Dim feat As SldWorks.Feature

    Set selMgr = swModel.SelectionManager
    If selMgr.GetSelectedObjectCount2(-1) >= 1 Then
        If selMgr.GetSelectedObjectType3(1, -1) = 4 Then   ' swSelDATUMPLANES
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
End Function

' prekinitev: zapri in izbrisi ze ustvarjeno (prazno) skico
Private Sub AbortSketch(swModel As SldWorks.ModelDoc2, skMgr As SldWorks.SketchManager, fe As SldWorks.Feature)
    On Error Resume Next
    If Not skMgr.ActiveSketch Is Nothing Then skMgr.InsertSketch True
    swModel.ClearSelection2 True
    If fe.Select2(False, 0) Then swModel.EditDelete
    swModel.ClearSelection2 True
End Sub

Private Sub ModelToSk(ByVal x As Double, ByVal y As Double, ByVal z As Double, xf As SldWorks.MathTransform, _
                      ByRef ox As Double, ByRef oy As Double)
    Dim d(2) As Double, v As Variant, mp As SldWorks.MathPoint
    d(0) = x: d(1) = y: d(2) = z
    v = d
    Set mp = gMath.CreatePoint(v)
    Set mp = mp.MultiplyTransform(xf)
    v = mp.ArrayData
    ox = v(0) * 1000#: oy = v(1) * 1000#
End Sub

Private Sub SkToSk(ByVal x As Double, ByVal y As Double, inv As SldWorks.MathTransform, xf As SldWorks.MathTransform, _
                   ByRef ox As Double, ByRef oy As Double)
    Dim d(2) As Double, v As Variant, mp As SldWorks.MathPoint
    d(0) = x: d(1) = y: d(2) = 0
    v = d
    Set mp = gMath.CreatePoint(v)
    Set mp = mp.MultiplyTransform(inv)
    Set mp = mp.MultiplyTransform(xf)
    v = mp.ArrayData
    ox = v(0) * 1000#: oy = v(1) * 1000#
End Sub

Private Function HasBody(swModel As SldWorks.ModelDoc2) As Boolean
    Dim pd As SldWorks.PartDoc, v As Variant
    Set pd = swModel
    v = pd.GetBodies2(0, True)       ' swSolidBody
    HasBody = Not IsEmpty(v)
End Function

Private Sub DrawAll(swModel As SldWorks.ModelDoc2, skMgr As SldWorks.SketchManager, ByVal mode As Long)
    Dim i As Long
    Dim view As Object

    Set view = swModel.ActiveView
    If Not view Is Nothing Then view.EnableGraphicsUpdate = False
    swModel.FeatureManager.EnableFeatureTree = False
    skMgr.AddToDB = True              ' brez snapanja / avtomatskih relacij
    skMgr.DisplayWhenAdded = False

    For i = 0 To sN - 1
        dCx = sX(i): dCy = sY(i): dCos = Cos(sA(i)): dSin = Sin(sA(i))
        If mode = 1 Then
            DrawSlotFast skMgr, sL(i), pSh, pR
        Else
            DrawSlotSafe swModel, skMgr, sL(i), pSh, pR
        End If
    Next i

    skMgr.AddToDB = False
    skMgr.DisplayWhenAdded = True
    swModel.FeatureManager.EnableFeatureTree = True
    If Not view Is Nothing Then view.EnableGraphicsUpdate = True
    swModel.ClearSelection2 True
End Sub

' tocka v okviru reze (u vzdolz, v precno, mm) -> skica [m]
Private Sub ToSk(ByVal u As Double, ByVal v As Double, ByRef ox As Double, ByRef oy As Double)
    ox = (dCx + u * dCos - v * dSin) / 1000#
    oy = (dCy + u * dSin + v * dCos) / 1000#
End Sub

Private Sub LineL(skMgr As SldWorks.SketchManager, ByVal u1 As Double, ByVal v1 As Double, ByVal u2 As Double, ByVal v2 As Double)
    Dim ax As Double, ay As Double, ex As Double, ey As Double
    ToSk u1, v1, ax, ay
    ToSk u2, v2, ex, ey
    skMgr.CreateLine ax, ay, 0, ex, ey, 0
End Sub

Private Sub ArcL(skMgr As SldWorks.SketchManager, ByVal uc As Double, ByVal vc As Double, _
                 ByVal us As Double, ByVal vs As Double, ByVal ue As Double, ByVal ve As Double)
    Dim cx As Double, cy As Double, ax As Double, ay As Double, ex As Double, ey As Double
    ToSk uc, vc, cx, cy
    ToSk us, vs, ax, ay
    ToSk ue, ve, ex, ey
    skMgr.CreateArc cx, cy, 0, ax, ay, 0, ex, ey, 0, 1      ' 1 = v nasprotni smeri ure
End Sub

' Nacin 1: 4 crte + 4 loki (tocno enake koordinate krajisc)
Private Sub DrawSlotFast(skMgr As SldWorks.SketchManager, ByVal L As Double, ByVal h As Double, ByVal r As Double)
    Dim u1 As Double, u2 As Double, v1 As Double, v2 As Double
    Dim ua As Double, ub As Double, va As Double, vb As Double
    Dim hasH As Boolean, hasV As Boolean

    u1 = -L / 2: u2 = L / 2
    v1 = -h / 2: v2 = h / 2

    If r <= EPS Then
        LineL skMgr, u1, v1, u2, v1
        LineL skMgr, u2, v1, u2, v2
        LineL skMgr, u2, v2, u1, v2
        LineL skMgr, u1, v2, u1, v1
        Exit Sub
    End If

    ua = u1 + r: ub = u2 - r
    va = v1 + r: vb = v2 - r
    hasH = (ub - ua > EPS)
    hasV = (vb - va > EPS)
    If Not hasH Then ua = 0: ub = 0
    If Not hasV Then va = 0: vb = 0

    If hasH Then LineL skMgr, ua, v1, ub, v1           ' spodaj
    ArcL skMgr, ub, va, ub, v1, u2, va                 ' spodaj desno
    If hasV Then LineL skMgr, u2, va, u2, vb           ' desno
    ArcL skMgr, ub, vb, u2, vb, ub, v2                 ' zgoraj desno
    If hasH Then LineL skMgr, ub, v2, ua, v2           ' zgoraj
    ArcL skMgr, ua, vb, ua, v2, u1, vb                 ' zgoraj levo
    If hasV Then LineL skMgr, u1, vb, u1, va           ' levo
    ArcL skMgr, ua, va, u1, va, ua, v1                 ' spodaj levo
End Sub

' Nacin 2: 3-tockovni pravokotnik + sketch fillet (ali slot pri R = h/2)
Private Sub DrawSlotSafe(swModel As SldWorks.ModelDoc2, skMgr As SldWorks.SketchManager, _
                         ByVal L As Double, ByVal h As Double, ByVal r As Double)
    Dim v As Variant, i As Long, k As Long, j As Long, nP As Long
    Dim seg As SldWorks.SketchSegment, sLn As SldWorks.SketchLine
    Dim pts(1 To 8) As SldWorks.SketchPoint, p As SldWorks.SketchPoint
    Dim dup As Boolean
    Dim x1 As Double, y1 As Double, x2 As Double, y2 As Double, x3 As Double, y3 As Double

    If r >= h / 2 - EPS Then
        ' polkrozni konci -> standardni slot (center-center)
        ToSk -(L - h) / 2, 0, x1, y1
        ToSk (L - h) / 2, 0, x2, y2
        skMgr.CreateSketchSlot 0, 0, h / 1000#, x1, y1, 0, x2, y2, 0, 0, 0, 0, 1, False
        Exit Sub
    End If

    ToSk -L / 2, -h / 2, x1, y1
    ToSk L / 2, -h / 2, x2, y2
    ToSk L / 2, h / 2, x3, y3
    v = skMgr.Create3PointCornerRectangle(x1, y1, 0, x2, y2, 0, x3, y3, 0)
    If r <= EPS Then Exit Sub
    If IsEmpty(v) Then Exit Sub

    ' zberi 4 unikatne vogalne tocke
    nP = 0
    For i = LBound(v) To UBound(v)
        Set seg = v(i)
        If seg.GetType = 0 And Not seg.ConstructionGeometry Then
            Set sLn = seg
            For k = 0 To 1
                If k = 0 Then Set p = sLn.GetStartPoint2 Else Set p = sLn.GetEndPoint2
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
    skMgr.CreateFillet r / 1000#, 1             ' swConstrainedCornerKeepGeometry
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
