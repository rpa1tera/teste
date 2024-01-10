#Include "Rwmake.ch"
#Include "Protheus.ch"      

User Function MT100AGR()
Local lRet := .F.   
Local oFontText 
Local _oDlg1
Local oMsg 
Local cProcImp	:= Space(500)

DEFINE FONT oFontText NAME "Courier New" SIZE 09,20

DEFINE MSDIALOG _oDlg1 TITLE "Observações do documento de entrada" FROM 323,412 TO 500,1000 PIXEL STYLE DS_MODALFRAME STATUS

@ 005, 004 TO 80, 250 LABEL "Digite abaixo:" PIXEL OF _oDlg1
@ 013,007 GET oMsg VAR cProcImp MEMO SIZE 240,60 OF _oDlg1 PIXEL

DEFINE SBUTTON FROM 10, 260 TYPE 1 ENABLE OF _oDlg1 ACTION _oDlg1:End() 
ACTIVATE MSDIALOG _oDlg1 CENTERED     

RecLock("SF1", .F.)  

If !Empty(cProcImp)      
	REPLACE SF1->F1_MSGNF WITH AllTrim(cProcImp)
EndIf        

SF1->(MsUnlock())
	    
Return .T.
